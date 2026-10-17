import 'package:cloud_firestore/cloud_firestore.dart';

import '../../auditoria/data/auditoria_repository.dart';
import '../../auditoria/domain/auditoria.dart';
import '../domain/cliente.dart';

/// Ya existe un cliente con esa cédula en la empresa (RN-02).
class CedulaDuplicadaException implements Exception {
  const CedulaDuplicadaException(this.cedula);

  final String cedula;

  @override
  String toString() => 'Ya existe un cliente con la cédula "$cedula".';
}

/// Acceso a la colección `clientes` (spec 004). Multi-tenant por `empresaId`.
///
/// La búsqueda y los filtros se aplican en el cliente para no depender de
/// índices compuestos; el volumen por empresa es manejable.
class ClientesRepository {
  ClientesRepository({
    FirebaseFirestore? firestore,
    AuditoriaRepository? auditoria,
  })  : _firestoreOverride = firestore,
        _auditoria = auditoria ?? AuditoriaRepository();

  final FirebaseFirestore? _firestoreOverride;
  final AuditoriaRepository _auditoria;

  FirebaseFirestore get _db => _firestoreOverride ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _clientes =>
      _db.collection('clientes');

  /// Genera un id nuevo (sin escribir).
  String nuevoId() => _clientes.doc().id;

  /// Escucha, en tiempo real, los clientes de una empresa.
  Stream<List<Cliente>> escuchar(String empresaId) {
    return _clientes
        .where('empresaId', isEqualTo: empresaId)
        .snapshots()
        .map(_aLista);
  }

  /// Lista los clientes de una empresa con filtros opcionales.
  Future<List<Cliente>> listar(
    String empresaId, {
    String? busqueda,
    EstadoCliente? estado,
    Clasificacion? clasificacion,
  }) async {
    final snap = await _clientes.where('empresaId', isEqualTo: empresaId).get();
    return filtrar(_aLista(snap),
        busqueda: busqueda, estado: estado, clasificacion: clasificacion);
  }

  /// Filtra una lista de clientes por búsqueda (nombre/cédula/teléfono),
  /// estado y clasificación.
  static List<Cliente> filtrar(
    List<Cliente> clientes, {
    String? busqueda,
    EstadoCliente? estado,
    Clasificacion? clasificacion,
  }) {
    final q = (busqueda ?? '').trim().toLowerCase();
    return clientes.where((c) {
      if (estado != null && c.estado != estado) return false;
      if (clasificacion != null && c.clasificacion != clasificacion) return false;
      if (q.isNotEmpty) {
        final nombre = c.nombreCompleto.toLowerCase();
        final cedula = c.cedula.toLowerCase();
        final telefono = c.telefono.toLowerCase();
        if (!nombre.contains(q) && !cedula.contains(q) && !telefono.contains(q)) {
          return false;
        }
      }
      return true;
    }).toList(growable: false);
  }

  /// Obtiene un cliente por su id.
  Future<Cliente?> obtener(String clienteId) async {
    final doc = await _clientes.doc(clienteId).get();
    if (!doc.exists || doc.data() == null) return null;
    return Cliente.fromMap(doc.id, doc.data()!);
  }

  /// Busca un cliente por cédula dentro de una empresa (RN-02).
  Future<Cliente?> porCedula(String empresaId, String cedula) async {
    final objetivo = cedula.trim().toLowerCase();
    if (objetivo.isEmpty) return null;
    final clientes = await listar(empresaId);
    for (final c in clientes) {
      if (c.cedula.trim().toLowerCase() == objetivo) return c;
    }
    return null;
  }

  /// Obtiene el cliente vinculado a una cuenta de Auth (rol Cliente).
  Future<Cliente?> porUid(String uid) async {
    final snap =
        await _clientes.where('uid', isEqualTo: uid).limit(1).get();
    if (snap.docs.isEmpty) return null;
    final doc = snap.docs.first;
    return Cliente.fromMap(doc.id, doc.data());
  }

  /// Crea un cliente y lo audita. Devuelve su id.
  Future<String> crear(Cliente cliente) async {
    if (cliente.nombreCompleto.trim().isEmpty) {
      throw ArgumentError('El nombre completo es obligatorio.');
    }
    final duplicado =
        await porCedula(cliente.empresaId, cliente.cedula);
    if (duplicado != null) throw CedulaDuplicadaException(cliente.cedula);

    final ref =
        cliente.id.isNotEmpty ? _clientes.doc(cliente.id) : _clientes.doc();
    final datos = cliente.toMap()..['id'] = ref.id;
    await ref.set(datos);

    await _auditoria.registrarEvento(
      empresaId: cliente.empresaId,
      operacion: OperacionAuditoria.insert,
      tabla: 'clientes',
      documentoId: ref.id,
      datos: datos,
    );
    return ref.id;
  }

  /// Crea o actualiza la ficha del **propio cliente** (rol Cliente). No valida
  /// cédula duplicada (un cliente no puede listar clientes). Devuelve el id.
  Future<String> guardarPropio(Cliente cliente) async {
    final ref =
        cliente.id.isNotEmpty ? _clientes.doc(cliente.id) : _clientes.doc();
    final datos = cliente.toMap()..['id'] = ref.id;
    await ref.set(datos, SetOptions(merge: true));
    await _auditoria.registrarEvento(
      empresaId: cliente.empresaId,
      operacion: OperacionAuditoria.insert,
      tabla: 'clientes',
      documentoId: ref.id,
      datos: datos,
    );
    return ref.id;
  }

  /// Actualiza un cliente y registra los cambios en la auditoría.
  Future<void> actualizar(Cliente cliente) async {
    final ref = _clientes.doc(cliente.id);
    final snap = await ref.get();
    final antes = snap.data() ?? const <String, dynamic>{};
    final despues = cliente.toMap();
    final antesParcial = <String, dynamic>{
      for (final clave in despues.keys) clave: antes[clave],
    };
    await ref.set(despues, SetOptions(merge: true));
    await _auditoria.registrarCambios(
      empresaId: cliente.empresaId,
      tabla: 'clientes',
      documentoId: cliente.id,
      antes: antesParcial,
      despues: despues,
    );
  }

  /// Cambia el estado del cliente (activo/inactivo/moroso) y lo audita.
  Future<void> cambiarEstado(
    String clienteId,
    EstadoCliente estado, {
    String? empresaId,
  }) async {
    final ref = _clientes.doc(clienteId);
    final snap = await ref.get();
    final antes = snap.data() ?? const <String, dynamic>{};
    final empresa = empresaId ?? (antes['empresaId'] as String?) ?? '';
    final despues = <String, dynamic>{'estado': estado.id};
    await ref.update(despues);
    await _auditoria.registrarCambios(
      empresaId: empresa,
      tabla: 'clientes',
      documentoId: clienteId,
      antes: <String, dynamic>{'estado': antes['estado']},
      despues: despues,
    );
  }

  List<Cliente> _aLista(QuerySnapshot<Map<String, dynamic>> snap) {
    final lista = snap.docs
        .map((DocumentSnapshot<Map<String, dynamic>> d) =>
            Cliente.fromMap(d.id, d.data()!))
        .toList();
    lista.sort((Cliente a, Cliente b) =>
        a.nombreCompleto.toLowerCase().compareTo(b.nombreCompleto.toLowerCase()));
    return lista;
  }
}

import 'package:flutter/material.dart';

import '../../auth/domain/usuario.dart';
import '../data/clientes_repository.dart';
import '../data/ubicacion_service.dart';
import '../data/ubicaciones/departamentos_ciudades.dart';
import '../domain/cliente.dart';
import '../domain/validar_cliente.dart';

/// Formulario de creación/edición de un cliente (spec 004, T021/T022).
///
/// Devuelve `true` al guardar para que el listado se recargue.
class ClienteFormScreen extends StatefulWidget {
  const ClienteFormScreen({
    super.key,
    required this.usuario,
    this.cliente,
    this.clientesRepository,
    this.ubicacionService,
  });

  final Usuario usuario;

  /// Cliente a editar. `null` para crear uno nuevo.
  final Cliente? cliente;

  final ClientesRepository? clientesRepository;
  final UbicacionService? ubicacionService;

  @override
  State<ClienteFormScreen> createState() => _ClienteFormScreenState();
}

class _ClienteFormScreenState extends State<ClienteFormScreen> {
  late final ClientesRepository _repo =
      widget.clientesRepository ?? ClientesRepository();
  late final UbicacionService _ubicacion =
      widget.ubicacionService ?? const UbicacionService();

  final _nombre = TextEditingController();
  final _cedula = TextEditingController();
  final _telefono = TextEditingController();
  final _correo = TextEditingController();
  final _contacto = TextEditingController();
  final _telefonoAlterno = TextEditingController();
  final _direccion = TextEditingController();
  final _barrio = TextEditingController();
  final _referencia = TextEditingController();
  final _creditoLimite = TextEditingController(text: '0');
  final _observaciones = TextEditingController();

  TipoDocumento _tipoDocumento = TipoDocumento.cc;
  Clasificacion _clasificacion = Clasificacion.detal;
  EstadoCliente _estado = EstadoCliente.activo;
  String? _departamento;
  String? _ciudad;
  UbicacionGPS? _ubicacionGps;
  bool _guardando = false;

  String get _empresaId => widget.usuario.empresaId ?? '';
  bool get _esEdicion => widget.cliente != null;

  @override
  void initState() {
    super.initState();
    final c = widget.cliente;
    if (c != null) {
      _nombre.text = c.nombreCompleto;
      _cedula.text = c.cedula;
      _telefono.text = c.telefono;
      _correo.text = c.correo;
      _contacto.text = c.contacto;
      _telefonoAlterno.text = c.telefonoAlterno;
      _direccion.text = c.direccion.direccion;
      _barrio.text = c.direccion.barrio;
      _referencia.text = c.direccion.referencia;
      _creditoLimite.text = c.creditoLimite.round().toString();
      _observaciones.text = c.observaciones;
      _tipoDocumento = c.tipoDocumento;
      _clasificacion = c.clasificacion;
      _estado = c.estado;
      _departamento =
          c.direccion.departamento.isEmpty ? null : c.direccion.departamento;
      _ciudad = c.direccion.ciudad.isEmpty ? null : c.direccion.ciudad;
      _ubicacionGps = c.ubicacionGPS;
    }
  }

  @override
  void dispose() {
    for (final c in <TextEditingController>[
      _nombre,
      _cedula,
      _telefono,
      _correo,
      _contacto,
      _telefonoAlterno,
      _direccion,
      _barrio,
      _referencia,
      _creditoLimite,
      _observaciones,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _avisar(String mensaje) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(mensaje)));
  }

  Future<void> _compartirUbicacion() async {
    final resultado = await _ubicacion.capturar();
    if (!mounted) return;
    if (!resultado.ok) {
      _avisar(resultado.error ?? 'No se pudo obtener la ubicación.');
      return;
    }
    setState(() => _ubicacionGps = resultado.ubicacion);
    _avisar('Ubicación capturada.');
  }

  Future<void> _guardar() async {
    final cliente = Cliente(
      id: widget.cliente?.id ?? _repo.nuevoId(),
      empresaId: _empresaId,
      nombreCompleto: _nombre.text.trim(),
      cedula: _cedula.text.trim(),
      tipoDocumento: _tipoDocumento,
      telefono: _telefono.text.trim(),
      correo: _correo.text.trim(),
      contacto: _contacto.text.trim(),
      telefonoAlterno: _telefonoAlterno.text.trim(),
      direccion: Direccion(
        departamento: _departamento ?? '',
        ciudad: _ciudad ?? '',
        direccion: _direccion.text.trim(),
        barrio: _barrio.text.trim(),
        referencia: _referencia.text.trim(),
      ),
      ubicacionGPS: _ubicacionGps,
      clasificacion: _clasificacion,
      estado: _esEdicion ? _estado : EstadoCliente.activo,
      creditoLimite: double.tryParse(_creditoLimite.text.trim()) ?? 0,
      creditoSaldo: widget.cliente?.creditoSaldo ?? 0,
      observaciones: _observaciones.text.trim(),
      uid: widget.cliente?.uid,
      fechaCreacion: widget.cliente?.fechaCreacion,
    );

    setState(() => _guardando = true);
    try {
      final existentes = await _repo.listar(_empresaId);
      final errores = validarCliente(
        cliente,
        existentes: existentes,
        exceptoId: widget.cliente?.id,
      );
      if (errores.isNotEmpty) {
        if (mounted) _avisar(errores.first);
        return;
      }

      if (_esEdicion) {
        await _repo.actualizar(cliente);
      } else {
        await _repo.crear(cliente);
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on CedulaDuplicadaException catch (e) {
      if (mounted) _avisar(e.toString());
    } catch (e) {
      if (mounted) _avisar('No se pudo guardar: $e');
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(_esEdicion ? 'Editar cliente' : 'Nuevo cliente'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          _seccion(theme, 'Datos personales'),
          _campo(_nombre, 'Nombre completo *'),
          Row(
            children: <Widget>[
              Expanded(
                child: DropdownButtonFormField<TipoDocumento>(
                  initialValue: _tipoDocumento,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de documento',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: <DropdownMenuItem<TipoDocumento>>[
                    for (final t in TipoDocumento.values)
                      DropdownMenuItem<TipoDocumento>(
                        value: t,
                        child: Text(t.nombre),
                      ),
                  ],
                  onChanged: (TipoDocumento? v) =>
                      setState(() => _tipoDocumento = v ?? TipoDocumento.cc),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(child: _campo(_cedula, 'Cédula *')),
            ],
          ),
          _campo(_telefono, 'Teléfono *'),
          _campo(_correo, 'Correo'),
          _campo(_telefonoAlterno, 'Teléfono alterno'),
          const SizedBox(height: 8),
          _seccion(theme, 'Dirección'),
          _dropdownDepartamento(),
          _dropdownCiudad(),
          _campo(_direccion, 'Dirección *'),
          _campo(_barrio, 'Barrio'),
          _campo(_referencia, 'Punto de referencia'),
          _campo(
            _contacto,
            'Persona de contacto (opcional)',
            ayuda: 'Quién recibe en esa dirección, si no es el cliente',
          ),
          const SizedBox(height: 8),
          _seccion(theme, 'Ubicación GPS'),
          _ubicacionWidget(theme),
          const SizedBox(height: 8),
          _seccion(theme, 'Clasificación y crédito'),
          DropdownButtonFormField<Clasificacion>(
            initialValue: _clasificacion,
            decoration: const InputDecoration(
              labelText: 'Clasificación',
              border: OutlineInputBorder(),
            ),
            items: <DropdownMenuItem<Clasificacion>>[
              for (final c in Clasificacion.values)
                DropdownMenuItem<Clasificacion>(
                  value: c,
                  child: Text(c.nombre),
                ),
            ],
            onChanged: (Clasificacion? v) =>
                setState(() => _clasificacion = v ?? Clasificacion.detal),
          ),
          const SizedBox(height: 12),
          if (_esEdicion)
            DropdownButtonFormField<EstadoCliente>(
              initialValue: _estado,
              decoration: const InputDecoration(
                labelText: 'Estado',
                border: OutlineInputBorder(),
              ),
              items: <DropdownMenuItem<EstadoCliente>>[
                for (final e in EstadoCliente.values)
                  DropdownMenuItem<EstadoCliente>(
                    value: e,
                    child: Text(e.nombre),
                  ),
              ],
              onChanged: (EstadoCliente? v) =>
                  setState(() => _estado = v ?? EstadoCliente.activo),
            ),
          if (_esEdicion) const SizedBox(height: 12),
          _campo(_creditoLimite, 'Límite de crédito', numero: true),
          _campo(_observaciones, 'Observaciones', maxLines: 2),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _guardando ? null : _guardar,
            icon: _guardando
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: Text(_guardando ? 'Guardando…' : 'Guardar'),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _seccion(ThemeData theme, String titulo) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(titulo, style: theme.textTheme.titleMedium),
      );

  Widget _campo(
    TextEditingController controller,
    String etiqueta, {
    bool numero = false,
    int maxLines = 1,
    String? ayuda,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: numero ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: etiqueta,
          helperText: ayuda,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _dropdownDepartamento() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String?>(
        initialValue: _departamento,
        isExpanded: true,
        decoration: const InputDecoration(
          labelText: 'Departamento *',
          border: OutlineInputBorder(),
        ),
        items: <DropdownMenuItem<String?>>[
          const DropdownMenuItem<String?>(value: null, child: Text('Selecciona…')),
          for (final d in departamentos)
            DropdownMenuItem<String?>(value: d, child: Text(d)),
        ],
        onChanged: (String? v) => setState(() {
          _departamento = v;
          // Si la ciudad actual no pertenece al nuevo departamento, se limpia.
          if (_ciudad != null && !ciudadesDe(v ?? '').contains(_ciudad)) {
            _ciudad = null;
          }
        }),
      ),
    );
  }

  Widget _dropdownCiudad() {
    final ciudades = ciudadesDe(_departamento ?? '');
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String?>(
        initialValue: ciudades.contains(_ciudad) ? _ciudad : null,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: 'Ciudad *',
          border: const OutlineInputBorder(),
          enabled: _departamento != null,
          helperText: _departamento == null
              ? 'Selecciona primero el departamento'
              : null,
        ),
        items: <DropdownMenuItem<String?>>[
          const DropdownMenuItem<String?>(value: null, child: Text('Selecciona…')),
          for (final c in ciudades)
            DropdownMenuItem<String?>(value: c, child: Text(c)),
        ],
        onChanged: _departamento == null
            ? null
            : (String? v) => setState(() => _ciudad = v),
      ),
    );
  }

  Widget _ubicacionWidget(ThemeData theme) {
    final u = _ubicacionGps;
    if (u == null) {
      return OutlinedButton.icon(
        onPressed: _compartirUbicacion,
        icon: const Icon(Icons.location_on_outlined),
        label: const Text('Compartir ubicación GPS'),
      );
    }
    return Card(
      child: ListTile(
        leading: const Icon(Icons.location_on),
        title: Text(u.coordenadas),
        subtitle: Text(u.direccionAproximada.isEmpty
            ? 'Ubicación capturada'
            : u.direccionAproximada),
        trailing: IconButton(
          tooltip: 'Quitar ubicación',
          icon: const Icon(Icons.close),
          onPressed: () => setState(() => _ubicacionGps = null),
        ),
      ),
    );
  }
}

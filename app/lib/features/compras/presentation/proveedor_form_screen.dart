import 'package:flutter/material.dart';

import '../../../core/validacion/correo.dart';
import '../../auth/domain/usuario.dart';
import '../data/proveedores_repository.dart';
import '../domain/proveedor.dart';

/// Formulario de proveedor (spec 007, RF-01).
class ProveedorFormScreen extends StatefulWidget {
  const ProveedorFormScreen({
    super.key,
    required this.usuario,
    this.proveedor,
    this.proveedoresRepository,
  });

  final Usuario usuario;
  final Proveedor? proveedor;
  final ProveedoresRepository? proveedoresRepository;

  @override
  State<ProveedorFormScreen> createState() => _ProveedorFormScreenState();
}

class _ProveedorFormScreenState extends State<ProveedorFormScreen> {
  late final ProveedoresRepository _repo =
      widget.proveedoresRepository ?? ProveedoresRepository();

  final _nombre = TextEditingController();
  final _nit = TextEditingController();
  final _direccion = TextEditingController();
  final _telefono = TextEditingController();
  final _correo = TextEditingController();
  final _contacto = TextEditingController();
  bool _activo = true;
  bool _guardando = false;

  String get _empresaId => widget.usuario.empresaId ?? '';
  bool get _esEdicion => widget.proveedor != null;

  @override
  void initState() {
    super.initState();
    final p = widget.proveedor;
    if (p != null) {
      _nombre.text = p.nombre;
      _nit.text = p.nit;
      _direccion.text = p.direccion;
      _telefono.text = p.telefono;
      _correo.text = p.correo;
      _contacto.text = p.contacto;
      _activo = p.activo;
    }
  }

  @override
  void dispose() {
    for (final c in <TextEditingController>[
      _nombre,
      _nit,
      _direccion,
      _telefono,
      _correo,
      _contacto,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _avisar(String m) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(m)));
  }

  Future<void> _guardar() async {
    final nombre = _nombre.text.trim();
    if (nombre.isEmpty) return _avisar('El nombre es obligatorio.');
    if (_correo.text.trim().isNotEmpty && !esCorreoValido(_correo.text)) {
      return _avisar('El correo no es válido.');
    }

    final proveedor = Proveedor(
      id: widget.proveedor?.id ?? _repo.nuevoId(),
      empresaId: _empresaId,
      nombre: nombre,
      nit: _nit.text.trim(),
      direccion: _direccion.text.trim(),
      telefono: _telefono.text.trim(),
      correo: _correo.text.trim(),
      contacto: _contacto.text.trim(),
      activo: _esEdicion ? _activo : true,
      fechaCreacion: widget.proveedor?.fechaCreacion,
    );

    setState(() => _guardando = true);
    try {
      if (_esEdicion) {
        await _repo.actualizar(proveedor);
      } else {
        await _repo.crear(proveedor);
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on NitDuplicadoException catch (e) {
      if (mounted) _avisar(e.toString());
    } catch (e) {
      if (mounted) _avisar('No se pudo guardar: $e');
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_esEdicion ? 'Editar proveedor' : 'Nuevo proveedor'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          _campo(_nombre, 'Nombre / razón social *'),
          _campo(_nit, 'NIT / RIF'),
          _campo(_direccion, 'Dirección'),
          _campo(_telefono, 'Teléfono'),
          _campo(_correo, 'Correo'),
          _campo(_contacto, 'Persona de contacto'),
          if (_esEdicion)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Activo'),
              value: _activo,
              onChanged: (bool v) => setState(() => _activo = v),
            ),
          const SizedBox(height: 16),
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
        ],
      ),
    );
  }

  Widget _campo(TextEditingController controller, String etiqueta) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: etiqueta,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}

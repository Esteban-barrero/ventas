import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../empresas/data/almacenamiento_repository.dart';
import '../data/usuarios_repository.dart';
import '../domain/usuario.dart';

/// Pantalla **"Mi perfil"** (spec 001): el usuario logueado actualiza su **foto**,
/// su nombre y su teléfono. La foto se muestra en el inicio.
class MiPerfilScreen extends StatefulWidget {
  const MiPerfilScreen({
    super.key,
    required this.usuario,
    this.usuariosRepository,
    this.almacenamiento,
    this.selectorImagen,
  });

  final Usuario usuario;
  final UsuariosRepository? usuariosRepository;
  final AlmacenamientoRepository? almacenamiento;

  /// Permite inyectar el selector de imagen en las pruebas.
  final Future<XFile?> Function()? selectorImagen;

  @override
  State<MiPerfilScreen> createState() => _MiPerfilScreenState();
}

class _MiPerfilScreenState extends State<MiPerfilScreen> {
  late final UsuariosRepository _repo =
      widget.usuariosRepository ?? UsuariosRepository();
  late final AlmacenamientoRepository _almacen =
      widget.almacenamiento ?? AlmacenamientoRepository();

  late final TextEditingController _nombre =
      TextEditingController(text: widget.usuario.nombre);
  late final TextEditingController _telefono =
      TextEditingController(text: widget.usuario.telefono);
  late String _foto = widget.usuario.foto;

  bool _guardando = false;
  bool _subiendo = false;

  @override
  void dispose() {
    _nombre.dispose();
    _telefono.dispose();
    super.dispose();
  }

  void _avisar(String m, {bool error = false}) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(m),
        backgroundColor: error ? Theme.of(context).colorScheme.error : null,
      ),
    );
  }

  /// Elige una imagen, la valida, la sube y guarda la URL en el perfil.
  Future<void> _cambiarFoto() async {
    setState(() => _subiendo = true);
    try {
      final XFile? archivo = widget.selectorImagen != null
          ? await widget.selectorImagen!()
          : await ImagePicker().pickImage(
              source: ImageSource.gallery,
              maxWidth: 512,
              maxHeight: 512,
            );
      if (archivo == null) return;

      final bytes = await archivo.readAsBytes();
      final extension = archivo.name.contains('.')
          ? archivo.name.split('.').last.toLowerCase()
          : 'jpg';

      try {
        AlmacenamientoRepository.validarFoto(bytes, extension: extension);
      } on ArchivoInvalidoException catch (e) {
        if (mounted) _avisar(e.mensaje, error: true);
        return;
      }

      final url = await _almacen.subirFotoUsuario(
        widget.usuario.uid,
        bytes,
        extension: extension,
      );
      await _repo.actualizarDatos(
        widget.usuario.uid,
        foto: url,
        autor: widget.usuario.uid,
      );
      if (mounted) {
        setState(() => _foto = url);
        _avisar('Foto actualizada.');
      }
    } catch (e) {
      if (mounted) _avisar('No se pudo subir la foto: $e', error: true);
    } finally {
      if (mounted) setState(() => _subiendo = false);
    }
  }

  Future<void> _guardar() async {
    setState(() => _guardando = true);
    try {
      await _repo.actualizarDatos(
        widget.usuario.uid,
        nombre: _nombre.text,
        telefono: _telefono.text,
        autor: widget.usuario.uid,
      );
      if (!mounted) return;
      Navigator.of(context).pop(_foto);
    } catch (e) {
      if (mounted) _avisar('No se pudo guardar: $e', error: true);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Mi perfil')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Center(
            child: Column(
              children: <Widget>[
                _avatar(48, tema),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: _subiendo ? null : _cambiarFoto,
                  icon: _subiendo
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.photo_camera_outlined),
                  label: Text(_subiendo ? 'Subiendo…' : 'Cambiar foto'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _nombre,
            decoration: const InputDecoration(
              labelText: 'Nombre',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _telefono,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Teléfono',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.usuario.email,
            style: tema.textTheme.bodySmall,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _guardando ? null : _guardar,
            icon: const Icon(Icons.save_outlined),
            label: Text(_guardando ? 'Guardando…' : 'Guardar'),
          ),
        ],
      ),
    );
  }

  Widget _avatar(double radius, ThemeData tema) {
    if (_foto.trim().isEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: tema.colorScheme.primary,
        child: Text(
          _iniciales(widget.usuario.nombre.isEmpty
              ? widget.usuario.email
              : widget.usuario.nombre),
          style: tema.textTheme.headlineSmall?.copyWith(
            color: tema.colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
    return CircleAvatar(radius: radius, backgroundImage: NetworkImage(_foto));
  }

  static String _iniciales(String texto) {
    final partes =
        texto.trim().split(RegExp(r'[\s@._-]+')).where((p) => p.isNotEmpty);
    if (partes.isEmpty) return '?';
    return partes.take(2).map((p) => p[0].toUpperCase()).join();
  }
}

import 'package:flutter/material.dart';

import '../../auth/domain/usuario.dart';
import '../data/categorias_repository.dart';
import '../domain/categoria.dart';

/// Gestión de categorías del catálogo (spec 003, RF-10 / T023).
class CategoriasScreen extends StatefulWidget {
  const CategoriasScreen({
    super.key,
    required this.usuario,
    this.categoriasRepository,
  });

  final Usuario usuario;
  final CategoriasRepository? categoriasRepository;

  @override
  State<CategoriasScreen> createState() => _CategoriasScreenState();
}

class _CategoriasScreenState extends State<CategoriasScreen> {
  late final CategoriasRepository _repo =
      widget.categoriasRepository ?? CategoriasRepository();

  String get _empresaId => widget.usuario.empresaId ?? '';

  void _avisar(String mensaje, {bool error = false}) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: error ? Theme.of(context).colorScheme.error : null,
      ),
    );
  }

  Future<void> _editar([Categoria? categoria]) async {
    final nombre = TextEditingController(text: categoria?.nombre ?? '');
    final descripcion =
        TextEditingController(text: categoria?.descripcion ?? '');

    final guardar = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(categoria == null ? 'Nueva categoría' : 'Editar categoría'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              controller: nombre,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descripcion,
              decoration: const InputDecoration(
                labelText: 'Descripción (opcional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (guardar != true) return;
    if (nombre.text.trim().isEmpty) {
      if (mounted) _avisar('El nombre es obligatorio.');
      return;
    }

    try {
      if (categoria == null) {
        await _repo.crear(Categoria(
          id: '',
          empresaId: _empresaId,
          nombre: nombre.text.trim(),
          descripcion: descripcion.text.trim(),
        ));
      } else {
        await _repo.actualizar(categoria.copyWith(
          nombre: nombre.text.trim(),
          descripcion: descripcion.text.trim(),
        ));
      }
      if (mounted) _avisar('Categoría guardada.');
    } catch (e) {
      if (mounted) _avisar('No se pudo guardar: $e', error: true);
    }
  }

  Future<void> _cambiarActivo(Categoria categoria, bool activo) async {
    try {
      await _repo.activar(categoria.id, activo, empresaId: _empresaId);
    } catch (e) {
      if (mounted) _avisar('No se pudo cambiar: $e', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Categorías')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _editar(),
        icon: const Icon(Icons.add),
        label: const Text('Nueva categoría'),
      ),
      body: StreamBuilder<List<Categoria>>(
        stream: _repo.escuchar(_empresaId),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final lista = snap.data ?? const <Categoria>[];
          if (lista.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Todavía no hay categorías.'),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 96),
            itemCount: lista.length,
            itemBuilder: (context, i) {
              final c = lista[i];
              return ListTile(
                leading: const Icon(Icons.category_outlined),
                title: Text(c.nombre),
                subtitle: c.descripcion.isEmpty ? null : Text(c.descripcion),
                onTap: () => _editar(c),
                trailing: Switch(
                  value: c.activo,
                  onChanged: (v) => _cambiarActivo(c, v),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../auth/domain/permisos.dart';
import '../../auth/domain/usuario.dart';
import '../data/proveedores_repository.dart';
import '../domain/proveedor.dart';
import 'proveedor_form_screen.dart';

/// Listado de proveedores (spec 007, RF-01).
class ProveedoresListScreen extends StatefulWidget {
  const ProveedoresListScreen({
    super.key,
    required this.usuario,
    this.proveedoresRepository,
  });

  final Usuario usuario;
  final ProveedoresRepository? proveedoresRepository;

  @override
  State<ProveedoresListScreen> createState() => _ProveedoresListScreenState();
}

class _ProveedoresListScreenState extends State<ProveedoresListScreen> {
  late final ProveedoresRepository _repo =
      widget.proveedoresRepository ?? ProveedoresRepository();

  final TextEditingController _busqueda = TextEditingController();

  String get _empresaId => widget.usuario.empresaId ?? '';

  /// Solo el Administrador puede crear/editar proveedores (reglas).
  bool get _puedeEditar => widget.usuario.puede(Permiso.comprasEditar);

  @override
  void initState() {
    super.initState();
    _busqueda.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _busqueda.dispose();
    super.dispose();
  }

  Future<void> _nuevo() async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => ProveedorFormScreen(usuario: widget.usuario),
      ),
    );
  }

  Future<void> _editar(Proveedor proveedor) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => ProveedorFormScreen(
          usuario: widget.usuario,
          proveedor: proveedor,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Proveedores')),
      floatingActionButton: _puedeEditar
          ? FloatingActionButton.extended(
              onPressed: _nuevo,
              icon: const Icon(Icons.add),
              label: const Text('Nuevo proveedor'),
            )
          : null,
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: _busqueda,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Buscar por nombre o NIT',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Proveedor>>(
              stream: _repo.escuchar(_empresaId),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final todos = snap.data ?? const <Proveedor>[];
                final visibles = ProveedoresRepository.filtrar(
                  todos,
                  busqueda: _busqueda.text,
                );
                if (visibles.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            todos.isEmpty
                                ? 'Todavía no hay proveedores.'
                                : 'No se encontraron proveedores.',
                            textAlign: TextAlign.center,
                          ),
                          if (todos.isEmpty && _puedeEditar) ...<Widget>[
                            const SizedBox(height: 16),
                            FilledButton.icon(
                              onPressed: _nuevo,
                              icon: const Icon(Icons.add),
                              label: const Text('Crear proveedor'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.only(bottom: 96),
                  itemCount: visibles.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final p = visibles[i];
                    return ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.storefront)),
                      title: Text(p.nombre),
                      subtitle: Text(p.nit.isEmpty ? 'Sin NIT' : 'NIT ${p.nit}'),
                      trailing: p.activo
                          ? null
                          : const Text('Inactivo',
                              style: TextStyle(fontSize: 12)),
                      onTap: _puedeEditar ? () => _editar(p) : null,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

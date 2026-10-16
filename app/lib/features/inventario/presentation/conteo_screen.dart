import 'package:flutter/material.dart';

import '../../auth/domain/usuario.dart';
import '../../catalogo/data/productos_repository.dart';
import '../../catalogo/domain/producto.dart';
import '../data/inventario_repository.dart';
import '../domain/conteo_inventario.dart';

/// Conteo físico (spec 008, T033): se ingresa el stock contado y al cerrar se
/// generan los ajustes por diferencia.
class ConteoScreen extends StatefulWidget {
  const ConteoScreen({
    super.key,
    required this.usuario,
    this.productosRepository,
    this.inventarioRepository,
  });

  final Usuario usuario;
  final ProductosRepository? productosRepository;
  final InventarioRepository? inventarioRepository;

  @override
  State<ConteoScreen> createState() => _ConteoScreenState();
}

class _ConteoScreenState extends State<ConteoScreen> {
  late final ProductosRepository _productos =
      widget.productosRepository ?? ProductosRepository();
  late final InventarioRepository _inventario =
      widget.inventarioRepository ?? InventarioRepository();

  final Map<String, TextEditingController> _contadores =
      <String, TextEditingController>{};
  List<Producto> _lista = const <Producto>[];
  bool _cargando = true;
  bool _guardando = false;

  String get _empresaId => widget.usuario.empresaId ?? '';

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    for (final c in _contadores.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _cargar() async {
    try {
      final productos = await _productos.listar(_empresaId, activo: true);
      if (!mounted) return;
      setState(() {
        _lista = productos;
        for (final p in productos) {
          _contadores[p.id] = TextEditingController(text: '${p.stock}');
        }
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _cargando = false);
    }
  }

  List<ItemConteo> _items() => <ItemConteo>[
        for (final p in _lista)
          ItemConteo(
            productoId: p.id,
            nombre: p.nombre,
            stockSistema: p.stock,
            stockFisico: int.tryParse(_contadores[p.id]?.text.trim() ?? '') ?? p.stock,
          ),
      ];

  int get _conDiferencia =>
      _items().where((ItemConteo i) => i.diferencia != 0).length;

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

  Future<void> _cerrar() async {
    final items = _items();
    if (_conDiferencia == 0) {
      return _avisar('No hay diferencias que ajustar.');
    }
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar conteo'),
        content: Text(
          'Se generarán ajustes por las diferencias de $_conDiferencia '
          'producto(s). ¿Continuar?',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Cerrar conteo'),
          ),
        ],
      ),
    );
    if (confirmar != true) return;

    setState(() => _guardando = true);
    try {
      await _inventario.registrarConteo(
        ConteoInventario(
          id: '',
          empresaId: _empresaId,
          fecha: DateTime.now(),
          items: items,
        ),
        usuarioUid: widget.usuario.uid,
      );
      if (!mounted) return;
      _avisar('Conteo cerrado y ajustes generados.');
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) _avisar('No se pudo cerrar el conteo: $e', error: true);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Conteo físico')),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Ingresa el stock contado. Al cerrar se generan los ajustes '
                    'por las diferencias ($_conDiferencia).',
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _lista.length,
                    itemBuilder: (context, i) {
                      final p = _lista[i];
                      return ListTile(
                        title: Text(p.nombre,
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text('Sistema: ${p.stock}'),
                        trailing: SizedBox(
                          width: 90,
                          child: TextField(
                            controller: _contadores[p.id],
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setState(() {}),
                            decoration: const InputDecoration(
                              labelText: 'Físico',
                              isDense: true,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _guardando ? null : _cerrar,
                      icon: const Icon(Icons.check),
                      label: Text(_guardando ? 'Cerrando…' : 'Cerrar conteo'),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

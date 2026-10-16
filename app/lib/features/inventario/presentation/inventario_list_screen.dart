import 'package:flutter/material.dart';

import '../../../core/formato/fechas.dart';
import '../../auth/domain/usuario.dart';
import '../../catalogo/data/productos_repository.dart';
import '../../catalogo/domain/producto.dart';
import '../data/inventario_repository.dart';
import '../domain/valorizacion.dart';
import 'conteo_screen.dart';
import 'kardex_screen.dart';

/// Filtro rápido del listado de inventario.
enum _Filtro { todos, bajo, agotado }

/// Listado de inventario (spec 008, T030): stock, alertas y valorización.
class InventarioListScreen extends StatefulWidget {
  const InventarioListScreen({
    super.key,
    required this.usuario,
    this.productosRepository,
    this.inventarioRepository,
  });

  final Usuario usuario;
  final ProductosRepository? productosRepository;
  final InventarioRepository? inventarioRepository;

  @override
  State<InventarioListScreen> createState() => _InventarioListScreenState();
}

class _InventarioListScreenState extends State<InventarioListScreen> {
  late final ProductosRepository _productos =
      widget.productosRepository ?? ProductosRepository();
  late final InventarioRepository _inventario =
      widget.inventarioRepository ?? InventarioRepository();

  final TextEditingController _busqueda = TextEditingController();
  _Filtro _filtro = _Filtro.todos;

  String get _empresaId => widget.usuario.empresaId ?? '';

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

  List<Producto> _filtrar(List<Producto> productos) {
    final q = _busqueda.text.trim().toLowerCase();
    return productos.where((Producto p) {
      if (_filtro == _Filtro.bajo && p.stock > p.stockMinimo) return false;
      if (_filtro == _Filtro.agotado && p.stock > 0) return false;
      if (q.isNotEmpty &&
          !p.nombre.toLowerCase().contains(q) &&
          !p.codigo.toLowerCase().contains(q)) {
        return false;
      }
      return true;
    }).toList(growable: false);
  }

  Future<void> _abrirKardex(Producto producto) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => KardexScreen(
          productoId: producto.id,
          nombre: producto.nombre,
          usuario: widget.usuario,
          inventarioRepository: _inventario,
        ),
      ),
    );
  }

  Future<void> _nuevoConteo() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ConteoScreen(
          usuario: widget.usuario,
          productosRepository: _productos,
          inventarioRepository: _inventario,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_empresaId.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Inventario')),
        body: const Center(child: Text('No perteneces a ninguna empresa.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Inventario')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _nuevoConteo,
        icon: const Icon(Icons.fact_check_outlined),
        label: const Text('Nuevo conteo'),
      ),
      body: StreamBuilder<List<Producto>>(
        stream: _productos.escuchar(_empresaId),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final todos = snap.data ?? const <Producto>[];
          final visibles = _filtrar(todos);
          final bajo = bajoStockDe(todos).length;
          final agotados = agotadosDe(todos).length;

          return Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Column(
                  children: <Widget>[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: <Widget>[
                            const Icon(Icons.pie_chart_outline),
                            const SizedBox(width: 8),
                            const Expanded(child: Text('Valorización')),
                            Text(
                              formatearValor(valorizarInventario(todos)),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _busqueda,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        hintText: 'Buscar producto',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: <Widget>[
                        ChoiceChip(
                          label: Text('Todos (${todos.length})'),
                          selected: _filtro == _Filtro.todos,
                          onSelected: (_) => setState(() => _filtro = _Filtro.todos),
                        ),
                        ChoiceChip(
                          label: Text('Bajo stock ($bajo)'),
                          selected: _filtro == _Filtro.bajo,
                          onSelected: (_) => setState(() => _filtro = _Filtro.bajo),
                        ),
                        ChoiceChip(
                          label: Text('Agotado ($agotados)'),
                          selected: _filtro == _Filtro.agotado,
                          onSelected: (_) => setState(() => _filtro = _Filtro.agotado),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: visibles.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text('No hay productos con ese filtro.'),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.only(bottom: 96),
                        itemCount: visibles.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, i) => _tile(visibles[i]),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _tile(Producto p) {
    final scheme = Theme.of(context).colorScheme;
    final bajo = p.stockBajo;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: p.stock <= 0
            ? scheme.errorContainer
            : (bajo ? scheme.tertiaryContainer : scheme.primaryContainer),
        child: Text('${p.stock}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: p.stock <= 0 ? scheme.onErrorContainer : null,
            )),
      ),
      title: Text(p.nombre, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        '${p.codigo} · Mín ${p.stockMinimo} · Valor ${formatearValor(valorizarProducto(p))}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: p.stock <= 0
          ? Text('Agotado', style: TextStyle(color: scheme.error, fontSize: 12))
          : (bajo
              ? const Text('Bajo', style: TextStyle(fontSize: 12))
              : null),
      onTap: () => _abrirKardex(p),
    );
  }
}

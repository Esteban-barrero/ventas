import 'package:flutter/material.dart';

import '../../../core/formato/fechas.dart';
import '../../catalogo/data/categorias_repository.dart';
import '../../catalogo/data/productos_repository.dart';
import '../../catalogo/domain/categoria.dart';
import '../../catalogo/domain/precio.dart';
import '../../catalogo/domain/producto.dart';
import '../../empresas/domain/empresa.dart';
import 'checkout_tienda_screen.dart';

/// Línea del carrito público.
class LineaTienda {
  LineaTienda(this.producto, this.cantidad);

  final Producto producto;
  int cantidad;
}

/// **Catálogo público** de una empresa (spec 010): productos con foto, buscador
/// y filtro por categoría. El invitado arma el carrito y hace el pedido.
class CatalogoTiendaScreen extends StatefulWidget {
  const CatalogoTiendaScreen({
    super.key,
    required this.empresa,
    required this.onIngresar,
    this.productosRepository,
    this.categoriasRepository,
  });

  final Empresa empresa;
  final VoidCallback onIngresar;
  final ProductosRepository? productosRepository;
  final CategoriasRepository? categoriasRepository;

  @override
  State<CatalogoTiendaScreen> createState() => _CatalogoTiendaScreenState();
}

class _CatalogoTiendaScreenState extends State<CatalogoTiendaScreen> {
  late final ProductosRepository _productosRepo =
      widget.productosRepository ?? ProductosRepository();
  late final CategoriasRepository _categoriasRepo =
      widget.categoriasRepository ?? CategoriasRepository();

  final List<LineaTienda> _lineas = <LineaTienda>[];
  List<Producto> _productos = const <Producto>[];
  List<Categoria> _categorias = const <Categoria>[];
  String _busqueda = '';
  String? _categoriaId;
  bool _cargando = true;

  String get _empresaId => widget.empresa.id;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final productos =
          await _productosRepo.listar(_empresaId, activo: true);
      final categorias =
          await _categoriasRepo.listar(_empresaId, soloActivas: true);
      if (!mounted) return;
      setState(() {
        _productos = productos;
        _categorias = categorias;
        _cargando = false;
      });
    } catch (_) {
      if (mounted) setState(() => _cargando = false);
    }
  }

  double _precioUnitario(Producto p) =>
      p.precio(TipoPrecio.contado, widget.empresa.parametros);

  double get _subtotal => _lineas.fold(
      0.0, (double a, LineaTienda l) => a + _precioUnitario(l.producto) * l.cantidad);

  int get _unidades =>
      _lineas.fold(0, (int a, LineaTienda l) => a + l.cantidad);

  void _agregar(Producto p) {
    if (p.stock <= 0) return;
    setState(() {
      final idx = _lineas.indexWhere((LineaTienda l) => l.producto.id == p.id);
      if (idx >= 0) {
        _lineas[idx].cantidad += 1;
      } else {
        _lineas.add(LineaTienda(p, 1));
      }
    });
  }

  void _quitar(Producto p) {
    setState(() {
      final idx = _lineas.indexWhere((LineaTienda l) => l.producto.id == p.id);
      if (idx < 0) return;
      if (_lineas[idx].cantidad <= 1) {
        _lineas.removeAt(idx);
      } else {
        _lineas[idx].cantidad -= 1;
      }
    });
  }

  Future<void> _hacerPedido() async {
    if (_lineas.isEmpty) return;
    final pedir = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(
        builder: (context, setSheet) => Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Carrito (${_lineas.length})',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: <Widget>[
                    for (final l in _lineas)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(l.producto.nombre),
                        subtitle: Text(
                            '${formatearValor(_precioUnitario(l.producto))} c/u'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: () {
                                _quitar(l.producto);
                                setSheet(() {});
                              },
                            ),
                            Text('${l.cantidad}'),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              onPressed: () {
                                _agregar(l.producto);
                                setSheet(() {});
                              },
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const Divider(),
              Row(
                children: <Widget>[
                  const Expanded(child: Text('Total')),
                  Text(formatearValor(_subtotal),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => Navigator.of(context).pop(true),
                  icon: const Icon(Icons.shopping_bag_outlined),
                  label: const Text('Hacer pedido'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (pedir != true) return;
    if (!mounted) return;

    final creado = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => CheckoutTiendaScreen(
          empresa: widget.empresa,
          lineas: _lineas,
          onIngresar: widget.onIngresar,
        ),
      ),
    );
    if (creado == true && mounted) {
      setState(() => _lineas.clear());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Pedido enviado! La empresa lo revisará.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = _busqueda.trim().toLowerCase();
    final visibles = _productos.where((Producto p) {
      if (_categoriaId != null && p.categoriaId != _categoriaId) return false;
      if (q.isEmpty) return true;
      return p.nombre.toLowerCase().contains(q) ||
          p.codigo.toLowerCase().contains(q) ||
          p.codigoBarras.toLowerCase().contains(q);
    }).toList(growable: false);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.empresa.nombre),
        actions: <Widget>[
          TextButton.icon(
            onPressed: widget.onIngresar,
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
            icon: const Icon(Icons.login),
            label: const Text('Iniciar sesión'),
          ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                  child: TextField(
                    onChanged: (v) => setState(() => _busqueda = v),
                    decoration: const InputDecoration(
                      hintText: 'Buscar producto',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                if (_categorias.isNotEmpty)
                  SizedBox(
                    height: 44,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: const Text('Todas'),
                            selected: _categoriaId == null,
                            onSelected: (_) =>
                                setState(() => _categoriaId = null),
                          ),
                        ),
                        for (final c in _categorias)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(c.nombre),
                              selected: _categoriaId == c.id,
                              onSelected: (_) =>
                                  setState(() => _categoriaId = c.id),
                            ),
                          ),
                      ],
                    ),
                  ),
                Expanded(
                  child: visibles.isEmpty
                      ? const Center(child: Text('No se encontraron productos.'))
                      : GridView.builder(
                          padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.72,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                          itemCount: visibles.length,
                          itemBuilder: (context, i) => _tarjeta(visibles[i]),
                        ),
                ),
              ],
            ),
      bottomNavigationBar: _lineas.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: FilledButton.icon(
                  onPressed: _hacerPedido,
                  icon: const Icon(Icons.shopping_cart_outlined),
                  label: Text(
                    'Carrito ($_unidades) · ${formatearValor(_subtotal)}',
                  ),
                ),
              ),
            ),
    );
  }

  Widget _tarjeta(Producto p) {
    final theme = Theme.of(context);
    final precio = _precioUnitario(p);
    final agotado = p.stock <= 0;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: InkWell(
              onTap: agotado ? null : () => _agregar(p),
              child: p.fotoPrincipal.trim().isEmpty
                  ? Container(
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: const Center(
                        child: Icon(Icons.image_outlined, size: 36),
                      ),
                    )
                  : Image.network(
                      p.fotoPrincipal,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (_, _, _) => Container(
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: const Center(
                          child: Icon(Icons.broken_image_outlined, size: 36),
                        ),
                      ),
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
            child: Text(p.nombre,
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              formatearValor(precio),
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 4, 4),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    agotado ? 'Agotado' : 'Stock ${p.stock}',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
                IconButton(
                  tooltip: 'Agregar',
                  icon: const Icon(Icons.add_shopping_cart_outlined, size: 20),
                  onPressed: agotado ? null : () => _agregar(p),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

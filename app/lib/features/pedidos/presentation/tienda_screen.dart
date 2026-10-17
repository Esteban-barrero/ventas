import 'package:flutter/material.dart';

import '../../../core/formato/fechas.dart';
import '../../auth/domain/usuario.dart';
import '../../catalogo/data/productos_repository.dart';
import '../../catalogo/domain/precio.dart';
import '../../catalogo/domain/producto.dart';
import '../../clientes/data/clientes_repository.dart';
import '../../clientes/domain/cliente.dart';
import '../../empresas/data/empresas_repository.dart';
import '../../empresas/domain/parametros_empresa.dart';
import '../data/pedidos_repository.dart';
import 'checkout_pedido_screen.dart';
import 'mis_pedidos_screen.dart';

/// Una línea del carrito de la tienda (producto + cantidad).
class LineaCarrito {
  LineaCarrito(this.producto, this.cantidad);

  final Producto producto;
  int cantidad;

  double get precioUnitario => producto.precio(TipoPrecio.contado, parametros);

  ParametrosEmpresa parametros = const ParametrosEmpresa();
}

/// **Tienda** para el cliente (spec 010): catálogo, carrito y pedido.
class TiendaScreen extends StatefulWidget {
  const TiendaScreen({
    super.key,
    required this.usuario,
    this.productosRepository,
    this.empresasRepository,
    this.clientesRepository,
    this.pedidosRepository,
  });

  final Usuario usuario;
  final ProductosRepository? productosRepository;
  final EmpresasRepository? empresasRepository;
  final ClientesRepository? clientesRepository;
  final PedidosRepository? pedidosRepository;

  @override
  State<TiendaScreen> createState() => _TiendaScreenState();
}

class _TiendaScreenState extends State<TiendaScreen> {
  late final ProductosRepository _productosRepo =
      widget.productosRepository ?? ProductosRepository();
  late final EmpresasRepository _empresasRepo =
      widget.empresasRepository ?? EmpresasRepository();
  late final ClientesRepository _clientesRepo =
      widget.clientesRepository ?? ClientesRepository();
  late final PedidosRepository _pedidosRepo =
      widget.pedidosRepository ?? PedidosRepository();

  final List<LineaCarrito> _lineas = <LineaCarrito>[];
  List<Producto> _productos = const <Producto>[];
  ParametrosEmpresa _parametros = const ParametrosEmpresa();
  Cliente? _cliente;
  bool _cargando = true;

  String get _empresaId => widget.usuario.empresaId ?? '';

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final empresa = await _empresasRepo.obtener(_empresaId);
      final productos = await _productosRepo.listar(_empresaId, activo: true);
      final clientes = await _clientesRepo.listar(_empresaId);
      Cliente? mio;
      for (final c in clientes) {
        if (c.uid != null && c.uid == widget.usuario.uid) {
          mio = c;
          break;
        }
      }
      if (!mounted) return;
      setState(() {
        _parametros = empresa?.parametros ?? const ParametrosEmpresa();
        _productos = productos;
        _cliente = mio;
        _cargando = false;
        for (final l in _lineas) {
          l.parametros = _parametros;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _cargando = false);
      _avisar('No se pudo cargar la tienda: $e', error: true);
    }
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

  double get _subtotal =>
      _lineas.fold(0.0, (double a, LineaCarrito l) => a + l.precioUnitario * l.cantidad);

  int get _unidades =>
      _lineas.fold(0, (int a, LineaCarrito l) => a + l.cantidad);

  void _agregar(Producto p) {
    if (p.stock <= 0) return _avisar('Producto agotado.', error: true);
    setState(() {
      final idx = _lineas.indexWhere((LineaCarrito l) => l.producto.id == p.id);
      if (idx >= 0) {
        _lineas[idx].cantidad += 1;
      } else {
        final linea = LineaCarrito(p, 1);
        linea.parametros = _parametros;
        _lineas.add(linea);
      }
    });
  }

  void _quitar(Producto p, {bool todo = false}) {
    setState(() {
      final idx = _lineas.indexWhere((LineaCarrito l) => l.producto.id == p.id);
      if (idx < 0) return;
      if (todo || _lineas[idx].cantidad <= 1) {
        _lineas.removeAt(idx);
      } else {
        _lineas[idx].cantidad -= 1;
      }
    });
  }

  Future<void> _verCarrito() async {
    if (_lineas.isEmpty) return _avisar('El carrito está vacío.');
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
                            '${formatearValor(l.precioUnitario)} c/u'),
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
        builder: (_) => CheckoutPedidoScreen(
          usuario: widget.usuario,
          lineas: _lineas,
          parametros: _parametros,
          cliente: _cliente,
          pedidosRepository: _pedidosRepo,
        ),
      ),
    );
    if (creado == true && mounted) {
      setState(() => _lineas.clear());
      _avisar('Pedido enviado. La empresa lo revisará.');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_empresaId.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Tienda')),
        body: const Center(child: Text('No perteneces a ninguna empresa.')),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tienda'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Mis pedidos',
            icon: const Icon(Icons.receipt_long_outlined),
            onPressed: () => Navigator.of(context).push<void>(
              MaterialPageRoute<void>(
                builder: (_) => MisPedidosScreen(
                  usuario: widget.usuario,
                  pedidosRepository: _pedidosRepo,
                ),
              ),
            ),
          ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _productos.isEmpty
              ? const Center(child: Text('No hay productos disponibles.'))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
                  itemCount: _productos.length,
                  itemBuilder: (context, i) => _tile(_productos[i]),
                ),
      bottomNavigationBar: _lineas.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: FilledButton.icon(
                  onPressed: _verCarrito,
                  icon: const Icon(Icons.shopping_cart_outlined),
                  label: Text(
                    'Carrito ($_unidades) · ${formatearValor(_subtotal)}',
                  ),
                ),
              ),
            ),
    );
  }

  Widget _tile(Producto p) {
    final theme = Theme.of(context);
    final precio = p.precio(TipoPrecio.contado, _parametros);
    final agotado = p.stock <= 0;
    return Card(
      child: ListTile(
        title: Text(p.nombre),
        subtitle: Text(
          '${p.codigo} · ${formatearValor(precio)}'
          '${agotado ? ' · Agotado' : ' · Stock ${p.stock}'}',
          style: theme.textTheme.bodySmall,
        ),
        trailing: IconButton(
          tooltip: 'Agregar',
          icon: const Icon(Icons.add_shopping_cart_outlined),
          onPressed: agotado ? null : () => _agregar(p),
        ),
      ),
    );
  }
}

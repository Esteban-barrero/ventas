import 'package:flutter/material.dart';

import '../../../core/formato/fechas.dart';
import '../../auth/domain/usuario.dart';
import '../../catalogo/data/productos_repository.dart';
import '../../catalogo/domain/producto.dart';
import '../../empresas/data/empresas_repository.dart';
import '../../empresas/domain/parametros_empresa.dart';
import '../data/compras_repository.dart';
import '../data/proveedores_repository.dart';
import '../domain/compra.dart';
import '../domain/proveedor.dart';
import '../domain/totales_compra.dart';

/// Una línea de la compra: producto, cantidad y costo unitario (editable).
class _LineaCompra {
  _LineaCompra(this.producto, this.cantidad, String costo)
      : costo = TextEditingController(text: costo);

  final Producto producto;
  int cantidad;
  final TextEditingController costo;

  double get costoNum => double.tryParse(costo.text.trim()) ?? 0;
}

/// Formulario de registro de una compra (spec 007, RF-02/RF-03/RF-07).
class CompraFormScreen extends StatefulWidget {
  const CompraFormScreen({
    super.key,
    required this.usuario,
    this.comprasRepository,
    this.proveedoresRepository,
    this.productosRepository,
    this.empresasRepository,
  });

  final Usuario usuario;
  final ComprasRepository? comprasRepository;
  final ProveedoresRepository? proveedoresRepository;
  final ProductosRepository? productosRepository;
  final EmpresasRepository? empresasRepository;

  @override
  State<CompraFormScreen> createState() => _CompraFormScreenState();
}

class _CompraFormScreenState extends State<CompraFormScreen> {
  late final ComprasRepository _compras =
      widget.comprasRepository ?? ComprasRepository();
  late final ProveedoresRepository _proveedoresRepo =
      widget.proveedoresRepository ?? ProveedoresRepository();
  late final ProductosRepository _productosRepo =
      widget.productosRepository ?? ProductosRepository();
  late final EmpresasRepository _empresasRepo =
      widget.empresasRepository ?? EmpresasRepository();

  final List<_LineaCompra> _lineas = <_LineaCompra>[];
  final _numeroOrden = TextEditingController();
  final _observaciones = TextEditingController();

  ParametrosEmpresa _parametros = const ParametrosEmpresa();
  List<Proveedor> _proveedores = const <Proveedor>[];
  List<Producto> _productos = const <Producto>[];
  String? _proveedorId;
  FormaPagoCompra _formaPago = FormaPagoCompra.contado;
  bool _actualizaCosto = true;
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
    for (final l in _lineas) {
      l.costo.dispose();
    }
    _numeroOrden.dispose();
    _observaciones.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    try {
      final empresa = await _empresasRepo.obtener(_empresaId);
      final proveedores = await _proveedoresRepo.listar(_empresaId, soloActivos: true);
      final productos = await _productosRepo.listar(_empresaId, activo: true);
      if (!mounted) return;
      setState(() {
        _parametros = empresa?.parametros ?? const ParametrosEmpresa();
        _proveedores = proveedores;
        _productos = productos;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _cargando = false);
      _avisar('No se pudieron cargar los datos: $e');
    }
  }

  void _avisar(String m) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(m)));
  }

  List<ItemCompra> _items() => <ItemCompra>[
        for (final l in _lineas)
          ItemCompra(
            productoId: l.producto.id,
            codigo: l.producto.codigo,
            nombre: l.producto.nombre,
            cantidad: l.cantidad,
            costoUnitario: l.costoNum,
            iva: l.producto.ivaEfectivo(_parametros),
          ),
      ];

  TotalesCompra get _totales {
    final items = _items();
    final sub = subtotalCompra(items);
    final iva = ivaCompra(items);
    return calcularTotalesCompra(
      items,
      retencionFuente: sub * _parametros.reteFuente / 100,
      retencionIva: iva * _parametros.reteIva / 100,
      retencionIca: sub * _parametros.reteIca / 100,
    );
  }

  Future<void> _agregarProducto() async {
    final producto = await showModalBottomSheet<Producto>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _SelectorProductos(productos: _productos),
    );
    if (producto == null) return;
    setState(() {
      final idx = _lineas.indexWhere((l) => l.producto.id == producto.id);
      if (idx >= 0) {
        _lineas[idx].cantidad += 1;
      } else {
        _lineas.add(_LineaCompra(
          producto,
          1,
          producto.costo.round().toString(),
        ));
      }
    });
  }

  Future<void> _registrar() async {
    if (_proveedorId == null) return _avisar('Selecciona el proveedor.');
    if (_lineas.isEmpty) return _avisar('Agrega al menos un producto.');

    final proveedor = _proveedores.firstWhere((p) => p.id == _proveedorId);
    final t = _totales;
    final compra = Compra(
      id: '',
      empresaId: _empresaId,
      numeroOrden: _numeroOrden.text.trim(),
      proveedorId: proveedor.id,
      proveedorNombre: proveedor.nombre,
      items: _items(),
      subtotal: t.subtotal,
      iva: t.iva,
      retencionFuente: t.retencionFuente,
      retencionIva: t.retencionIva,
      retencionIca: t.retencionIca,
      valorTotal: t.total,
      formaPago: _formaPago,
      actualizaCosto: _actualizaCosto,
      observaciones: _observaciones.text.trim(),
    );

    setState(() => _guardando = true);
    try {
      await _compras.registrar(compra);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) _avisar('No se pudo registrar la compra: $e');
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_cargando) {
      return Scaffold(
        appBar: AppBar(title: const Text('Nueva compra')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final t = _totales;

    return Scaffold(
      appBar: AppBar(title: const Text('Nueva compra')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          DropdownButtonFormField<String?>(
            initialValue: _proveedorId,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Proveedor *',
              border: OutlineInputBorder(),
            ),
            items: <DropdownMenuItem<String?>>[
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('Selecciona…'),
              ),
              for (final p in _proveedores)
                DropdownMenuItem<String?>(value: p.id, child: Text(p.nombre)),
            ],
            onChanged: (String? v) => setState(() => _proveedorId = v),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _numeroOrden,
            decoration: const InputDecoration(
              labelText: 'Número de orden (opcional)',
              helperText: 'Si lo dejas vacío, se asigna automáticamente (OC-…)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          _seccion(theme, 'Productos'),
          if (_lineas.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('Todavía no has agregado productos.'),
            )
          else
            ..._lineas.map(_lineaWidget),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _agregarProducto,
            icon: const Icon(Icons.add),
            label: const Text('Agregar producto'),
          ),
          const SizedBox(height: 16),
          _seccion(theme, 'Pago'),
          DropdownButtonFormField<FormaPagoCompra>(
            initialValue: _formaPago,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Forma de pago',
              border: OutlineInputBorder(),
            ),
            items: <DropdownMenuItem<FormaPagoCompra>>[
              for (final f in FormaPagoCompra.values)
                DropdownMenuItem<FormaPagoCompra>(value: f, child: Text(f.nombre)),
            ],
            onChanged: (FormaPagoCompra? v) =>
                setState(() => _formaPago = v ?? FormaPagoCompra.contado),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Actualizar costo del producto'),
            subtitle: const Text('Usa el costo de esta compra como nuevo costo'),
            value: _actualizaCosto,
            onChanged: (bool v) => setState(() => _actualizaCosto = v),
          ),
          TextField(
            controller: _observaciones,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Observaciones',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: <Widget>[
                  _fila('Subtotal', formatearValor(t.subtotal)),
                  _fila('IVA', formatearValor(t.iva)),
                  if (t.retencionFuente > 0)
                    _fila('Retención fuente', '-${formatearValor(t.retencionFuente)}'),
                  if (t.retencionIva > 0)
                    _fila('ReteIVA', '-${formatearValor(t.retencionIva)}'),
                  if (t.retencionIca > 0)
                    _fila('ReteICA', '-${formatearValor(t.retencionIca)}'),
                  const Divider(),
                  _fila('Total a pagar', formatearValor(t.total), negrita: true),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _guardando ? null : _registrar,
            icon: _guardando
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check),
            label: Text(_guardando ? 'Registrando…' : 'Registrar compra'),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _lineaWidget(_LineaCompra linea) {
    final theme = Theme.of(context);
    final subtotal = linea.cantidad * linea.costoNum;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(linea.producto.nombre,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: () => setState(() {
                    if (linea.cantidad > 1) {
                      linea.cantidad -= 1;
                    } else {
                      _lineas.remove(linea);
                    }
                  }),
                ),
                Text('${linea.cantidad}', style: theme.textTheme.titleMedium),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () => setState(() => linea.cantidad += 1),
                ),
              ],
            ),
            Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: linea.costo,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Costo unitario',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text('= ${formatearValor(subtotal)}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _seccion(ThemeData theme, String titulo) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(titulo, style: theme.textTheme.titleMedium),
      );

  Widget _fila(String etiqueta, String valor, {bool negrita = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: <Widget>[
          Expanded(child: Text(etiqueta)),
          Text(
            valor,
            style: TextStyle(
              fontWeight: negrita ? FontWeight.bold : FontWeight.normal,
              fontSize: negrita ? 16 : null,
            ),
          ),
        ],
      ),
    );
  }
}

/// Selector de productos para la compra.
class _SelectorProductos extends StatefulWidget {
  const _SelectorProductos({required this.productos});

  final List<Producto> productos;

  @override
  State<_SelectorProductos> createState() => _SelectorProductosState();
}

class _SelectorProductosState extends State<_SelectorProductos> {
  final TextEditingController _busqueda = TextEditingController();

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

  @override
  Widget build(BuildContext context) {
    final q = _busqueda.text.trim().toLowerCase();
    final lista = widget.productos.where((p) {
      if (q.isEmpty) return true;
      return p.nombre.toLowerCase().contains(q) ||
          p.codigo.toLowerCase().contains(q);
    }).toList(growable: false);

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
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
          Flexible(
            child: lista.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('Sin resultados.'),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: lista.length,
                    itemBuilder: (context, i) => ListTile(
                      title: Text(lista[i].nombre),
                      subtitle: Text('${lista[i].codigo} · Stock: ${lista[i].stock}'),
                      trailing: Text(formatearValor(lista[i].costo)),
                      onTap: () => Navigator.of(context).pop(lista[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

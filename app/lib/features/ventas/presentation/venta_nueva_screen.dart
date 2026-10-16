import 'package:flutter/material.dart';

import '../../../core/formato/fechas.dart';
import '../../auth/domain/usuario.dart';
import '../../catalogo/data/productos_repository.dart';
import '../../catalogo/domain/precio.dart';
import '../../catalogo/domain/producto.dart';
import '../../catalogo/presentation/escanear_codigo_screen.dart';
import '../../clientes/data/clientes_repository.dart';
import '../../clientes/domain/cliente.dart';
import '../../creditos/data/creditos_repository.dart';
import '../../creditos/domain/credito.dart';
import '../../empresas/data/empresas_repository.dart';
import '../../empresas/domain/parametros_empresa.dart';
import '../data/ventas_repository.dart';
import '../domain/totales.dart';
import '../domain/venta.dart';

/// Una línea del carrito de la venta: producto + cantidad.
class _Linea {
  _Linea(this.producto, this.cantidad);

  final Producto producto;
  int cantidad;
}

/// Pantalla de registro de una venta (spec 005, T020..T023).
///
/// Devuelve `true` al registrar para que el listado se recargue.
class VentaNuevaScreen extends StatefulWidget {
  const VentaNuevaScreen({
    super.key,
    required this.usuario,
    this.ventasRepository,
    this.productosRepository,
    this.clientesRepository,
    this.empresasRepository,
    this.creditosRepository,
  });

  final Usuario usuario;
  final VentasRepository? ventasRepository;
  final ProductosRepository? productosRepository;
  final ClientesRepository? clientesRepository;
  final EmpresasRepository? empresasRepository;
  final CreditosRepository? creditosRepository;

  @override
  State<VentaNuevaScreen> createState() => _VentaNuevaScreenState();
}

class _VentaNuevaScreenState extends State<VentaNuevaScreen> {
  late final VentasRepository _ventas =
      widget.ventasRepository ?? VentasRepository();
  late final ProductosRepository _productosRepo =
      widget.productosRepository ?? ProductosRepository();
  late final ClientesRepository _clientesRepo =
      widget.clientesRepository ?? ClientesRepository();
  late final EmpresasRepository _empresasRepo =
      widget.empresasRepository ?? EmpresasRepository();
  late final CreditosRepository _creditos =
      widget.creditosRepository ?? CreditosRepository();

  final List<_Linea> _lineas = <_Linea>[];
  final _costoEnvio = TextEditingController(text: '0');
  final _descuento = TextEditingController(text: '0');
  final _numeroCuotas = TextEditingController(text: '3');
  final _tasaInteres = TextEditingController(text: '0');
  Periodicidad _periodicidad = Periodicidad.mensual;
  DateTime? _fechaPrimerPago;

  ParametrosEmpresa _parametros = const ParametrosEmpresa();
  List<Producto> _productos = const <Producto>[];
  List<Cliente> _clientes = const <Cliente>[];
  TipoPrecio _tipoVenta = TipoPrecio.contado;
  TipoEntrega _tipoEntrega = TipoEntrega.presencial;
  MedioPago _medioPago = MedioPago.efectivo;
  String? _clienteId;
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
    _costoEnvio.dispose();
    _descuento.dispose();
    _numeroCuotas.dispose();
    _tasaInteres.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    try {
      final empresa = await _empresasRepo.obtener(_empresaId);
      final productos =
          await _productosRepo.listar(_empresaId, activo: true);
      final clientes = await _clientesRepo.listar(_empresaId);
      if (!mounted) return;
      setState(() {
        _parametros = empresa?.parametros ?? const ParametrosEmpresa();
        _costoEnvio.text = _parametros.costoEnvio.round().toString();
        _productos = productos;
        _clientes = clientes;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _cargando = false);
      _avisar('No se pudieron cargar los datos: $e');
    }
  }

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

  List<ItemVenta> _items() => <ItemVenta>[
        for (final l in _lineas)
          ItemVenta(
            productoId: l.producto.id,
            codigo: l.producto.codigo,
            nombre: l.producto.nombre,
            cantidad: l.cantidad,
            precioUnitario: l.producto.precio(_tipoVenta, _parametros),
            iva: l.producto.ivaEfectivo(_parametros),
          ),
      ];

  double _precioLinea(Producto p) => p.precio(_tipoVenta, _parametros);

  TotalesVenta get _totales {
    final items = _items();
    return calcularTotales(
      items: items,
      tipoEntrega: _tipoEntrega,
      costoEnvio: double.tryParse(_costoEnvio.text.trim()) ?? 0,
      descuento: double.tryParse(_descuento.text.trim()) ?? 0,
      impuestos: impuestosDeItems(items),
    );
  }

  Future<void> _agregarProducto() async {
    final producto = await showModalBottomSheet<Producto>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _SelectorProductos(productos: _productos, parametros: _parametros, tipoVenta: _tipoVenta),
    );
    if (producto == null) return;
    setState(() {
      final idx = _lineas.indexWhere((l) => l.producto.id == producto.id);
      if (idx >= 0) {
        _lineas[idx].cantidad += 1;
      } else {
        _lineas.add(_Linea(producto, 1));
      }
    });
  }

  /// Agrega un producto a partir de un código escaneado (barras o QR).
  Future<void> _escanear() async {
    String? leido;
    try {
      leido = await Navigator.of(context).push<String>(
        MaterialPageRoute<String>(
          builder: (_) => const EscanearCodigoScreen(),
        ),
      );
    } catch (e) {
      if (mounted) _avisar('No se pudo abrir el escáner: $e');
      return;
    }
    if (leido == null) return;

    final codigo = leido.trim();
    Producto? encontrado;
    for (final p in _productos) {
      if (p.codigoBarras == codigo || p.codigo == codigo) {
        encontrado = p;
        break;
      }
    }
    if (encontrado == null) {
      if (mounted) _avisar('No hay un producto con el código "$codigo".');
      return;
    }

    final producto = encontrado;
    setState(() {
      final idx = _lineas.indexWhere((l) => l.producto.id == producto.id);
      if (idx >= 0) {
        _lineas[idx].cantidad += 1;
      } else {
        _lineas.add(_Linea(producto, 1));
      }
    });
    if (mounted) _avisar('Agregado: ${producto.nombre}');
  }

  Future<void> _registrar() async {
    if (_lineas.isEmpty) return _avisar('Agrega al menos un producto.');
    final t = _totales;
    if (t.descuento > t.subtotal + t.envio) {
      return _avisar('El descuento no puede superar el subtotal + envío.');
    }
    if (_tipoVenta == TipoPrecio.credito &&
        (int.tryParse(_numeroCuotas.text.trim()) ?? 0) < 1) {
      return _avisar('Indica el número de cuotas del crédito.');
    }

    Cliente? cliente;
    if (_clienteId != null) {
      for (final c in _clientes) {
        if (c.id == _clienteId) {
          cliente = c;
          break;
        }
      }
    }

    final venta = Venta(
      id: '',
      empresaId: _empresaId,
      vendedorUid: widget.usuario.uid,
      vendedorNombre: widget.usuario.nombre,
      clienteId: cliente?.id,
      clienteNombre: cliente?.nombreCompleto ?? 'Consumidor final',
      clienteUid: cliente?.uid,
      items: _items(),
      tipoVenta: _tipoVenta,
      tipoEntrega: _tipoEntrega,
      medioPago: _medioPago,
      subtotal: t.subtotal,
      costoEnvio: t.envio,
      descuento: t.descuento,
      impuestos: t.impuestos,
      total: t.total,
    );

    setState(() => _guardando = true);
    final messenger = ScaffoldMessenger.of(context);
    String? avisoCredito;
    try {
      final ventaId = await _ventas.registrar(venta);
      if (_tipoVenta == TipoPrecio.credito) {
        try {
          await _creditos.crearDesdeVenta(
            ventaId,
            numeroCuotas: int.tryParse(_numeroCuotas.text.trim()) ?? 1,
            periodicidad: _periodicidad,
            tasaInteres: double.tryParse(_tasaInteres.text.trim()) ?? 0,
            fechaPrimerPago: _fechaPrimerPago,
          );
        } catch (e) {
          avisoCredito =
              'La venta quedó registrada, pero no se pudo crear el crédito: $e';
        }
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
      if (avisoCredito != null) {
        messenger.showSnackBar(SnackBar(content: Text(avisoCredito)));
      }
    } on StockInsuficienteVentaException catch (e) {
      if (mounted) _avisar(e.toString(), error: true);
    } catch (e) {
      if (mounted) _avisar('No se pudo registrar la venta: $e', error: true);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_cargando) {
      return Scaffold(
        appBar: AppBar(title: const Text('Nueva venta')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final t = _totales;

    return Scaffold(
      appBar: AppBar(title: const Text('Nueva venta')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          _seccion(theme, 'Cliente'),
          DropdownButtonFormField<String?>(
            initialValue: _clienteId,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Cliente',
              border: OutlineInputBorder(),
            ),
            items: <DropdownMenuItem<String?>>[
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('Consumidor final'),
              ),
              for (final c in _clientes)
                DropdownMenuItem<String?>(
                  value: c.id,
                  child: Text('${c.nombreCompleto} · ${c.cedula}'),
                ),
            ],
            onChanged: (String? v) => setState(() => _clienteId = v),
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
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _agregarProducto,
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar producto'),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _escanear,
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Escanear'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _seccion(theme, 'Tipo de venta'),
          SegmentedButton<TipoPrecio>(
            segments: const <ButtonSegment<TipoPrecio>>[
              ButtonSegment<TipoPrecio>(
                value: TipoPrecio.contado,
                label: Text('Contado'),
              ),
              ButtonSegment<TipoPrecio>(
                value: TipoPrecio.credito,
                label: Text('Crédito'),
              ),
            ],
            selected: <TipoPrecio>{_tipoVenta},
            onSelectionChanged: (Set<TipoPrecio> s) =>
                setState(() => _tipoVenta = s.first),
          ),
          if (_tipoVenta == TipoPrecio.credito) ...<Widget>[
            const SizedBox(height: 16),
            _seccion(theme, 'Plan de crédito'),
            Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _numeroCuotas,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Número de cuotas',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _tasaInteres,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Interés %',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<Periodicidad>(
              initialValue: _periodicidad,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Periodicidad',
                border: OutlineInputBorder(),
              ),
              items: <DropdownMenuItem<Periodicidad>>[
                for (final p in Periodicidad.values)
                  DropdownMenuItem<Periodicidad>(value: p, child: Text(p.nombre)),
              ],
              onChanged: (Periodicidad? v) =>
                  setState(() => _periodicidad = v ?? Periodicidad.mensual),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Primer pago'),
              subtitle: Text(_fechaPrimerPago == null
                  ? 'Por defecto: dentro de un periodo'
                  : formatearFecha(_fechaPrimerPago)),
              trailing: const Icon(Icons.calendar_today_outlined),
              onTap: _elegirFechaPrimerPago,
            ),
            _resumenPlanCredito(theme),
          ],
          const SizedBox(height: 16),
          _seccion(theme, 'Entrega y pago'),
          DropdownButtonFormField<TipoEntrega>(
            initialValue: _tipoEntrega,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Tipo de entrega',
              border: OutlineInputBorder(),
            ),
            items: <DropdownMenuItem<TipoEntrega>>[
              for (final e in TipoEntrega.values)
                DropdownMenuItem<TipoEntrega>(value: e, child: Text(e.nombre)),
            ],
            onChanged: (TipoEntrega? v) =>
                setState(() => _tipoEntrega = v ?? TipoEntrega.presencial),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<MedioPago>(
            initialValue: _medioPago,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Medio de pago',
              border: OutlineInputBorder(),
            ),
            items: <DropdownMenuItem<MedioPago>>[
              for (final m in MedioPago.values)
                DropdownMenuItem<MedioPago>(value: m, child: Text(m.nombre)),
            ],
            onChanged: (MedioPago? v) =>
                setState(() => _medioPago = v ?? MedioPago.efectivo),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _costoEnvio,
            enabled: _tipoEntrega.cobraEnvio,
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Costo de envío',
              helperText: _tipoEntrega.cobraEnvio
                  ? 'Según la entrega'
                  : 'No aplica (0) para ${_tipoEntrega.nombre.toLowerCase()}',
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descuento,
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Descuento',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Los impuestos se calculan por producto, según su IVA.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: <Widget>[
                  _fila('Subtotal', formatearValor(t.subtotal)),
                  _fila('Envío', formatearValor(t.envio)),
                  if (t.descuento > 0) _fila('Descuento', '-${formatearValor(t.descuento)}'),
                  if (t.impuestos > 0) _fila('Impuestos', formatearValor(t.impuestos)),
                  const Divider(),
                  _fila('Total', formatearValor(t.total), negrita: true),
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
            label: Text(_guardando ? 'Registrando…' : 'Registrar venta'),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _lineaWidget(_Linea linea) {
    final theme = Theme.of(context);
    final precio = _precioLinea(linea.producto);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(linea.producto.nombre, maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(
                    '${formatearValor(precio)} c/u',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Quitar uno',
              onPressed: () => setState(() {
                if (linea.cantidad > 1) {
                  linea.cantidad -= 1;
                } else {
                  _lineas.remove(linea);
                }
              }),
              icon: const Icon(Icons.remove_circle_outline),
            ),
            Text('${linea.cantidad}', style: theme.textTheme.titleMedium),
            IconButton(
              tooltip: 'Agregar uno',
              onPressed: () => setState(() => linea.cantidad += 1),
              icon: const Icon(Icons.add_circle_outline),
            ),
            SizedBox(
              width: 84,
              child: Text(
                formatearValor(linea.cantidad * precio),
                textAlign: TextAlign.right,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Abre el selector de fecha para el primer pago del crédito.
  Future<void> _elegirFechaPrimerPago() async {
    final hoy = DateTime.now();
    final elegida = await showDatePicker(
      context: context,
      initialDate:
          _fechaPrimerPago ?? DateTime(hoy.year, hoy.month + 1, hoy.day),
      firstDate: hoy,
      lastDate: DateTime(2100),
    );
    if (elegida != null) setState(() => _fechaPrimerPago = elegida);
  }

  /// Resumen del plan de crédito (total con interés y cuota aproximada).
  Widget _resumenPlanCredito(ThemeData theme) {
    final t = _totales;
    final n = int.tryParse(_numeroCuotas.text.trim()) ?? 0;
    final tasa = double.tryParse(_tasaInteres.text.trim()) ?? 0;
    final conInteres = t.total * (1 + (tasa < 0 ? 0 : tasa) / 100);
    final cuota = n > 0 ? conInteres / n : 0;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        n > 0
            ? 'Total con interés ${formatearValor(conInteres)} · $n cuota(s) de ~${formatearValor(cuota)}'
            : 'Define el número de cuotas.',
        style: theme.textTheme.bodySmall,
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

/// Selector de productos (búsqueda + lista) para agregar a la venta.
class _SelectorProductos extends StatefulWidget {
  const _SelectorProductos({
    required this.productos,
    required this.parametros,
    required this.tipoVenta,
  });

  final List<Producto> productos;
  final ParametrosEmpresa parametros;
  final TipoPrecio tipoVenta;

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
                    itemBuilder: (context, i) {
                      final p = lista[i];
                      return ListTile(
                        title: Text(p.nombre),
                        subtitle: Text('${p.codigo} · Stock: ${p.stock}'),
                        trailing: Text(
                          formatearValor(p.precio(widget.tipoVenta, widget.parametros)),
                        ),
                        enabled: p.stock > 0,
                        onTap: () => Navigator.of(context).pop(p),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

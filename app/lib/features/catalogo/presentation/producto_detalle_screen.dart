import 'package:flutter/material.dart';

import '../../../core/formato/fechas.dart';
import '../../auth/domain/permisos.dart';
import '../../auth/domain/usuario.dart';
import '../../empresas/domain/parametros_empresa.dart';
import '../../empresas/presentation/widgets/tarjeta_datos.dart';
import '../data/productos_repository.dart';
import '../domain/precio.dart';
import '../domain/producto.dart';
import 'producto_form_screen.dart';
import 'widgets/imagen_producto.dart';

/// Detalle de un producto con sus precios (contado/crédito), stock y acciones
/// (editar, activar/desactivar, ajustar stock). Spec 003, T021.
class ProductoDetalleScreen extends StatefulWidget {
  const ProductoDetalleScreen({
    super.key,
    required this.productoId,
    required this.usuario,
    this.parametros = const ParametrosEmpresa(),
    this.productosRepository,
  });

  final String productoId;
  final Usuario usuario;
  final ParametrosEmpresa parametros;
  final ProductosRepository? productosRepository;

  @override
  State<ProductoDetalleScreen> createState() => _ProductoDetalleScreenState();
}

class _ProductoDetalleScreenState extends State<ProductoDetalleScreen> {
  late final ProductosRepository _repo =
      widget.productosRepository ?? ProductosRepository();

  Producto? _producto;
  bool _cargando = true;
  String? _error;

  bool get _puedeEditar => widget.usuario.puede(Permiso.catalogoEditar);

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final producto = await _repo.obtener(widget.productoId);
      if (!mounted) return;
      setState(() {
        _producto = producto;
        _cargando = false;
        if (producto == null) _error = 'El producto ya no existe.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _cargando = false;
      });
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

  Future<void> _editar() async {
    final producto = _producto;
    if (producto == null) return;
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => ProductoFormScreen(
          usuario: widget.usuario,
          producto: producto,
        ),
      ),
    );
    await _cargar();
  }

  Future<void> _cambiarActivo(bool activo) async {
    final producto = _producto;
    if (producto == null) return;
    try {
      await _repo.activar(producto.id, activo, empresaId: producto.empresaId);
      await _cargar();
      if (mounted) _avisar(activo ? 'Producto activado.' : 'Producto desactivado.');
    } catch (e) {
      if (mounted) _avisar('No se pudo cambiar: $e', error: true);
    }
  }

  Future<void> _ajustarStock() async {
    final producto = _producto;
    if (producto == null) return;

    final cantidad = TextEditingController();
    var entrada = true;

    final aplicar = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Ajustar stock'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              SegmentedButton<bool>(
                segments: const <ButtonSegment<bool>>[
                  ButtonSegment<bool>(
                    value: true,
                    label: Text('Entrada'),
                    icon: Icon(Icons.add),
                  ),
                  ButtonSegment<bool>(
                    value: false,
                    label: Text('Salida'),
                    icon: Icon(Icons.remove),
                  ),
                ],
                selected: <bool>{entrada},
                onSelectionChanged: (Set<bool> s) =>
                    setDialogState(() => entrada = s.first),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: cantidad,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Cantidad',
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
              child: const Text('Aplicar'),
            ),
          ],
        ),
      ),
    );

    if (aplicar != true) return;
    final n = int.tryParse(cantidad.text.trim());
    if (n == null || n <= 0) {
      _avisar('Ingresa una cantidad mayor que cero.', error: true);
      return;
    }

    try {
      await _repo.actualizarStock(producto.id, entrada ? n : -n,
          motivo: entrada ? 'entrada' : 'salida');
      await _cargar();
      if (mounted) _avisar('Stock actualizado.');
    } on StockInsuficienteException catch (e) {
      if (mounted) _avisar(e.toString(), error: true);
    } catch (e) {
      if (mounted) _avisar('No se pudo ajustar el stock: $e', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final producto = _producto;
    return Scaffold(
      appBar: AppBar(
        title: Text(producto?.nombre ?? 'Producto'),
        actions: <Widget>[
          if (producto != null && _puedeEditar)
            IconButton(
              tooltip: 'Editar',
              icon: const Icon(Icons.edit_outlined),
              onPressed: _editar,
            ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(_error!, textAlign: TextAlign.center),
                  ),
                )
              : _cuerpo(producto!),
    );
  }

  Widget _cuerpo(Producto producto) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final p = widget.parametros;

    final precioContado = producto.precio(TipoPrecio.contado, p);
    final precioCredito = producto.precio(TipoPrecio.credito, p);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AspectRatio(
            aspectRatio: 1.4,
            child: ImagenProducto(producto: producto, ajuste: BoxFit.cover),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: <Widget>[
            Expanded(
              child: Text(producto.nombre, style: theme.textTheme.titleLarge),
            ),
            Switch(
              value: producto.activo,
              onChanged: _puedeEditar ? _cambiarActivo : null,
            ),
          ],
        ),
        Text('Código: ${producto.codigo}',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: scheme.onSurfaceVariant)),
        if (producto.codigoBarras.trim().isNotEmpty)
          Text('Código de barras: ${producto.codigoBarras}',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: scheme.onSurfaceVariant)),
        if (producto.descripcion.trim().isNotEmpty) ...<Widget>[
          const SizedBox(height: 8),
          Text(producto.descripcion),
        ],
        const SizedBox(height: 12),
        TarjetaDatos(
          titulo: 'Precios',
          icono: Icons.sell_outlined,
          filas: <FilaDato>[
            FilaDato(
              'Costo',
              formatearValor(producto.costo),
            ),
            FilaDato(
              'IVA',
              '${producto.ivaEfectivo(p).round()}%',
            ),
            FilaDato(
              'Contado (${producto.margenEfectivo(TipoPrecio.contado, p).round()}%)',
              formatearValor(precioContado),
            ),
            FilaDato(
              'Crédito (${producto.margenEfectivo(TipoPrecio.credito, p).round()}%)',
              formatearValor(precioCredito),
            ),
            FilaDato(
              'Envío',
              formatearValor(producto.costoEnvioEfectivo(p)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TarjetaDatos(
          titulo: 'Stock',
          icono: Icons.warehouse_outlined,
          filas: <FilaDato>[
            FilaDato('Disponible', '${producto.stock}'),
            FilaDato('Mínimo', '${producto.stockMinimo}'),
            FilaDato(
              'Estado',
              producto.stockBajo ? 'Stock bajo' : 'Suficiente',
            ),
          ],
          acciones: <Widget>[
            if (_puedeEditar)
              TextButton.icon(
                onPressed: _ajustarStock,
                icon: const Icon(Icons.add_box_outlined, size: 18),
                label: const Text('Ajustar stock'),
              ),
          ],
        ),
        if (!producto.medidas.vacio || producto.color.trim().isNotEmpty) ...<Widget>[
          const SizedBox(height: 12),
          TarjetaDatos(
            titulo: 'Medidas y color',
            icono: Icons.straighten_outlined,
            filas: <FilaDato>[
              if (producto.medidas.material.isNotEmpty)
                FilaDato('Material', producto.medidas.material),
              if (producto.medidas.dimensiones.isNotEmpty)
                FilaDato('Dimensiones', producto.medidas.dimensiones),
              if (producto.medidas.peso.isNotEmpty)
                FilaDato('Peso', producto.medidas.peso),
              if (producto.color.trim().isNotEmpty)
                FilaDato('Color', producto.color),
            ],
          ),
        ],
        const SizedBox(height: 12),
        TarjetaDatos(
          titulo: 'Fechas',
          icono: Icons.schedule_outlined,
          filas: <FilaDato>[
            FilaDato('Creado', formatearFecha(producto.fechaCreacion)),
            FilaDato('Actualizado', formatearFecha(producto.fechaActualizacion)),
          ],
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

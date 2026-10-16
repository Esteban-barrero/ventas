import 'package:flutter/material.dart';

import '../../../core/formato/fechas.dart';
import '../../auth/domain/permisos.dart';
import '../../auth/domain/usuario.dart';
import '../../empresas/presentation/widgets/tarjeta_datos.dart';
import '../data/ventas_repository.dart';
import '../domain/venta.dart';

/// Detalle de una venta con su factura y la opción de anular (spec 005, T025).
class VentaDetalleScreen extends StatefulWidget {
  const VentaDetalleScreen({
    super.key,
    required this.ventaId,
    required this.usuario,
    this.ventasRepository,
  });

  final String ventaId;
  final Usuario usuario;
  final VentasRepository? ventasRepository;

  @override
  State<VentaDetalleScreen> createState() => _VentaDetalleScreenState();
}

class _VentaDetalleScreenState extends State<VentaDetalleScreen> {
  late final VentasRepository _repo =
      widget.ventasRepository ?? VentasRepository();

  Venta? _venta;
  bool _cargando = true;
  String? _error;

  bool get _puedeAnular => widget.usuario.puede(Permiso.ventasAnular);

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
      final venta = await _repo.obtener(widget.ventaId);
      if (!mounted) return;
      setState(() {
        _venta = venta;
        _cargando = false;
        if (venta == null) _error = 'La venta ya no existe.';
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

  Future<void> _anular() async {
    final venta = _venta;
    if (venta == null) return;

    final motivo = TextEditingController();
    final confirmar = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Anular venta'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text('Se revertirá el stock de ${venta.numeroFactura}.'),
            const SizedBox(height: 12),
            TextField(
              controller: motivo,
              decoration: const InputDecoration(
                labelText: 'Motivo',
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
            child: const Text('Anular'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;
    if (motivo.text.trim().isEmpty) {
      _avisar('Indica el motivo de la anulación.', error: true);
      return;
    }

    try {
      await _repo.anular(venta.id, motivo.text.trim(), empresaId: venta.empresaId);
      await _cargar();
      if (mounted) _avisar('Venta anulada.');
    } catch (e) {
      if (mounted) _avisar('No se pudo anular: $e', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final venta = _venta;
    return Scaffold(
      appBar: AppBar(
        title: Text(venta == null ? 'Venta' : 'Factura ${venta.numeroFactura}'),
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
              : _cuerpo(venta!),
    );
  }

  Widget _cuerpo(Venta venta) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        if (venta.anulada)
          Card(
            color: scheme.errorContainer,
            child: ListTile(
              leading: Icon(Icons.cancel_outlined, color: scheme.onErrorContainer),
              title: Text('Venta anulada',
                  style: TextStyle(color: scheme.onErrorContainer)),
              subtitle: Text(venta.motivoAnulacion.isEmpty
                  ? 'Sin motivo'
                  : venta.motivoAnulacion),
            ),
          ),
        TarjetaDatos(
          titulo: 'Factura',
          icono: Icons.receipt_long_outlined,
          filas: <FilaDato>[
            FilaDato('Número', venta.numeroFactura),
            FilaDato('Fecha', formatearFecha(venta.fecha)),
            FilaDato('Estado', venta.estado.nombre),
            FilaDato('Vendedor', venta.vendedorNombre.isEmpty ? '—' : venta.vendedorNombre),
            FilaDato('Cliente', venta.clienteNombre),
          ],
        ),
        const SizedBox(height: 12),
        TarjetaDatos(
          titulo: 'Productos',
          icono: Icons.inventory_2_outlined,
          filas: <FilaDato>[
            for (final it in venta.items)
              FilaDato(
                '${it.cantidad}× ${it.nombre}',
                formatearValor(it.subtotal),
              ),
          ],
        ),
        const SizedBox(height: 12),
        TarjetaDatos(
          titulo: 'Totales',
          icono: Icons.summarize_outlined,
          filas: <FilaDato>[
            FilaDato('Subtotal', formatearValor(venta.subtotal)),
            FilaDato('Envío', formatearValor(venta.costoEnvio)),
            if (venta.descuento > 0)
              FilaDato('Descuento', '-${formatearValor(venta.descuento)}'),
            if (venta.impuestos > 0)
              FilaDato('Impuestos', formatearValor(venta.impuestos)),
            FilaDato('Total', formatearValor(venta.total)),
          ],
        ),
        const SizedBox(height: 12),
        TarjetaDatos(
          titulo: 'Pago y entrega',
          icono: Icons.local_shipping_outlined,
          filas: <FilaDato>[
            FilaDato('Tipo de venta', venta.tipoVenta.nombre),
            FilaDato('Tipo de entrega', venta.tipoEntrega.nombre),
            FilaDato('Medio de pago', venta.medioPago.nombre),
            if (venta.empresaEnvio.isNotEmpty)
              FilaDato('Empresa de envío', venta.empresaEnvio),
          ],
        ),
        const SizedBox(height: 24),
        if (_puedeAnular && !venta.anulada)
          OutlinedButton.icon(
            onPressed: _anular,
            icon: const Icon(Icons.cancel_outlined),
            label: const Text('Anular venta'),
            style: OutlinedButton.styleFrom(foregroundColor: scheme.error),
          ),
        const SizedBox(height: 32),
      ],
    );
  }
}

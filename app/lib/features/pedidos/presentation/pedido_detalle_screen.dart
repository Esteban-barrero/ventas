import 'package:flutter/material.dart';

import '../../../core/formato/fechas.dart';
import '../../auth/domain/permisos.dart';
import '../../auth/domain/usuario.dart';
import '../../ventas/data/ventas_repository.dart';
import '../../ventas/domain/venta.dart';
import '../data/pedidos_repository.dart';
import '../domain/pedido.dart';

/// Detalle de un pedido (spec 010). Si el usuario puede gestionar ventas y el
/// pedido está pendiente, permite **aprobarlo** (lo convierte en venta → pasa a
/// Entregas) o **cancelarlo**.
class PedidoDetalleScreen extends StatefulWidget {
  const PedidoDetalleScreen({
    super.key,
    required this.pedido,
    required this.usuario,
    this.pedidosRepository,
  });

  final Pedido pedido;
  final Usuario usuario;
  final PedidosRepository? pedidosRepository;

  @override
  State<PedidoDetalleScreen> createState() => _PedidoDetalleScreenState();
}

class _PedidoDetalleScreenState extends State<PedidoDetalleScreen> {
  late final PedidosRepository _repo =
      widget.pedidosRepository ?? PedidosRepository();
  late final VentasRepository _ventas = VentasRepository();

  /// Estado del **envío** (spec 011), si el pedido ya se convirtió en venta.
  EstadoEnvio? _envio;

  bool _procesando = false;

  @override
  void initState() {
    super.initState();
    _cargarEnvio();
  }

  Future<void> _cargarEnvio() async {
    if (widget.pedido.ventaId.isEmpty) return;
    try {
      final venta = await _ventas.obtener(widget.pedido.ventaId);
      if (!mounted || venta == null) return;
      setState(() => _envio = venta.estadoEnvioActual);
    } catch (_) {
      // Si no se puede leer la venta, se omite el estado del envío.
    }
  }

  bool get _puedeGestionar => widget.usuario.puede(Permiso.ventasVer);

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

  Future<void> _aprobar() async {
    setState(() => _procesando = true);
    try {
      await _repo.aprobar(
        widget.pedido,
        usuarioUid: widget.usuario.uid,
        usuarioNombre: widget.usuario.nombre,
      );
      if (!mounted) return;
      _avisar('Pedido aprobado. Se generó la venta y quedó en Entregas.');
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) _avisar('No se pudo aprobar: $e', error: true);
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  Future<void> _cancelar() async {
    final motivo = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar pedido'),
        content: TextField(
          controller: motivo,
          decoration: const InputDecoration(
            labelText: 'Motivo',
            border: OutlineInputBorder(),
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Volver'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Cancelar pedido'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _procesando = true);
    try {
      await _repo.cambiarEstado(
        widget.pedido.id,
        EstadoPedido.cancelado,
        empresaId: widget.pedido.empresaId,
        motivo: motivo.text.trim(),
        usuarioUid: widget.usuario.uid,
      );
      if (!mounted) return;
      _avisar('Pedido cancelado.');
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) _avisar('No se pudo cancelar: $e', error: true);
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.pedido;
    final theme = Theme.of(context);
    final pendiente = p.estado == EstadoPedido.pendiente;

    return Scaffold(
      appBar: AppBar(title: Text(p.numero.isEmpty ? 'Pedido' : p.numero)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: <Widget>[
                  _fila('Estado', p.estado.nombre, negrita: true),
                  if (_envio != null) _fila('Envío', _envio!.nombre),
                  _fila('Fecha', formatearFecha(p.fechaCreacion)),
                  _fila('Entrega', p.tipoEntrega.nombre),
                  _fila('Pago', p.tipoPago.nombre),
                  _fila('Total', formatearValor(p.total), negrita: true),
                  if (p.ventaId.isNotEmpty) _fila('Venta', p.ventaId),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text('Cliente', style: theme.textTheme.titleMedium),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _fila('Nombre', p.clienteNombre),
                  _fila('Cédula', p.cedula),
                  _fila('Teléfono', p.telefono),
                  const SizedBox(height: 6),
                  Text(p.direccion.resumen.isEmpty
                      ? 'Sin dirección'
                      : p.direccion.resumen),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text('Productos', style: theme.textTheme.titleMedium),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: <Widget>[
                  for (final ItemPedido it in p.items)
                    _fila('${it.cantidad} × ${it.nombre}',
                        formatearValor(it.subtotal)),
                ],
              ),
            ),
          ),
          if (p.observaciones.isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            Text('Observaciones: ${p.observaciones}',
                style: theme.textTheme.bodySmall),
          ],
          const SizedBox(height: 24),
          if (_procesando)
            const Center(child: CircularProgressIndicator())
          else if (pendiente && _puedeGestionar)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                FilledButton.icon(
                  onPressed: _aprobar,
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Aprobar pedido'),
                ),
                OutlinedButton.icon(
                  onPressed: _cancelar,
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Cancelar'),
                ),
              ],
            )
          else if (pendiente)
            Text('Pendiente de aprobación por la empresa.',
                style: theme.textTheme.bodySmall),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _fila(String etiqueta, String valor, {bool negrita = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: <Widget>[
          Expanded(child: Text(etiqueta)),
          Flexible(
            child: Text(
              valor.isEmpty ? '—' : valor,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: negrita ? FontWeight.bold : FontWeight.normal,
                fontSize: negrita ? 16 : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

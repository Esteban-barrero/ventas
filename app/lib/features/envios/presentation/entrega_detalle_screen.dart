import 'package:flutter/material.dart';

import '../../../core/formato/fechas.dart';
import '../../auth/domain/usuario.dart';
import '../../clientes/data/mapas.dart';
import '../../clientes/domain/cliente.dart';
import '../../tesoreria/data/tesoreria_repository.dart';
import '../../tesoreria/domain/movimiento_dinero.dart';
import '../../ventas/domain/venta.dart';
import '../data/entregas_repository.dart';

/// Detalle de una entrega: pedido, datos del cliente, dirección y acciones
/// (en reparto / entregado / novedad). Spec 011.
class EntregaDetalleScreen extends StatefulWidget {
  const EntregaDetalleScreen({
    super.key,
    required this.venta,
    required this.usuario,
    this.cliente,
    this.entregasRepository,
    this.tesoreriaRepository,
  });

  final Venta venta;
  final Usuario usuario;
  final Cliente? cliente;
  final EntregasRepository? entregasRepository;
  final TesoreriaRepository? tesoreriaRepository;

  @override
  State<EntregaDetalleScreen> createState() => _EntregaDetalleScreenState();
}

class _EntregaDetalleScreenState extends State<EntregaDetalleScreen> {
  late final EntregasRepository _entregas =
      widget.entregasRepository ?? EntregasRepository();
  late final TesoreriaRepository _tesoreria =
      widget.tesoreriaRepository ?? TesoreriaRepository();
  final Mapas _mapas = const Mapas();

  bool _guardando = false;

  String get _empresaId => widget.usuario.empresaId ?? '';

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

  /// Marca la venta "en reparto" con este domiciliario (RF-04, RF-09).
  Future<void> _enReparto() async {
    setState(() => _guardando = true);
    try {
      await _entregas.marcarEstado(
        widget.venta.id,
        EstadoEnvio.enReparto,
        empresaId: _empresaId,
        repartidorUid: widget.usuario.uid,
        repartidorNombre: widget.usuario.nombre,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) _avisar('No se pudo actualizar: $e', error: true);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  /// Marca la venta como **entregada** y, si es de contado, pasa el dinero a
  /// manos del domiciliario (spec 016, RN-04).
  Future<void> _entregado() async {
    setState(() => _guardando = true);
    try {
      await _entregas.marcarEstado(
        widget.venta.id,
        EstadoEnvio.entregado,
        empresaId: _empresaId,
        repartidorUid: widget.usuario.uid,
        repartidorNombre: widget.usuario.nombre,
      );
      if (!widget.venta.esCredito && widget.venta.total > 0) {
        try {
          await _tesoreria.trasladar(
            empresaId: _empresaId,
            monto: widget.venta.total,
            origen: UbicacionDinero.contraEntrega,
            destino: UbicacionDinero.vendedorEfectivo,
            usuarioUid: widget.usuario.uid,
            usuarioNombre: widget.usuario.nombre,
            responsableUid: widget.usuario.uid,
            responsableNombre: widget.usuario.nombre,
            descripcion: 'Entrega ${widget.venta.numeroFactura}',
            referenciaId: widget.venta.id,
          );
        } catch (_) {
          // El estado queda entregado aunque falle el traslado del dinero.
        }
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) _avisar('No se pudo entregar: $e', error: true);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  /// Marca una **novedad** (no entregado).
  Future<void> _novedad() async {
    final motivo = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reportar novedad'),
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
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Reportar'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _guardando = true);
    try {
      await _entregas.marcarEstado(
        widget.venta.id,
        EstadoEnvio.novedad,
        empresaId: _empresaId,
        repartidorUid: widget.usuario.uid,
        repartidorNombre: widget.usuario.nombre,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) _avisar('No se pudo reportar: $e', error: true);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.venta;
    final tema = Theme.of(context);
    final cliente = widget.cliente;

    return Scaffold(
      appBar: AppBar(title: Text(v.numeroFactura.isEmpty ? 'Entrega' : v.numeroFactura)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: <Widget>[
                  _fila('Estado', v.estadoEnvioActual.nombre, negrita: true),
                  _fila('Fecha', formatearFecha(v.fecha)),
                  _fila('Entrega', v.tipoEntrega.nombre),
                  _fila('Pago', v.esCredito ? 'Crédito' : 'Contado · ${v.medioPago.nombre}'),
                  _fila('Total', formatearValor(v.total), negrita: true),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text('Cliente', style: tema.textTheme.titleMedium),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _fila('Nombre', v.clienteNombre),
                  if (cliente != null) ...<Widget>[
                    _fila('Cédula', cliente.cedula),
                    _fila('Teléfono', cliente.telefono),
                    const SizedBox(height: 8),
                    Text(cliente.direccion.resumen.isEmpty
                        ? 'Sin dirección registrada'
                        : cliente.direccion.resumen),
                    const SizedBox(height: 8),
                    if (cliente.tieneUbicacion)
                      Wrap(
                        spacing: 8,
                        children: <Widget>[
                          OutlinedButton.icon(
                            onPressed: () => _mapas.googleMaps(
                              cliente.ubicacionGPS!.latitud,
                              cliente.ubicacionGPS!.longitud,
                            ),
                            icon: const Icon(Icons.map_outlined),
                            label: const Text('Google Maps'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => _mapas.waze(
                              cliente.ubicacionGPS!.latitud,
                              cliente.ubicacionGPS!.longitud,
                            ),
                            icon: const Icon(Icons.navigation_outlined),
                            label: const Text('Waze'),
                          ),
                        ],
                      )
                    else
                      const Text('El cliente no tiene ubicación GPS registrada.'),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text('Productos', style: tema.textTheme.titleMedium),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: <Widget>[
                  for (final ItemVenta it in v.items)
                    _fila('${it.cantidad} × ${it.nombre}',
                        formatearValor(it.subtotal)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (_guardando)
            const Center(child: CircularProgressIndicator())
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                FilledButton.icon(
                  onPressed: _enReparto,
                  icon: const Icon(Icons.local_shipping_outlined),
                  label: const Text('En reparto'),
                ),
                FilledButton.icon(
                  onPressed: _entregado,
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Entregado'),
                ),
                OutlinedButton.icon(
                  onPressed: _novedad,
                  icon: const Icon(Icons.report_gmailerrorred_outlined),
                  label: const Text('Novedad'),
                ),
              ],
            ),
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

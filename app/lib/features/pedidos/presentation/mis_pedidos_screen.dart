import 'package:flutter/material.dart';

import '../../../core/formato/fechas.dart';
import '../../auth/domain/usuario.dart';
import '../../ventas/data/ventas_repository.dart';
import '../../ventas/domain/venta.dart';
import '../data/pedidos_repository.dart';
import '../domain/pedido.dart';
import 'pedido_detalle_screen.dart';

/// Historial de pedidos del cliente (spec 010, RF-08). Muestra el estado del
/// pedido y, si ya se convirtió en venta, el avance del **envío** (spec 011).
class MisPedidosScreen extends StatefulWidget {
  const MisPedidosScreen({
    super.key,
    required this.usuario,
    this.pedidosRepository,
    this.ventasRepository,
  });

  final Usuario usuario;
  final PedidosRepository? pedidosRepository;
  final VentasRepository? ventasRepository;

  @override
  State<MisPedidosScreen> createState() => _MisPedidosScreenState();
}

class _MisPedidosScreenState extends State<MisPedidosScreen> {
  late final PedidosRepository _repo =
      widget.pedidosRepository ?? PedidosRepository();
  late final VentasRepository _ventas =
      widget.ventasRepository ?? VentasRepository();

  /// Cachea la venta (envío) de cada pedido para no releerla en cada rebuild.
  final Map<String, Future<Venta?>> _envios = <String, Future<Venta?>>{};

  Future<Venta?> _envioDe(String ventaId) =>
      _envios.putIfAbsent(ventaId, () => _ventas.obtener(ventaId));

  @override
  Widget build(BuildContext context) {
    final empresaId = widget.usuario.empresaId ?? '';
    return Scaffold(
      appBar: AppBar(title: const Text('Mis pedidos')),
      body: StreamBuilder<List<Pedido>>(
        stream: _repo.escucharMisPedidos(empresaId, widget.usuario.uid),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final pedidos = snap.data ?? const <Pedido>[];
          if (pedidos.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Todavía no has hecho pedidos.'),
              ),
            );
          }
          return ListView.separated(
            itemCount: pedidos.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) => _tile(pedidos[i]),
          );
        },
      ),
    );
  }

  Widget _tile(Pedido p) {
    return ListTile(
      title: Text('${p.numero} · ${formatearValor(p.total)}'),
      subtitle: _subtitulo(p),
      trailing: Text(p.estado.nombre),
      onTap: () => Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => PedidoDetalleScreen(
            pedido: p,
            usuario: widget.usuario,
            pedidosRepository: _repo,
          ),
        ),
      ),
    );
  }

  Widget _subtitulo(Pedido p) {
    final base = '${formatearFecha(p.fechaCreacion)} · ${p.tipoEntrega.nombre}';
    if (p.ventaId.isEmpty) return Text(base);
    return FutureBuilder<Venta?>(
      future: _envioDe(p.ventaId),
      builder: (context, snap) {
        final envio = snap.data?.estadoEnvioActual.nombre;
        return Text(envio == null ? base : '$base · Envío: $envio');
      },
    );
  }
}

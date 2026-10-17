import 'package:flutter/material.dart';

import '../../../core/formato/fechas.dart';
import '../../auth/domain/usuario.dart';
import '../data/pedidos_repository.dart';
import '../domain/pedido.dart';
import 'pedido_detalle_screen.dart';

/// Historial de pedidos del cliente (spec 010, RF-08).
class MisPedidosScreen extends StatelessWidget {
  const MisPedidosScreen({
    super.key,
    required this.usuario,
    this.pedidosRepository,
  });

  final Usuario usuario;
  final PedidosRepository? pedidosRepository;

  @override
  Widget build(BuildContext context) {
    final repo = pedidosRepository ?? PedidosRepository();
    final empresaId = usuario.empresaId ?? '';
    return Scaffold(
      appBar: AppBar(title: const Text('Mis pedidos')),
      body: StreamBuilder<List<Pedido>>(
        stream: repo.escucharMisPedidos(empresaId, usuario.uid),
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
            itemBuilder: (context, i) {
              final p = pedidos[i];
              return ListTile(
                title: Text('${p.numero} · ${formatearValor(p.total)}'),
                subtitle: Text(
                  '${formatearFecha(p.fechaCreacion)} · ${p.tipoEntrega.nombre}',
                ),
                trailing: Text(p.estado.nombre),
                onTap: () => Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) => PedidoDetalleScreen(
                      pedido: p,
                      usuario: usuario,
                      pedidosRepository: repo,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

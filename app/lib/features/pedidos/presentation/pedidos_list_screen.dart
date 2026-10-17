import 'package:flutter/material.dart';

import '../../../core/formato/fechas.dart';
import '../../auth/domain/usuario.dart';
import '../data/pedidos_repository.dart';
import '../domain/pedido.dart';
import 'pedido_detalle_screen.dart';

/// Lista de **pedidos** de la empresa (spec 010). El responsable los revisa y
/// los aprueba (pasan a Entregas) o los cancela.
class PedidosListScreen extends StatefulWidget {
  const PedidosListScreen({
    super.key,
    required this.usuario,
    this.pedidosRepository,
  });

  final Usuario usuario;
  final PedidosRepository? pedidosRepository;

  @override
  State<PedidosListScreen> createState() => _PedidosListScreenState();
}

class _PedidosListScreenState extends State<PedidosListScreen> {
  late final PedidosRepository _repo =
      widget.pedidosRepository ?? PedidosRepository();

  EstadoPedido? _filtro;

  String get _empresaId => widget.usuario.empresaId ?? '';

  @override
  Widget build(BuildContext context) {
    if (_empresaId.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Pedidos')),
        body: const Center(child: Text('No perteneces a ninguna empresa.')),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Pedidos')),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Wrap(
              spacing: 8,
              children: <Widget>[
                FilterChip(
                  label: const Text('Pendientes'),
                  selected: _filtro == EstadoPedido.pendiente,
                  onSelected: (_) => setState(() => _filtro =
                      _filtro == EstadoPedido.pendiente
                          ? null
                          : EstadoPedido.pendiente),
                ),
                FilterChip(
                  label: const Text('Aprobados'),
                  selected: _filtro == EstadoPedido.confirmado,
                  onSelected: (_) => setState(() => _filtro =
                      _filtro == EstadoPedido.confirmado
                          ? null
                          : EstadoPedido.confirmado),
                ),
                FilterChip(
                  label: const Text('Cancelados'),
                  selected: _filtro == EstadoPedido.cancelado,
                  onSelected: (_) => setState(() => _filtro =
                      _filtro == EstadoPedido.cancelado
                          ? null
                          : EstadoPedido.cancelado),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Pedido>>(
              stream: _repo.escuchar(_empresaId),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final todos = snap.data ?? const <Pedido>[];
                final visibles = _filtro == null
                    ? todos
                    : todos
                        .where((Pedido p) => p.estado == _filtro)
                        .toList(growable: false);
                if (visibles.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('No hay pedidos.'),
                    ),
                  );
                }
                return ListView.separated(
                  itemCount: visibles.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, i) => _tile(visibles[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile(Pedido p) {
    final tema = Theme.of(context);
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: _color(p.estado, tema).withValues(alpha: 0.15),
        child: Icon(Icons.receipt_long_outlined, color: _color(p.estado, tema)),
      ),
      title: Text('${p.numero} · ${p.clienteNombre}'),
      subtitle: Text(
        '${formatearFecha(p.fechaCreacion)} · ${formatearValor(p.total)} · '
        '${p.tipoEntrega.nombre}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Text(p.estado.nombre,
          style: tema.textTheme.bodySmall
              ?.copyWith(color: _color(p.estado, tema))),
      onTap: () => Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(
          builder: (_) => PedidoDetalleScreen(
            pedido: p,
            usuario: widget.usuario,
            pedidosRepository: _repo,
          ),
        ),
      ),
    );
  }

  Color _color(EstadoPedido e, ThemeData tema) => switch (e) {
        EstadoPedido.pendiente => Colors.orange,
        EstadoPedido.confirmado => Colors.green,
        EstadoPedido.cancelado => tema.colorScheme.error,
        _ => tema.colorScheme.primary,
      };
}

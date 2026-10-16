import 'package:flutter/material.dart';

import '../../../core/formato/fechas.dart';
import '../../auth/domain/permisos.dart';
import '../../auth/domain/usuario.dart';
import '../data/inventario_repository.dart';
import '../domain/movimiento_inventario.dart';

/// Kardex de un producto (spec 008, T031): historial de movimientos + ajuste.
class KardexScreen extends StatefulWidget {
  const KardexScreen({
    super.key,
    required this.productoId,
    required this.nombre,
    required this.usuario,
    this.inventarioRepository,
  });

  final String productoId;
  final String nombre;
  final Usuario usuario;
  final InventarioRepository? inventarioRepository;

  @override
  State<KardexScreen> createState() => _KardexScreenState();
}

class _KardexScreenState extends State<KardexScreen> {
  late final InventarioRepository _repo =
      widget.inventarioRepository ?? InventarioRepository();

  String get _empresaId => widget.usuario.empresaId ?? '';
  bool get _puedeAjustar => widget.usuario.puede(Permiso.inventarioEditar);

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

  Future<void> _ajustar() async {
    final cantidad = TextEditingController();
    final motivo = TextEditingController();
    var entrada = true;

    final aplicar = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Ajuste de inventario'),
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
              const SizedBox(height: 12),
              TextField(
                controller: motivo,
                decoration: const InputDecoration(
                  labelText: 'Motivo *',
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
    final n = int.tryParse(cantidad.text.trim()) ?? 0;
    if (n <= 0) return _avisar('La cantidad debe ser mayor que cero.', error: true);
    if (motivo.text.trim().isEmpty) {
      return _avisar('El motivo es obligatorio.', error: true);
    }

    try {
      await _repo.ajuste(
        empresaId: _empresaId,
        productoId: widget.productoId,
        delta: entrada ? n : -n,
        motivo: motivo.text.trim(),
        usuarioUid: widget.usuario.uid,
      );
      if (mounted) _avisar('Ajuste registrado.');
    } catch (e) {
      if (mounted) _avisar('No se pudo ajustar: $e', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kardex · ${widget.nombre}'),
        actions: <Widget>[
          if (_puedeAjustar)
            IconButton(
              tooltip: 'Ajustar',
              icon: const Icon(Icons.tune),
              onPressed: _ajustar,
            ),
        ],
      ),
      body: StreamBuilder<List<MovimientoInventario>>(
        stream: _repo.kardex(_empresaId, widget.productoId),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No se pudo cargar el kardex: ${snap.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          final movimientos = snap.data ?? const <MovimientoInventario>[];
          if (movimientos.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Sin movimientos todavía.'),
              ),
            );
          }
          return ListView.separated(
            itemCount: movimientos.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) => _tile(movimientos[i]),
          );
        },
      ),
    );
  }

  Widget _tile(MovimientoInventario m) {
    final scheme = Theme.of(context).colorScheme;
    final suma = m.suma;
    return ListTile(
      leading: Icon(
        suma ? Icons.arrow_downward : Icons.arrow_upward,
        color: suma ? Colors.green : scheme.error,
      ),
      title: Text(
        '${m.tipo.nombre} · ${suma ? '+' : '−'}${m.cantidad}  →  stock ${m.stockResultante}',
      ),
      subtitle: Text(
        '${formatearFecha(m.fecha)} · ${m.referenciaTipo.nombre}'
        '${m.motivo.isEmpty ? '' : ' · ${m.motivo}'}',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

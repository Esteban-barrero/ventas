import 'package:flutter/material.dart';

import '../../../core/formato/fechas.dart';
import '../../auth/domain/usuario.dart';
import '../data/caja_repository.dart';
import '../domain/caja.dart';
import 'trazabilidad_screen.dart';

/// Panel de caja (spec 009, T020..T023): abrir, mover, cerrar y ver movimientos.
class CajaPanelScreen extends StatefulWidget {
  const CajaPanelScreen({super.key, required this.usuario, this.cajaRepository});

  final Usuario usuario;
  final CajaRepository? cajaRepository;

  @override
  State<CajaPanelScreen> createState() => _CajaPanelScreenState();
}

class _CajaPanelScreenState extends State<CajaPanelScreen> {
  late final CajaRepository _repo =
      widget.cajaRepository ?? CajaRepository();

  String get _empresaId => widget.usuario.empresaId ?? '';
  String get _uid => widget.usuario.uid;

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

  Future<void> _abrir() async {
    final monto = TextEditingController(text: '0');
    var medio = MedioPagoCaja.efectivo;
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Abrir caja'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: monto,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Monto inicial',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<MedioPagoCaja>(
                initialValue: medio,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Medio predominante',
                  border: OutlineInputBorder(),
                ),
                items: <DropdownMenuItem<MedioPagoCaja>>[
                  for (final m in MedioPagoCaja.values)
                    DropdownMenuItem<MedioPagoCaja>(
                        value: m, child: Text(m.nombre)),
                ],
                onChanged: (MedioPagoCaja? v) =>
                    setDialogState(() => medio = v ?? MedioPagoCaja.efectivo),
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
              child: const Text('Abrir caja'),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    try {
      await _repo.abrirCaja(
        empresaId: _empresaId,
        usuarioUid: _uid,
        usuarioNombre: widget.usuario.nombre,
        montoInicial: double.tryParse(monto.text.trim()) ?? 0,
        medioPredominante: medio,
      );
      if (mounted) _avisar('Caja abierta.');
    } catch (e) {
      if (mounted) _avisar('No se pudo abrir la caja: $e', error: true);
    }
  }

  Future<void> _nuevoMovimiento(Caja caja) async {
    final monto = TextEditingController();
    final concepto = TextEditingController();
    var tipo = TipoMovimientoCaja.ingreso;
    var medio = caja.medioPredominante;

    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Nuevo movimiento'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                DropdownButtonFormField<TipoMovimientoCaja>(
                  initialValue: tipo,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Tipo',
                    border: OutlineInputBorder(),
                  ),
                  items: <DropdownMenuItem<TipoMovimientoCaja>>[
                    for (final t in TipoMovimientoCaja.values)
                      DropdownMenuItem<TipoMovimientoCaja>(
                          value: t, child: Text(t.nombre)),
                  ],
                  onChanged: (TipoMovimientoCaja? v) =>
                      setDialogState(() => tipo = v ?? TipoMovimientoCaja.ingreso),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: monto,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Monto',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: concepto,
                  decoration: const InputDecoration(
                    labelText: 'Concepto',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<MedioPagoCaja>(
                  initialValue: medio,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Medio de pago',
                    border: OutlineInputBorder(),
                  ),
                  items: <DropdownMenuItem<MedioPagoCaja>>[
                    for (final m in MedioPagoCaja.values)
                      DropdownMenuItem<MedioPagoCaja>(
                          value: m, child: Text(m.nombre)),
                  ],
                  onChanged: (MedioPagoCaja? v) =>
                      setDialogState(() => medio = v ?? MedioPagoCaja.efectivo),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Registrar'),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    final valor = double.tryParse(monto.text.trim()) ?? 0;
    if (valor <= 0) return _avisar('El monto debe ser mayor que cero.', error: true);
    try {
      await _repo.registrarMovimiento(
        empresaId: _empresaId,
        cajaId: caja.id,
        tipo: tipo,
        concepto: concepto.text.trim(),
        monto: valor,
        medioPago: medio,
        referenciaTipo: ReferenciaCaja.manual,
        usuarioUid: _uid,
      );
      if (mounted) _avisar('Movimiento registrado.');
    } catch (e) {
      if (mounted) _avisar('No se pudo registrar: $e', error: true);
    }
  }

  Future<void> _cerrar(Caja caja) async {
    final contado = TextEditingController(text: caja.saldo.round().toString());
    final justificacion = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final valor = double.tryParse(contado.text.trim()) ?? caja.saldo;
          final diferencia = valor - caja.saldo;
          return AlertDialog(
            title: const Text('Cerrar caja (arqueo)'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Esperado en caja: ${formatearValor(caja.saldo)}'),
                  const SizedBox(height: 12),
                  TextField(
                    controller: contado,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setDialogState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Efectivo contado',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    diferencia == 0
                        ? 'Cuadre perfecto'
                        : (diferencia > 0
                            ? 'Sobrante: ${formatearValor(diferencia)}'
                            : 'Faltante: ${formatearValor(diferencia.abs())}'),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: diferencia == 0 ? Colors.green : Colors.orange,
                    ),
                  ),
                  if (diferencia != 0) ...<Widget>[
                    const SizedBox(height: 12),
                    TextField(
                      controller: justificacion,
                      decoration: const InputDecoration(
                        labelText: 'Justificación *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Cerrar caja'),
              ),
            ],
          );
        },
      ),
    );
    if (ok != true) return;
    try {
      await _repo.cerrarCaja(
        empresaId: _empresaId,
        cajaId: caja.id,
        totalContado: double.tryParse(contado.text.trim()) ?? 0,
        usuarioUid: _uid,
        justificacion: justificacion.text.trim(),
      );
      if (mounted) _avisar('Caja cerrada.');
    } catch (e) {
      if (mounted) _avisar('No se pudo cerrar: $e', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_empresaId.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Caja')),
        body: const Center(child: Text('No perteneces a ninguna empresa.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Caja'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Trazabilidad del dinero',
            icon: const Icon(Icons.account_balance_wallet_outlined),
            onPressed: () => Navigator.of(context).push<void>(
              MaterialPageRoute<void>(
                builder: (_) => TrazabilidadScreen(usuario: widget.usuario),
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder<Caja?>(
        stream: _repo.escucharAbierta(_empresaId, _uid),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final caja = snap.data;
          if (caja == null) return _sinCaja();
          return _conCaja(caja);
        },
      ),
    );
  }

  Widget _sinCaja() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.point_of_sale_outlined, size: 48),
            const SizedBox(height: 12),
            const Text('No tienes una caja abierta.'),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _abrir,
              icon: const Icon(Icons.lock_open_outlined),
              label: const Text('Abrir caja'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _conCaja(Caja caja) {
    final theme = Theme.of(context);
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(16),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      const Icon(Icons.account_balance_wallet_outlined),
                      const SizedBox(width: 8),
                      Expanded(child: Text(caja.nombre, style: theme.textTheme.titleMedium)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: <Widget>[
                      const Expanded(child: Text('Monto inicial')),
                      Text(formatearValor(caja.montoInicial)),
                    ],
                  ),
                  Row(
                    children: <Widget>[
                      const Expanded(child: Text('Saldo en caja')),
                      Text(
                        formatearValor(caja.saldo),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => _nuevoMovimiento(caja),
                          icon: const Icon(Icons.add),
                          label: const Text('Movimiento'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _cerrar(caja),
                          icon: const Icon(Icons.lock_outline),
                          label: const Text('Cerrar caja'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('Movimientos', style: theme.textTheme.titleMedium),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<MovimientoCaja>>(
            stream: _repo.movimientos(_empresaId, cajaId: caja.id),
            builder: (context, snap) {
              final movs = snap.data ?? const <MovimientoCaja>[];
              if (movs.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('Sin movimientos todavía.'),
                  ),
                );
              }
              return ListView.separated(
                itemCount: movs.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final m = movs[i];
                  return ListTile(
                    leading: Icon(
                      m.suma ? Icons.south_west : Icons.north_east,
                      color: m.suma ? Colors.green : theme.colorScheme.error,
                    ),
                    title: Text(
                        '${m.tipo.nombre} · ${formatearValor(m.monto)}'),
                    subtitle: Text(
                      '${m.concepto.isEmpty ? m.referenciaTipo.nombre : m.concepto}'
                      ' · ${m.medioPago.nombre} · ${formatearFecha(m.fecha)}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Text('Saldo ${formatearValor(m.saldoResultante)}',
                        style: theme.textTheme.bodySmall),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

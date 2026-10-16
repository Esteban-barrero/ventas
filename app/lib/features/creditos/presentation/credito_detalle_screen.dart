import 'package:flutter/material.dart';

import '../../../core/formato/fechas.dart';
import '../../auth/domain/permisos.dart';
import '../../auth/domain/usuario.dart';
import '../../empresas/presentation/widgets/tarjeta_datos.dart';
import '../../ventas/domain/venta.dart' show MedioPago;
import '../data/creditos_repository.dart';
import '../domain/credito.dart';

/// Detalle de un crédito: cuotas, saldo, mora y acciones (aprobar, pagar,
/// cancelar). Spec 006, T021/T022.
class CreditoDetalleScreen extends StatefulWidget {
  const CreditoDetalleScreen({
    super.key,
    required this.creditoId,
    required this.usuario,
    this.creditosRepository,
  });

  final String creditoId;
  final Usuario usuario;
  final CreditosRepository? creditosRepository;

  @override
  State<CreditoDetalleScreen> createState() => _CreditoDetalleScreenState();
}

class _CreditoDetalleScreenState extends State<CreditoDetalleScreen> {
  late final CreditosRepository _repo =
      widget.creditosRepository ?? CreditosRepository();

  Credito? _credito;
  bool _cargando = true;
  String? _error;

  bool get _puedeGestionar => widget.usuario.puede(Permiso.creditosEditar);
  bool get _puedeAprobar =>
      _puedeGestionar ||
      widget.usuario.rolesTipados.any((r) => r.id == 'gerente');

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
      final credito = await _repo.obtener(widget.creditoId);
      if (!mounted) return;
      setState(() {
        _credito = credito;
        _cargando = false;
        if (credito == null) _error = 'El crédito ya no existe.';
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

  Future<void> _aprobar() async {
    final credito = _credito;
    if (credito == null) return;
    try {
      await _repo.aprobar(credito.id, aprobadoPor: widget.usuario.uid);
      await _cargar();
      if (mounted) _avisar('Crédito aprobado.');
    } catch (e) {
      if (mounted) _avisar('No se pudo aprobar: $e', error: true);
    }
  }

  Future<void> _registrarPago(List<Cuota> cuotas) async {
    final credito = _credito;
    if (credito == null) return;

    // Por defecto, el valor de la próxima cuota sin pagar (no el saldo total).
    final pendientes = cuotas.where((Cuota c) => c.saldo > 0).toList()
      ..sort((Cuota a, Cuota b) => a.numero.compareTo(b.numero));
    final sugerido =
        pendientes.isNotEmpty ? pendientes.first.saldo : credito.saldoActual;
    final monto = TextEditingController(text: sugerido.round().toString());
    var medio = MedioPago.efectivo;

    final pagar = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Registrar pago'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text('Saldo pendiente: ${formatearValor(credito.saldoActual)}'),
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
              DropdownButtonFormField<MedioPago>(
                initialValue: medio,
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
                    setDialogState(() => medio = v ?? MedioPago.efectivo),
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
              child: const Text('Registrar'),
            ),
          ],
        ),
      ),
    );

    if (pagar != true) return;
    final valor = double.tryParse(monto.text.trim()) ?? 0;
    try {
      await _repo.registrarPago(
        credito.id,
        valor,
        medio,
        cobradorUid: widget.usuario.uid,
      );
      await _cargar();
      if (mounted) _avisar('Pago registrado.');
    } catch (e) {
      if (mounted) _avisar('No se pudo registrar el pago: $e', error: true);
    }
  }

  Future<void> _cancelar() async {
    final credito = _credito;
    if (credito == null) return;
    final motivo = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar crédito'),
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
            child: const Text('Cancelar crédito'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _repo.cancelar(credito.id, motivo.text.trim());
      await _cargar();
      if (mounted) _avisar('Crédito cancelado.');
    } catch (e) {
      if (mounted) _avisar('No se pudo cancelar: $e', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final credito = _credito;
    return Scaffold(
      appBar: AppBar(title: Text(credito?.clienteNombre ?? 'Crédito')),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(_error!, textAlign: TextAlign.center),
                  ),
                )
              : _cuerpo(credito!),
    );
  }

  Widget _cuerpo(Credito credito) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return StreamBuilder<List<Cuota>>(
      stream: _repo.escucharCuotas(credito.id),
      builder: (context, snap) {
        final cuotas = snap.data ?? const <Cuota>[];
        final mora = calcularMoraDeCuotas(cuotas);
        final vencido = mora > 0 && !credito.pagado && !credito.cancelado;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            if (!credito.aprobado)
              Card(
                color: scheme.tertiaryContainer,
                child: ListTile(
                  leading: Icon(Icons.hourglass_empty,
                      color: scheme.onTertiaryContainer),
                  title: Text('Crédito sin aprobar',
                      style: TextStyle(color: scheme.onTertiaryContainer)),
                ),
              ),
            if (credito.cancelado)
              Card(
                color: scheme.errorContainer,
                child: ListTile(
                  leading:
                      Icon(Icons.cancel_outlined, color: scheme.onErrorContainer),
                  title: Text('Crédito cancelado',
                      style: TextStyle(color: scheme.onErrorContainer)),
                  subtitle: Text(credito.motivoCancelacion.isEmpty
                      ? 'Sin motivo'
                      : credito.motivoCancelacion),
                ),
              ),
            TarjetaDatos(
              titulo: 'Crédito',
              icono: Icons.request_quote_outlined,
              filas: <FilaDato>[
                FilaDato('Cliente', credito.clienteNombre),
                FilaDato('Monto', formatearValor(credito.montoTotal)),
                if (credito.tasaInteres > 0)
                  FilaDato('Interés', '${credito.tasaInteres.round()}%'),
                FilaDato('Total con interés',
                    formatearValor(credito.montoConInteres)),
                FilaDato('Cuotas',
                    '${credito.cuotasPagadas}/${credito.numeroCuotas} · ${credito.periodicidad.nombre}'),
                FilaDato('Saldo', formatearValor(credito.saldoActual)),
                FilaDato(
                  'Estado',
                  credito.cancelado || credito.pagado
                      ? credito.estado.nombre
                      : (vencido ? 'Vencido' : credito.estado.nombre),
                ),
                if (mora > 0) FilaDato('Días de mora', '$mora'),
              ],
            ),
            const SizedBox(height: 12),
            TarjetaDatos(
              titulo: 'Plan de cuotas',
              icono: Icons.list_alt_outlined,
              filas: <FilaDato>[
                for (final c in cuotas)
                  FilaDato(
                    '#${c.numero} · ${formatearFecha(c.fechaVencimiento)}',
                    '${formatearValor(c.pagado)}/${formatearValor(c.monto)} · ${c.estado.nombre}',
                  ),
              ],
            ),
            const SizedBox(height: 24),
            if (!credito.aprobado && _puedeAprobar)
              FilledButton.icon(
                onPressed: _aprobar,
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Aprobar crédito'),
              ),
            if (!credito.pagado && !credito.cancelado && _puedeGestionar) ...<Widget>[
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => _registrarPago(cuotas),
                icon: const Icon(Icons.payments_outlined),
                label: const Text('Registrar pago'),
              ),
            ],
            if (!credito.pagado && !credito.cancelado && _puedeGestionar) ...<Widget>[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _cancelar,
                icon: const Icon(Icons.cancel_outlined),
                label: const Text('Cancelar crédito'),
                style: OutlinedButton.styleFrom(foregroundColor: scheme.error),
              ),
            ],
            const SizedBox(height: 32),
          ],
        );
      },
    );
  }
}

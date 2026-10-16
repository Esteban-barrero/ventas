import 'package:flutter/material.dart';

import '../../../core/formato/fechas.dart';
import '../../auth/domain/permisos.dart';
import '../../auth/domain/usuario.dart';
import '../data/tesoreria_repository.dart';
import '../domain/movimiento_dinero.dart';
import '../domain/posiciones.dart';
import '../domain/rendicion.dart';

/// Pantalla de **Tesorería** (spec 016): total del dinero, desglose por
/// ubicación y responsable, movimientos y traslados.
class TesoreriaScreen extends StatefulWidget {
  const TesoreriaScreen({super.key, required this.usuario, this.tesoreriaRepository});

  final Usuario usuario;
  final TesoreriaRepository? tesoreriaRepository;

  @override
  State<TesoreriaScreen> createState() => _TesoreriaScreenState();
}

class _TesoreriaScreenState extends State<TesoreriaScreen> {
  late final TesoreriaRepository _repo =
      widget.tesoreriaRepository ?? TesoreriaRepository();

  String get _empresaId => widget.usuario.empresaId ?? '';
  String get _uid => widget.usuario.uid;
  String get _nombre => widget.usuario.nombre;

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

  Future<void> _nuevoMovimiento() async {
    var tipo = TipoMovimientoDinero.ingreso;
    var ubicacion = UbicacionDinero.cajaFisica;
    var medio = MedioDinero.efectivo;
    final monto = TextEditingController();
    final descripcion = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Movimiento de dinero'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                DropdownButtonFormField<TipoMovimientoDinero>(
                  initialValue: tipo,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Tipo',
                    border: OutlineInputBorder(),
                  ),
                  items: <DropdownMenuItem<TipoMovimientoDinero>>[
                    const DropdownMenuItem<TipoMovimientoDinero>(
                      value: TipoMovimientoDinero.ingreso,
                      child: Text('Ingreso'),
                    ),
                    const DropdownMenuItem<TipoMovimientoDinero>(
                      value: TipoMovimientoDinero.egreso,
                      child: Text('Egreso / gasto / retiro'),
                    ),
                  ],
                  onChanged: (TipoMovimientoDinero? v) => setDialogState(
                      () => tipo = v ?? TipoMovimientoDinero.ingreso),
                ),
                const SizedBox(height: 12),
                _dropUbicacion(
                  valor: ubicacion,
                  onChanged: (UbicacionDinero v) =>
                      setDialogState(() => ubicacion = v),
                ),
                const SizedBox(height: 12),
                _dropMedio(
                  valor: medio,
                  onChanged: (MedioDinero v) => setDialogState(() => medio = v),
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
                  controller: descripcion,
                  decoration: const InputDecoration(
                    labelText: 'Descripción',
                    border: OutlineInputBorder(),
                  ),
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
    final valor = parsearNumero(monto.text) ?? 0;
    if (valor <= 0) return _avisar('El monto debe ser mayor que cero.', error: true);
    try {
      await _repo.registrarMovimiento(
        empresaId: _empresaId,
        tipo: tipo,
        monto: valor,
        ubicacion: ubicacion,
        medioPago: medio,
        referenciaTipo: tipo == TipoMovimientoDinero.ingreso
            ? ReferenciaDinero.ajuste
            : ReferenciaDinero.gasto,
        usuarioUid: _uid,
        usuarioNombre: _nombre,
        responsableUid: _uid,
        responsableNombre: _nombre,
        descripcion: descripcion.text.trim(),
      );
      if (mounted) _avisar('Movimiento registrado.');
    } catch (e) {
      if (mounted) _avisar('No se pudo registrar: $e', error: true);
    }
  }

  Future<void> _trasladar() async {
    var origen = UbicacionDinero.vendedorEfectivo;
    var destino = UbicacionDinero.cajaFisica;
    final monto = TextEditingController();
    final descripcion = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Trasladar dinero'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                _dropUbicacion(
                  label: 'Origen',
                  valor: origen,
                  onChanged: (UbicacionDinero v) =>
                      setDialogState(() => origen = v),
                ),
                const SizedBox(height: 12),
                _dropUbicacion(
                  label: 'Destino',
                  valor: destino,
                  onChanged: (UbicacionDinero v) =>
                      setDialogState(() => destino = v),
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
                  controller: descripcion,
                  decoration: const InputDecoration(
                    labelText: 'Descripción',
                    border: OutlineInputBorder(),
                  ),
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
              child: const Text('Trasladar'),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    final valor = parsearNumero(monto.text) ?? 0;
    if (valor <= 0) return _avisar('El monto debe ser mayor que cero.', error: true);
    try {
      await _repo.trasladar(
        empresaId: _empresaId,
        monto: valor,
        origen: origen,
        destino: destino,
        usuarioUid: _uid,
        usuarioNombre: _nombre,
        descripcion: descripcion.text.trim(),
      );
      if (mounted) _avisar('Traslado registrado.');
    } catch (e) {
      if (mounted) _avisar('No se pudo trasladar: $e', error: true);
    }
  }

  Widget _dropUbicacion({
    String label = 'Ubicación',
    required UbicacionDinero valor,
    required ValueChanged<UbicacionDinero> onChanged,
  }) {
    return DropdownButtonFormField<UbicacionDinero>(
      initialValue: valor,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: <DropdownMenuItem<UbicacionDinero>>[
        for (final u in UbicacionDinero.values)
          DropdownMenuItem<UbicacionDinero>(value: u, child: Text(u.nombre)),
      ],
      onChanged: (UbicacionDinero? v) =>
          onChanged(v ?? UbicacionDinero.cajaFisica),
    );
  }

  Widget _dropMedio({
    required MedioDinero valor,
    required ValueChanged<MedioDinero> onChanged,
  }) {
    return DropdownButtonFormField<MedioDinero>(
      initialValue: valor,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Medio',
        border: OutlineInputBorder(),
      ),
      items: <DropdownMenuItem<MedioDinero>>[
        for (final m in MedioDinero.values)
          DropdownMenuItem<MedioDinero>(value: m, child: Text(m.nombre)),
      ],
      onChanged: (MedioDinero? v) => onChanged(v ?? MedioDinero.efectivo),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_empresaId.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Tesorería')),
        body: const Center(child: Text('No perteneces a ninguna empresa.')),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tesorería'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Movimiento',
            icon: const Icon(Icons.add),
            onPressed: _nuevoMovimiento,
          ),
          IconButton(
            tooltip: 'Trasladar',
            icon: const Icon(Icons.swap_horiz),
            onPressed: _trasladar,
          ),
        ],
      ),
      body: StreamBuilder<List<MovimientoDinero>>(
        stream: _repo.escucharMovimientos(_empresaId),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final movs = snap.data ?? const <MovimientoDinero>[];
          final posiciones = calcularPosiciones(movs);
          final porResp = posicionesPorResponsable(movs);
          final total = totalDePosiciones(posiciones);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              _totalCard(total),
              const SizedBox(height: 16),
              if (widget.usuario.puede(Permiso.cajaConfirmar)) ...<Widget>[
                _rendicionesPendientes(),
                const SizedBox(height: 16),
              ],
              Text('Dónde está el dinero',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ..._ubicaciones(porResp),
              const SizedBox(height: 16),
              Text('Movimientos',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (movs.isEmpty)
                const Text('Sin movimientos todavía.')
              else
                ...movs.map(_tileMovimiento),
            ],
          );
        },
      ),
    );
  }

  /// Rendiciones pendientes de confirmar (spec 016, doble control).
  Widget _rendicionesPendientes() {
    final tema = Theme.of(context);
    return StreamBuilder<List<Rendicion>>(
      stream: _repo.escucharRendiciones(
        _empresaId,
        estado: EstadoRendicion.pendiente,
      ),
      builder: (context, snap) {
        final pend = snap.data ?? const <Rendicion>[];
        if (pend.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Rendiciones por confirmar', style: tema.textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final Rendicion r in pend)
              Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(Icons.receipt_long_outlined),
                  title: Text(
                      '${r.domiciliarioNombre} · ${formatearValor(r.montoDeclarado)}'),
                  subtitle: Text(
                    'Declarada ${formatearFecha(r.fecha)}'
                    '${r.observaciones.isEmpty ? '' : ' · ${r.observaciones}'}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      IconButton(
                        tooltip: 'Rechazar',
                        icon: const Icon(Icons.close),
                        onPressed: () => _rechazarRendicion(r),
                      ),
                      FilledButton(
                        onPressed: () => _confirmarRendicion(r),
                        child: const Text('Confirmar'),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  /// Confirma una rendición contando el efectivo (RF-05).
  Future<void> _confirmarRendicion(Rendicion r) async {
    double disponible = 0;
    try {
      final pos = await _repo.posiciones(_empresaId);
      disponible = pos[UbicacionDinero.vendedorEfectivo] ?? 0;
    } catch (_) {
      // Si no se puede leer, se confirma sin el aviso de disponible.
    }
    if (!mounted) return;
    final contado = TextEditingController(text: numeroParaEditar(r.montoDeclarado));
    final justificacion = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final valor = parsearNumero(contado.text) ?? r.montoDeclarado;
          final diferencia = r.montoDeclarado - valor;
          final excede = valor > disponible + 0.001;
          return AlertDialog(
            title: const Text('Confirmar rendición'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('${r.domiciliarioNombre} declara '
                      '${formatearValor(r.montoDeclarado)}.'),
                  const SizedBox(height: 4),
                  Text(
                    'Disponible con el vendedor: ${formatearValor(disponible)}.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (excede)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'El monto supera lo disponible. Ajusta el valor o '
                        'rechaza la rendición y pídele al domiciliario que la '
                        'declare de nuevo.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
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
                            ? 'Faltante: ${formatearValor(diferencia)}'
                            : 'Sobrante: ${formatearValor(diferencia.abs())}'),
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
                onPressed:
                    excede ? null : () => Navigator.of(context).pop(true),
                child: const Text('Confirmar recepción'),
              ),
            ],
          );
        },
      ),
    );
    if (ok != true) return;
    try {
      await _repo.confirmarRendicion(
        rendicionId: r.id,
        empresaId: _empresaId,
        recibidoPorUid: _uid,
        recibidoPorNombre: _nombre,
        montoContado: parsearNumero(contado.text) ?? 0,
        justificacion: justificacion.text.trim(),
      );
      if (mounted) _avisar('Rendición confirmada.');
    } catch (e) {
      if (mounted) _avisar('No se pudo confirmar: $e', error: true);
    }
  }

  /// Rechaza una rendición (no se recibe el dinero).
  Future<void> _rechazarRendicion(Rendicion r) async {
    final motivo = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rechazar rendición'),
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
            child: const Text('Rechazar'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _repo.rechazarRendicion(
        rendicionId: r.id,
        empresaId: _empresaId,
        usuarioUid: _uid,
        motivo: motivo.text.trim(),
      );
      if (mounted) _avisar('Rendición rechazada.');
    } catch (e) {
      if (mounted) _avisar('No se pudo rechazar: $e', error: true);
    }
  }

  Widget _totalCard(double total) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: <Widget>[
            Text('Total de la empresa', style: theme.textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              formatearValor(total),
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _ubicaciones(Map<UbicacionDinero, Map<String, double>> porResp) {
    final conDinero = UbicacionDinero.values.where((UbicacionDinero u) {
      final resp = porResp[u] ?? const <String, double>{};
      return resp.values.any((double v) => v.abs() > 0.001);
    }).toList();
    if (conDinero.isEmpty) {
      return <Widget>[const Text('Aún no hay dinero registrado.')];
    }
    return <Widget>[
      for (final u in conDinero)
        Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    const Icon(Icons.place_outlined, size: 18),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(u.nombre,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Text(
                      formatearValor(
                        (porResp[u] ?? const <String, double>{})
                            .values
                            .fold<double>(0, (double a, double b) => a + b),
                      ),
                    ),
                  ],
                ),
                for (final entry in (porResp[u] ?? const <String, double>{})
                    .entries
                    .where((e) => e.value.abs() > 0.001))
                  Padding(
                    padding: const EdgeInsets.only(left: 24, top: 4),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Text('· ${entry.key}',
                              style: Theme.of(context).textTheme.bodySmall),
                        ),
                        Text(formatearValor(entry.value),
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
    ];
  }

  Widget _tileMovimiento(MovimientoDinero m) {
    final theme = Theme.of(context);
    final color = switch (m.tipo) {
      TipoMovimientoDinero.ingreso => Colors.green,
      TipoMovimientoDinero.egreso => theme.colorScheme.error,
      TipoMovimientoDinero.traslado => theme.colorScheme.primary,
    };
    final subtitulo = m.tipo == TipoMovimientoDinero.traslado
        ? '${m.ubicacion.nombre} → ${m.ubicacionDestino?.nombre ?? '—'}'
        : m.ubicacion.nombre;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(Icons.circle, size: 12, color: color),
      title: Text('${m.tipo.nombre} · ${formatearValor(m.monto)}'),
      subtitle: Text(
        '${m.descripcion.isEmpty ? subtitulo : m.descripcion} · '
        '${m.responsableNombre.isEmpty ? subtitulo : m.responsableNombre} · '
        '${formatearFecha(m.fecha)}',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

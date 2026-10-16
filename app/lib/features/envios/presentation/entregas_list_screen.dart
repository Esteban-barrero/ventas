import 'package:flutter/material.dart';

import '../../../core/formato/fechas.dart';
import '../../auth/domain/usuario.dart';
import '../../clientes/data/clientes_repository.dart';
import '../../clientes/domain/cliente.dart';
import '../../tesoreria/data/tesoreria_repository.dart';
import '../../tesoreria/domain/movimiento_dinero.dart';
import '../../tesoreria/domain/rendicion.dart';
import '../../ventas/domain/venta.dart';
import '../data/entregas_repository.dart';
import 'entrega_detalle_screen.dart';

/// Lista de **pendientes por entregar** (spec 011, MVP / spec 016 para el
/// dinero). Filtra por estado y por ciudad; permite rendir el efectivo.
class EntregasListScreen extends StatefulWidget {
  const EntregasListScreen({
    super.key,
    required this.usuario,
    this.entregasRepository,
    this.clientesRepository,
    this.tesoreriaRepository,
  });

  final Usuario usuario;
  final EntregasRepository? entregasRepository;
  final ClientesRepository? clientesRepository;
  final TesoreriaRepository? tesoreriaRepository;

  @override
  State<EntregasListScreen> createState() => _EntregasListScreenState();
}

class _EntregasListScreenState extends State<EntregasListScreen> {
  late final EntregasRepository _entregas =
      widget.entregasRepository ?? EntregasRepository();
  late final ClientesRepository _clientesRepo =
      widget.clientesRepository ?? ClientesRepository();
  late final TesoreriaRepository _tesoreria =
      widget.tesoreriaRepository ?? TesoreriaRepository();

  Map<String, Cliente> _clientes = <String, Cliente>{};
  EstadoEnvio? _filtro;
  String? _ciudad;
  bool _rindiendo = false;

  String get _empresaId => widget.usuario.empresaId ?? '';

  @override
  void initState() {
    super.initState();
    _cargarClientes();
  }

  Future<void> _cargarClientes() async {
    try {
      final lista = await _clientesRepo.listar(_empresaId);
      if (!mounted) return;
      setState(() => _clientes = <String, Cliente>{
            for (final Cliente c in lista) c.id: c,
          });
    } catch (_) {
      // Si falla, la lista de entregas sigue funcionando sin dirección.
    }
  }

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

  String _ciudadDe(Venta v) {
    final cliente = v.clienteId == null ? null : _clientes[v.clienteId];
    return cliente?.direccion.ciudad ?? '';
  }

  /// Efectivo que tiene el domiciliario (ubicación `vendedorEfectivo`).
  Future<double> _miEfectivo() async {
    final movs = await _tesoreria.movimientos(_empresaId);
    double saldo = 0;
    for (final MovimientoDinero m in movs) {
      if (m.responsableUid != widget.usuario.uid) continue;
      switch (m.tipo) {
        case TipoMovimientoDinero.ingreso:
          if (m.ubicacion == UbicacionDinero.vendedorEfectivo) saldo += m.monto;
        case TipoMovimientoDinero.egreso:
          if (m.ubicacion == UbicacionDinero.vendedorEfectivo) saldo -= m.monto;
        case TipoMovimientoDinero.traslado:
          if (m.ubicacion == UbicacionDinero.vendedorEfectivo) saldo -= m.monto;
          if (m.ubicacionDestino == UbicacionDinero.vendedorEfectivo) {
            saldo += m.monto;
          }
      }
    }
    return saldo;
  }

  /// **Declara** una rendición de efectivo (spec 016, RF-05). El dinero no se
  /// mueve hasta que un responsable la confirme contando el efectivo.
  Future<void> _declararRendicion() async {
    final saldo = await _miEfectivo();
    if (!mounted) return;
    if (saldo <= 0.5) {
      _avisar('No tienes efectivo por declarar.');
      return;
    }
    final monto = TextEditingController(text: numeroParaEditar(saldo));
    final observaciones = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Declarar rendición'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                'Tienes ${formatearValor(saldo)} por entregar. '
                'Un responsable en tesorería debe confirmarlo.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: monto,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Monto a entregar',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: observaciones,
                decoration: const InputDecoration(
                  labelText: 'Observaciones (opcional)',
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
            child: const Text('Declarar'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final valor = parsearNumero(monto.text) ?? 0;
    if (valor <= 0) {
      _avisar('El monto debe ser mayor que cero.', error: true);
      return;
    }
    if (valor > saldo + 0.001) {
      _avisar('Solo tienes ${formatearValor(saldo)} por declarar.', error: true);
      return;
    }
    setState(() => _rindiendo = true);
    try {
      await _tesoreria.declararRendicion(
        empresaId: _empresaId,
        domiciliarioUid: widget.usuario.uid,
        domiciliarioNombre: widget.usuario.nombre,
        montoDeclarado: valor,
        observaciones: observaciones.text.trim(),
      );
      if (mounted) _avisar('Rendición declarada. Espera la confirmación.');
    } catch (e) {
      if (mounted) _avisar('No se pudo declarar: $e', error: true);
    } finally {
      if (mounted) setState(() => _rindiendo = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_empresaId.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Pendientes por entregar')),
        body: const Center(child: Text('No perteneces a ninguna empresa.')),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pendientes por entregar'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Declarar rendición',
            icon: _rindiendo
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.price_check_outlined),
            onPressed: _rindiendo ? null : _declararRendicion,
          ),
        ],
      ),
      body: StreamBuilder<List<Venta>>(
        stream: _entregas.escucharPorEntregar(_empresaId),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final todas = snap.data ?? const <Venta>[];
          final ciudades = <String>{
            for (final Venta v in todas)
              if (_ciudadDe(v).isNotEmpty) _ciudadDe(v),
          }.toList()
            ..sort();
          final visibles = todas.where((Venta v) {
            if (_filtro != null && v.estadoEnvioActual != _filtro) return false;
            if (_ciudad != null && _ciudad!.isNotEmpty && _ciudadDe(v) != _ciudad) {
              return false;
            }
            return true;
          }).toList(growable: false);

          return Column(
            children: <Widget>[
              _avisoRendicion(),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                child: Column(
                  children: <Widget>[
                    Wrap(
                      spacing: 8,
                      children: <Widget>[
                        FilterChip(
                          label: const Text('Por entregar'),
                          selected: _filtro == EstadoEnvio.pendiente,
                          onSelected: (_) => setState(() => _filtro =
                              _filtro == EstadoEnvio.pendiente
                                  ? null
                                  : EstadoEnvio.pendiente),
                        ),
                        FilterChip(
                          label: const Text('En reparto'),
                          selected: _filtro == EstadoEnvio.enReparto,
                          onSelected: (_) => setState(() => _filtro =
                              _filtro == EstadoEnvio.enReparto
                                  ? null
                                  : EstadoEnvio.enReparto),
                        ),
                        FilterChip(
                          label: const Text('Novedad'),
                          selected: _filtro == EstadoEnvio.novedad,
                          onSelected: (_) => setState(() => _filtro =
                              _filtro == EstadoEnvio.novedad
                                  ? null
                                  : EstadoEnvio.novedad),
                        ),
                      ],
                    ),
                    if (ciudades.isNotEmpty)
                      DropdownButtonFormField<String?>(
                        initialValue: _ciudad,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Ciudad',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: <DropdownMenuItem<String?>>[
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('Todas las ciudades'),
                          ),
                          for (final c in ciudades)
                            DropdownMenuItem<String?>(value: c, child: Text(c)),
                        ],
                        onChanged: (String? v) => setState(() => _ciudad = v),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: visibles.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text('No hay entregas pendientes.'),
                        ),
                      )
                    : ListView.separated(
                        itemCount: visibles.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, i) => _tile(visibles[i]),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Aviso de rendición pendiente de confirmar por tesorería (spec 016).
  Widget _avisoRendicion() {
    return StreamBuilder<List<Rendicion>>(
      stream: _tesoreria.escucharRendiciones(
        _empresaId,
        estado: EstadoRendicion.pendiente,
        domiciliarioUid: widget.usuario.uid,
      ),
      builder: (context, snap) {
        final pendientes = snap.data ?? const <Rendicion>[];
        if (pendientes.isEmpty) return const SizedBox.shrink();
        final total = pendientes.fold<double>(
            0, (double a, Rendicion r) => a + r.montoDeclarado);
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: <Widget>[
              const Icon(Icons.hourglass_top_outlined, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Rendición pendiente por confirmar: ${formatearValor(total)}',
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _tile(Venta v) {    final tema = Theme.of(context);
    final ciudad = _ciudadDe(v);
    final cliente = v.clienteId == null ? null : _clientes[v.clienteId];
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: _colorEstado(v.estadoEnvioActual, tema).withValues(alpha: 0.15),
        child: Icon(Icons.local_shipping_outlined,
            color: _colorEstado(v.estadoEnvioActual, tema)),
      ),
      title: Text('${v.numeroFactura} · ${v.clienteNombre}'),
      subtitle: Text(
        '${ciudad.isEmpty ? 'Sin ciudad' : ciudad} · ${formatearValor(v.total)} · '
        '${cliente?.telefono ?? ''}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Text(v.estadoEnvioActual.nombre,
          style: tema.textTheme.bodySmall
              ?.copyWith(color: _colorEstado(v.estadoEnvioActual, tema))),
      onTap: () => Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => EntregaDetalleScreen(
            venta: v,
            usuario: widget.usuario,
            cliente: cliente,
            entregasRepository: _entregas,
            tesoreriaRepository: _tesoreria,
          ),
        ),
      ),
    );
  }

  Color _colorEstado(EstadoEnvio e, ThemeData tema) => switch (e) {
        EstadoEnvio.pendiente => Colors.orange,
        EstadoEnvio.enReparto => tema.colorScheme.primary,
        EstadoEnvio.entregado => Colors.green,
        EstadoEnvio.novedad => tema.colorScheme.error,
      };
}

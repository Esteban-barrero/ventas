import 'package:flutter/material.dart';

import '../../../core/formato/fechas.dart';
import '../../auth/domain/usuario.dart';
import '../../clientes/data/clientes_repository.dart';
import '../../clientes/domain/cliente.dart';
import '../../tesoreria/data/tesoreria_repository.dart';
import '../../tesoreria/domain/movimiento_dinero.dart';
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

  /// Rinde el efectivo del domiciliario a la caja física (spec 016, RF-05).
  Future<void> _rendir() async {
    setState(() => _rindiendo = true);
    try {
      final saldo = await _miEfectivo();
      if (saldo <= 0.5) {
        if (mounted) _avisar('No tienes efectivo por rendir.');
        return;
      }
      await _tesoreria.trasladar(
        empresaId: _empresaId,
        monto: saldo,
        origen: UbicacionDinero.vendedorEfectivo,
        destino: UbicacionDinero.cajaFisica,
        usuarioUid: widget.usuario.uid,
        usuarioNombre: widget.usuario.nombre,
        responsableUid: widget.usuario.uid,
        responsableNombre: widget.usuario.nombre,
        descripcion: 'Rendición de efectivo',
      );
      if (mounted) _avisar('Rendiste ${formatearValor(saldo)} a caja.');
    } catch (e) {
      if (mounted) _avisar('No se pudo rendir: $e', error: true);
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
            tooltip: 'Rendir efectivo',
            icon: _rindiendo
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.price_check_outlined),
            onPressed: _rindiendo ? null : _rendir,
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

  Widget _tile(Venta v) {
    final tema = Theme.of(context);
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

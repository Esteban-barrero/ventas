import 'package:flutter/material.dart';

import '../../../core/formato/fechas.dart';
import '../../auth/domain/usuario.dart';
import '../data/caja_repository.dart';
import '../domain/caja.dart';

/// Trazabilidad del dinero (spec 009, T024): movimientos con **quién** tiene el
/// dinero, **dónde** está y **cómo** se pagó.
class TrazabilidadScreen extends StatefulWidget {
  const TrazabilidadScreen({super.key, required this.usuario, this.cajaRepository});

  final Usuario usuario;
  final CajaRepository? cajaRepository;

  @override
  State<TrazabilidadScreen> createState() => _TrazabilidadScreenState();
}

class _TrazabilidadScreenState extends State<TrazabilidadScreen> {
  late final CajaRepository _repo =
      widget.cajaRepository ?? CajaRepository();

  EstadoDinero? _estado;

  String get _empresaId => widget.usuario.empresaId ?? '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trazabilidad del dinero')),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: DropdownButtonFormField<EstadoDinero?>(
              initialValue: _estado,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Estado del dinero',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: <DropdownMenuItem<EstadoDinero?>>[
                const DropdownMenuItem<EstadoDinero?>(
                  value: null,
                  child: Text('Todos'),
                ),
                for (final e in EstadoDinero.values)
                  DropdownMenuItem<EstadoDinero?>(
                    value: e,
                    child: Text(e.nombre),
                  ),
              ],
              onChanged: (EstadoDinero? v) => setState(() => _estado = v),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<MovimientoCaja>>(
              stream: _repo.movimientos(_empresaId),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final todos = snap.data ?? const <MovimientoCaja>[];
                final visibles = _estado == null
                    ? todos
                    : todos
                        .where((MovimientoCaja m) => m.estadoDinero == _estado)
                        .toList(growable: false);
                if (visibles.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('Sin movimientos de dinero.'),
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

  Widget _tile(MovimientoCaja m) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(
        m.suma ? Icons.south_west : Icons.north_east,
        color: m.suma ? Colors.green : theme.colorScheme.error,
      ),
      title: Text('${m.tipo.nombre} · ${formatearValor(m.monto)}'),
      subtitle: Text(
        '${m.estadoDinero.nombre} · ${m.medioPago.nombre}'
        ' · resp: ${m.responsableUid.isEmpty ? '—' : m.responsableUid}',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Text(formatearFecha(m.fecha),
          style: theme.textTheme.bodySmall),
    );
  }
}

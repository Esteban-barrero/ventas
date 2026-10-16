import 'package:flutter/material.dart';

import '../../../core/formato/fechas.dart';
import '../../auth/domain/usuario.dart';
import '../data/creditos_repository.dart';
import '../domain/credito.dart';
import 'credito_detalle_screen.dart';

/// Listado de créditos (cartera) de la empresa (spec 006, T020).
class CreditosListScreen extends StatefulWidget {
  const CreditosListScreen({
    super.key,
    required this.usuario,
    this.creditosRepository,
  });

  final Usuario usuario;
  final CreditosRepository? creditosRepository;

  @override
  State<CreditosListScreen> createState() => _CreditosListScreenState();
}

class _CreditosListScreenState extends State<CreditosListScreen> {
  late final CreditosRepository _repo =
      widget.creditosRepository ?? CreditosRepository();

  final TextEditingController _busqueda = TextEditingController();
  EstadoCredito? _estado;

  String get _empresaId => widget.usuario.empresaId ?? '';

  @override
  void initState() {
    super.initState();
    _busqueda.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _busqueda.dispose();
    super.dispose();
  }

  Future<void> _abrir(Credito credito) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => CreditoDetalleScreen(
          creditoId: credito.id,
          usuario: widget.usuario,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_empresaId.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Créditos')),
        body: const Center(child: Text('No perteneces a ninguna empresa.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Créditos')),
      body: StreamBuilder<List<Credito>>(
        stream: _repo.escuchar(_empresaId),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Text('No se pudieron cargar los créditos: ${snap.error}'),
            );
          }
          final todos = snap.data ?? const <Credito>[];
          final visibles = CreditosRepository.filtrar(
            todos,
            busqueda: _busqueda.text,
            estado: _estado,
          );
          return Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Column(
                  children: <Widget>[
                    TextField(
                      controller: _busqueda,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        hintText: 'Buscar por cliente',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<EstadoCredito?>(
                      initialValue: _estado,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Estado',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: <DropdownMenuItem<EstadoCredito?>>[
                        const DropdownMenuItem<EstadoCredito?>(
                          value: null,
                          child: Text('Todos'),
                        ),
                        for (final e in EstadoCredito.values)
                          DropdownMenuItem<EstadoCredito?>(
                            value: e,
                            child: Text(e.nombre),
                          ),
                      ],
                      onChanged: (EstadoCredito? v) => setState(() => _estado = v),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: visibles.isEmpty
                    ? _vacio(todos.isEmpty)
                    : ListView.separated(
                        padding: const EdgeInsets.only(bottom: 24),
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

  Widget _tile(Credito credito) {
    return ListTile(
      leading: CircleAvatar(
        child: Icon(credito.aprobado ? Icons.check : Icons.hourglass_empty),
      ),
      title: Text(credito.clienteNombre.isEmpty
          ? 'Consumidor final'
          : credito.clienteNombre),
      subtitle: Text(
        '${credito.numeroCuotas} cuotas · ${credito.periodicidad.nombre} · ${credito.cuotasPagadas} pagadas',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          Text('Saldo ${formatearValor(credito.saldoActual)}',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(credito.estado.nombre, style: const TextStyle(fontSize: 11)),
        ],
      ),
      onTap: () => _abrir(credito),
    );
  }

  Widget _vacio(bool sinCreditos) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.request_quote_outlined, size: 48),
            const SizedBox(height: 12),
            Text(
              sinCreditos
                  ? 'Todavía no hay créditos. Se crean al registrar una venta a crédito.'
                  : 'No se encontraron créditos con esos filtros.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

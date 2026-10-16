import 'package:flutter/material.dart';

import '../../../core/formato/fechas.dart';
import '../../auth/domain/permisos.dart';
import '../../auth/domain/usuario.dart';
import '../data/ventas_repository.dart';
import '../domain/venta.dart';
import 'venta_detalle_screen.dart';
import 'venta_nueva_screen.dart';

/// Listado de ventas de la empresa (spec 005, RF-01..RF-03, RF-16).
class VentasListScreen extends StatefulWidget {
  const VentasListScreen({super.key, required this.usuario, this.ventasRepository});

  final Usuario usuario;
  final VentasRepository? ventasRepository;

  @override
  State<VentasListScreen> createState() => _VentasListScreenState();
}

class _VentasListScreenState extends State<VentasListScreen> {
  late final VentasRepository _repo =
      widget.ventasRepository ?? VentasRepository();

  final TextEditingController _busqueda = TextEditingController();
  EstadoVenta? _estado;

  String get _empresaId => widget.usuario.empresaId ?? '';
  bool get _puedeCrear => widget.usuario.puede(Permiso.ventasCrear);

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

  Future<void> _nueva() async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => VentaNuevaScreen(usuario: widget.usuario),
      ),
    );
  }

  Future<void> _abrir(Venta venta) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => VentaDetalleScreen(
          ventaId: venta.id,
          usuario: widget.usuario,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_empresaId.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Ventas')),
        body: const Center(child: Text('No perteneces a ninguna empresa.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Ventas')),
      floatingActionButton: _puedeCrear
          ? FloatingActionButton.extended(
              onPressed: _nueva,
              icon: const Icon(Icons.add),
              label: const Text('Nueva venta'),
            )
          : null,
      body: StreamBuilder<List<Venta>>(
        stream: _repo.escuchar(_empresaId),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Text('No se pudieron cargar las ventas: ${snap.error}'),
            );
          }
          final todas = snap.data ?? const <Venta>[];
          final visibles = VentasRepository.filtrar(
            todas,
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
                        hintText: 'Buscar por factura o cliente',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<EstadoVenta?>(
                      initialValue: _estado,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Estado',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: <DropdownMenuItem<EstadoVenta?>>[
                        const DropdownMenuItem<EstadoVenta?>(
                          value: null,
                          child: Text('Todas'),
                        ),
                        for (final e in EstadoVenta.values)
                          DropdownMenuItem<EstadoVenta?>(
                            value: e,
                            child: Text(e.nombre),
                          ),
                      ],
                      onChanged: (EstadoVenta? v) => setState(() => _estado = v),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: visibles.isEmpty
                    ? _vacio(todas.isEmpty)
                    : ListView.separated(
                        padding: const EdgeInsets.only(bottom: 96),
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

  Widget _tile(Venta venta) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: venta.anulada
            ? scheme.errorContainer
            : scheme.primaryContainer,
        child: Icon(
          venta.esCredito ? Icons.schedule : Icons.attach_money,
          color: venta.anulada ? scheme.onErrorContainer : scheme.onPrimaryContainer,
        ),
      ),
      title: Text('${venta.numeroFactura} · ${venta.clienteNombre}',
          maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        '${formatearFecha(venta.fecha)} · ${venta.tipoVenta.nombre} · ${venta.tipoEntrega.nombre}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          Text(
            formatearValor(venta.total),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          if (venta.anulada)
            Text('Anulada', style: TextStyle(color: scheme.error, fontSize: 11)),
        ],
      ),
      onTap: () => _abrir(venta),
    );
  }

  Widget _vacio(bool sinVentas) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.point_of_sale_outlined, size: 48),
            const SizedBox(height: 12),
            Text(
              sinVentas
                  ? 'Todavía no hay ventas registradas.'
                  : 'No se encontraron ventas con esos filtros.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

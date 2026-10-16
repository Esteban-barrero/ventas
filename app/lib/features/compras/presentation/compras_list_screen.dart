import 'package:flutter/material.dart';

import '../../../core/formato/fechas.dart';
import '../../auth/domain/usuario.dart';
import '../data/compras_repository.dart';
import '../domain/compra.dart';
import 'compra_detalle_screen.dart';
import 'compra_form_screen.dart';
import 'proveedores_list_screen.dart';

/// Listado de compras (spec 007, RF-02).
class ComprasListScreen extends StatefulWidget {
  const ComprasListScreen({super.key, required this.usuario, this.comprasRepository});

  final Usuario usuario;
  final ComprasRepository? comprasRepository;

  @override
  State<ComprasListScreen> createState() => _ComprasListScreenState();
}

class _ComprasListScreenState extends State<ComprasListScreen> {
  late final ComprasRepository _repo =
      widget.comprasRepository ?? ComprasRepository();

  final TextEditingController _busqueda = TextEditingController();
  EstadoCompra? _estado;

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

  Future<void> _nueva() async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => CompraFormScreen(usuario: widget.usuario),
      ),
    );
  }

  Future<void> _abrir(Compra compra) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => CompraDetalleScreen(
          compraId: compra.id,
          usuario: widget.usuario,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_empresaId.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Compras')),
        body: const Center(child: Text('No perteneces a ninguna empresa.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Compras'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Proveedores',
            icon: const Icon(Icons.storefront_outlined),
            onPressed: () => Navigator.of(context).push<void>(
              MaterialPageRoute<void>(
                builder: (_) => ProveedoresListScreen(usuario: widget.usuario),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _nueva,
        icon: const Icon(Icons.add),
        label: const Text('Nueva compra'),
      ),
      body: StreamBuilder<List<Compra>>(
        stream: _repo.escuchar(_empresaId),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final todas = snap.data ?? const <Compra>[];
          final visibles = ComprasRepository.filtrar(
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
                        hintText: 'Buscar por orden o proveedor',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<EstadoCompra?>(
                      initialValue: _estado,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Estado',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: <DropdownMenuItem<EstadoCompra?>>[
                        const DropdownMenuItem<EstadoCompra?>(
                          value: null,
                          child: Text('Todas'),
                        ),
                        for (final e in EstadoCompra.values)
                          DropdownMenuItem<EstadoCompra?>(
                            value: e,
                            child: Text(e.nombre),
                          ),
                      ],
                      onChanged: (EstadoCompra? v) => setState(() => _estado = v),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: visibles.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            todas.isEmpty
                                ? 'Todavía no hay compras registradas.'
                                : 'No se encontraron compras con esos filtros.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
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

  Widget _tile(Compra compra) {
    return ListTile(
      leading: const CircleAvatar(child: Icon(Icons.receipt_long_outlined)),
      title: Text('${compra.numeroOrden} · ${compra.proveedorNombre}',
          maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        '${formatearFecha(compra.fecha)} · ${compra.formaPago.nombre}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          Text(formatearValor(compra.valorTotal),
              style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(compra.estado.nombre, style: const TextStyle(fontSize: 11)),
        ],
      ),
      onTap: () => _abrir(compra),
    );
  }
}

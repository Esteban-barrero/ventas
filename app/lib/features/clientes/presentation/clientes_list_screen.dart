import 'package:flutter/material.dart';

import '../../auth/domain/permisos.dart';
import '../../auth/domain/usuario.dart';
import '../data/clientes_repository.dart';
import '../domain/cliente.dart';
import 'cliente_detalle_screen.dart';
import 'cliente_form_screen.dart';

/// Listado de clientes de la empresa (spec 004, RF-01, RF-07..RF-09).
class ClientesListScreen extends StatefulWidget {
  const ClientesListScreen({
    super.key,
    required this.usuario,
    this.clientesRepository,
  });

  final Usuario usuario;
  final ClientesRepository? clientesRepository;

  @override
  State<ClientesListScreen> createState() => _ClientesListScreenState();
}

class _ClientesListScreenState extends State<ClientesListScreen> {
  late final ClientesRepository _repo =
      widget.clientesRepository ?? ClientesRepository();

  final TextEditingController _busqueda = TextEditingController();
  EstadoCliente? _estado;
  Clasificacion? _clasificacion;

  String get _empresaId => widget.usuario.empresaId ?? '';
  bool get _puedeEditar => widget.usuario.puede(Permiso.clientesEditar);

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

  Future<void> _nuevo() async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => ClienteFormScreen(usuario: widget.usuario),
      ),
    );
  }

  Future<void> _abrir(Cliente cliente) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ClienteDetalleScreen(
          clienteId: cliente.id,
          usuario: widget.usuario,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_empresaId.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Clientes')),
        body: const Center(child: Text('No perteneces a ninguna empresa.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Clientes')),
      floatingActionButton: _puedeEditar
          ? FloatingActionButton.extended(
              onPressed: _nuevo,
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('Nuevo cliente'),
            )
          : null,
      body: StreamBuilder<List<Cliente>>(
        stream: _repo.escuchar(_empresaId),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Text('No se pudieron cargar los clientes: ${snap.error}'),
            );
          }
          final todos = snap.data ?? const <Cliente>[];
          final visibles = ClientesRepository.filtrar(
            todos,
            busqueda: _busqueda.text,
            estado: _estado,
            clasificacion: _clasificacion,
          );
          return Column(
            children: <Widget>[
              _filtros(),
              Expanded(
                child: visibles.isEmpty
                    ? _vacio(todos.isEmpty)
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

  Widget _filtros() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        children: <Widget>[
          TextField(
            controller: _busqueda,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Buscar por nombre, cédula o teléfono',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              Expanded(
                child: DropdownButtonFormField<EstadoCliente?>(
                  initialValue: _estado,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Estado',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: <DropdownMenuItem<EstadoCliente?>>[
                    const DropdownMenuItem<EstadoCliente?>(
                      value: null,
                      child: Text('Todos'),
                    ),
                    for (final e in EstadoCliente.values)
                      DropdownMenuItem<EstadoCliente?>(
                        value: e,
                        child: Text(e.nombre),
                      ),
                  ],
                  onChanged: (EstadoCliente? v) => setState(() => _estado = v),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<Clasificacion?>(
                  initialValue: _clasificacion,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Clasificación',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: <DropdownMenuItem<Clasificacion?>>[
                    const DropdownMenuItem<Clasificacion?>(
                      value: null,
                      child: Text('Todas'),
                    ),
                    for (final c in Clasificacion.values)
                      DropdownMenuItem<Clasificacion?>(
                        value: c,
                        child: Text(c.nombre),
                      ),
                  ],
                  onChanged: (Clasificacion? v) =>
                      setState(() => _clasificacion = v),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tile(Cliente cliente) {
    return ListTile(
      leading: CircleAvatar(
        child: Text(_iniciales(cliente.nombreCompleto)),
      ),
      title: Text(cliente.nombreCompleto),
      subtitle: Text(
        '${cliente.cedula} · ${cliente.telefono}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          _Chip(texto: cliente.clasificacion.nombre),
          const SizedBox(height: 4),
          _Chip(
            texto: cliente.estado.nombre,
            color: _colorEstado(cliente.estado),
          ),
        ],
      ),
      onTap: () => _abrir(cliente),
    );
  }

  Widget _vacio(bool sinClientes) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.people_outline, size: 48),
            const SizedBox(height: 12),
            Text(
              sinClientes
                  ? 'Todavía no hay clientes registrados.'
                  : 'No se encontraron clientes con esos filtros.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  static String _iniciales(String texto) {
    final partes =
        texto.trim().split(RegExp(r'[\s.]+')).where((p) => p.isNotEmpty);
    if (partes.isEmpty) return '?';
    return partes.take(2).map((p) => p[0].toUpperCase()).join();
  }

  static Color _colorEstado(EstadoCliente estado) => switch (estado) {
        EstadoCliente.activo => Colors.green,
        EstadoCliente.inactivo => Colors.grey,
        EstadoCliente.moroso => Colors.red,
      };
}

class _Chip extends StatelessWidget {
  const _Chip({required this.texto, this.color});

  final String texto;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fondo = color ?? scheme.secondaryContainer;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: fondo.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: fondo.withValues(alpha: 0.6)),
      ),
      child: Text(
        texto,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fondo),
      ),
    );
  }
}

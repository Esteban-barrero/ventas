import 'package:flutter/material.dart';

import '../../../core/formato/fechas.dart';
import '../../auth/domain/permisos.dart';
import '../../auth/domain/usuario.dart';
import '../../empresas/presentation/widgets/tarjeta_datos.dart';
import '../data/clientes_repository.dart';
import '../data/mapas.dart';
import '../domain/cliente.dart';
import 'cliente_form_screen.dart';

/// Detalle de un cliente (spec 004, T024): datos, dirección, ubicación GPS con
/// apertura en mapas, clasificación, estado y (cuando existan) historial.
class ClienteDetalleScreen extends StatefulWidget {
  const ClienteDetalleScreen({
    super.key,
    required this.clienteId,
    required this.usuario,
    this.clientesRepository,
    this.mapas,
  });

  final String clienteId;
  final Usuario usuario;
  final ClientesRepository? clientesRepository;
  final Mapas? mapas;

  @override
  State<ClienteDetalleScreen> createState() => _ClienteDetalleScreenState();
}

class _ClienteDetalleScreenState extends State<ClienteDetalleScreen> {
  late final ClientesRepository _repo =
      widget.clientesRepository ?? ClientesRepository();
  late final Mapas _mapas = widget.mapas ?? const Mapas();

  Cliente? _cliente;
  bool _cargando = true;
  String? _error;

  bool get _esClientePropio =>
      widget.usuario.rolesTipados.any((r) => r.id == 'cliente');

  bool get _puedeEditar =>
      widget.usuario.puede(Permiso.clientesEditar) || _esClientePropio;

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
      final cliente = await _repo.obtener(widget.clienteId);
      if (!mounted) return;
      setState(() {
        _cliente = cliente;
        _cargando = false;
        if (cliente == null) _error = 'El cliente ya no existe.';
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

  Future<void> _editar() async {
    final cliente = _cliente;
    if (cliente == null) return;
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => ClienteFormScreen(
          usuario: widget.usuario,
          cliente: cliente,
        ),
      ),
    );
    await _cargar();
  }

  Future<void> _cambiarEstado(EstadoCliente estado) async {
    final cliente = _cliente;
    if (cliente == null) return;
    try {
      await _repo.cambiarEstado(cliente.id, estado, empresaId: cliente.empresaId);
      await _cargar();
      if (mounted) _avisar('Estado actualizado a "${estado.nombre}".');
    } catch (e) {
      if (mounted) _avisar('No se pudo cambiar: $e', error: true);
    }
  }

  Future<void> _abrirMapa({required bool waze}) async {
    final u = _cliente?.ubicacionGPS;
    if (u == null) return;
    final ok = waze
        ? await _mapas.waze(u.latitud, u.longitud)
        : await _mapas.googleMaps(u.latitud, u.longitud);
    if (!ok && mounted) {
      _avisar('No se pudo abrir la app de mapas.', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cliente = _cliente;
    return Scaffold(
      appBar: AppBar(
        title: Text(cliente?.nombreCompleto ?? 'Cliente'),
        actions: <Widget>[
          if (cliente != null && _puedeEditar)
            IconButton(
              tooltip: 'Editar',
              icon: const Icon(Icons.edit_outlined),
              onPressed: _editar,
            ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(_error!, textAlign: TextAlign.center),
                  ),
                )
              : _cuerpo(cliente!),
    );
  }

  Widget _cuerpo(Cliente cliente) {
    final theme = Theme.of(context);
    final u = cliente.ubicacionGPS;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        TarjetaDatos(
          titulo: 'Datos',
          icono: Icons.person_outline,
          filas: <FilaDato>[
            FilaDato('Nombre', cliente.nombreCompleto),
            FilaDato(cliente.tipoDocumento.nombre, cliente.cedula),
            FilaDato('Teléfono', cliente.telefono),
            if (cliente.telefonoAlterno.isNotEmpty)
              FilaDato('Teléfono alterno', cliente.telefonoAlterno),
            if (cliente.correo.isNotEmpty) FilaDato('Correo', cliente.correo),
            FilaDato('Clasificación', cliente.clasificacion.nombre),
          ],
        ),
        const SizedBox(height: 12),
        TarjetaDatos(
          titulo: 'Dirección',
          icono: Icons.home_outlined,
          filas: <FilaDato>[
            FilaDato('Departamento',
                cliente.direccion.departamento.isEmpty
                    ? '—'
                    : cliente.direccion.departamento),
            FilaDato(
                'Ciudad',
                cliente.direccion.ciudad.isEmpty
                    ? '—'
                    : cliente.direccion.ciudad),
            FilaDato('Dirección',
                cliente.direccion.direccion.isEmpty
                    ? '—'
                    : cliente.direccion.direccion),
            if (cliente.direccion.barrio.isNotEmpty)
              FilaDato('Barrio', cliente.direccion.barrio),
            if (cliente.direccion.referencia.isNotEmpty)
              FilaDato('Referencia', cliente.direccion.referencia),
            if (cliente.contacto.isNotEmpty)
              FilaDato('Persona de contacto', cliente.contacto),
          ],
        ),
        const SizedBox(height: 12),
        TarjetaDatos(
          titulo: 'Estado y crédito',
          icono: Icons.verified_user_outlined,
          filas: <FilaDato>[
            FilaDato('Estado', cliente.estado.nombre),
            FilaDato('Límite de crédito', formatearValor(cliente.creditoLimite)),
            FilaDato('Saldo', formatearValor(cliente.creditoSaldo)),
          ],
        ),
        if (cliente.observaciones.isNotEmpty) ...<Widget>[
          const SizedBox(height: 12),
          TarjetaDatos(
            titulo: 'Observaciones',
            icono: Icons.notes_outlined,
            filas: <FilaDato>[FilaDato('Notas', cliente.observaciones)],
          ),
        ],
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    const Icon(Icons.location_on_outlined),
                    const SizedBox(width: 8),
                    Text('Ubicación GPS',
                        style: theme.textTheme.titleMedium),
                  ],
                ),
                const SizedBox(height: 8),
                if (u == null)
                  const Text('Sin ubicación registrada.')
                else ...<Widget>[
                  Text(u.direccionAproximada.isEmpty
                      ? u.coordenadas
                      : '${u.direccionAproximada}\n${u.coordenadas}'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: <Widget>[
                      FilledButton.tonalIcon(
                        onPressed: () => _abrirMapa(waze: false),
                        icon: const Icon(Icons.map_outlined),
                        label: const Text('Google Maps'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _abrirMapa(waze: true),
                        icon: const Icon(Icons.navigation_outlined),
                        label: const Text('Waze'),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        const TarjetaDatos(
          titulo: 'Historial',
          icono: Icons.history,
          filas: <FilaDato>[
            FilaDato('Compras', 'Disponible con Ventas (spec 005)'),
            FilaDato('Pedidos', 'Disponible con Pedidos (spec 010)'),
          ],
        ),
        const SizedBox(height: 24),
        if (_puedeEditar) ...<Widget>[
          Text('Estado del cliente', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: <Widget>[
              for (final e in EstadoCliente.values)
                ChoiceChip(
                  label: Text(e.nombre),
                  selected: cliente.estado == e,
                  onSelected: (_) => _cambiarEstado(e),
                ),
            ],
          ),
        ],
        const SizedBox(height: 32),
      ],
    );
  }
}

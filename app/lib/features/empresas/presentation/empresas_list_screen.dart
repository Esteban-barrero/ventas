import 'package:flutter/material.dart';

import '../../../core/formato/fechas.dart';
import '../data/empresas_repository.dart';
import '../data/planes_repository.dart';
import '../domain/empresa.dart';
import '../domain/licencia.dart';
import 'empresa_detalle_screen.dart';
import 'empresa_form_screen.dart';
import 'tablero_vencimientos_screen.dart';
import 'widgets/estado_licencia_chip.dart';
import 'widgets/logo_empresa.dart';

/// Listado de empresas (solo Super Admin). Ver spec 002, T020.
class EmpresasListScreen extends StatefulWidget {
  const EmpresasListScreen({
    super.key,
    this.repository,
    this.planesRepository,
  });

  /// Permiten inyectar repositorios en las pruebas.
  final EmpresasRepository? repository;
  final PlanesRepository? planesRepository;

  @override
  State<EmpresasListScreen> createState() => _EmpresasListScreenState();
}

class _EmpresasListScreenState extends State<EmpresasListScreen> {
  late final EmpresasRepository _repo =
      widget.repository ?? EmpresasRepository();
  late final PlanesRepository _planesRepo =
      widget.planesRepository ?? PlanesRepository();

  late Future<List<Empresa>> _futuro;
  String _busqueda = '';

  @override
  void initState() {
    super.initState();
    _sembrarPlanes();
    _cargar();
  }

  /// Siembra los planes por defecto la primera vez (T003). Mejor esfuerzo: si
  /// falla (sin permisos o sin conexión) no se interrumpe el listado.
  Future<void> _sembrarPlanes() async {
    try {
      await _planesRepo.sembrarPorDefecto();
    } catch (_) {
      // Los planes por defecto del cliente siguen disponibles.
    }
  }

  void _cargar() {
    setState(() {
      _futuro = _repo.listar();
    });
  }

  List<Empresa> _filtrar(List<Empresa> empresas) {
    final texto = _busqueda.trim().toLowerCase();
    if (texto.isEmpty) return empresas;
    return empresas
        .where((Empresa e) =>
            e.nombre.toLowerCase().contains(texto) ||
            e.nit.toLowerCase().contains(texto))
        .toList(growable: false);
  }

  Future<void> _nuevaEmpresa() async {
    final creada = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => EmpresaFormScreen(repository: _repo),
      ),
    );
    if (creada == true) _cargar();
  }

  Future<void> _abrirDetalle(Empresa empresa) async {
    final cambio = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => EmpresaDetalleScreen(
          empresaId: empresa.id,
          repository: _repo,
        ),
      ),
    );
    if (cambio == true) _cargar();
  }

  void _abrirTablero() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => TableroVencimientosScreen(repository: _repo),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Empresas'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Tablero de vencimientos',
            icon: const Icon(Icons.dashboard_outlined),
            onPressed: _abrirTablero,
          ),
          IconButton(
            tooltip: 'Actualizar',
            icon: const Icon(Icons.refresh),
            onPressed: _cargar,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _nuevaEmpresa,
        icon: const Icon(Icons.add_business_outlined),
        label: const Text('Nueva empresa'),
      ),
      body: FutureBuilder<List<Empresa>>(
        future: _futuro,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _ErrorCarga(
              error: snapshot.error!,
              onReintentar: _cargar,
            );
          }

          final empresas = snapshot.data ?? const <Empresa>[];
          if (empresas.isEmpty) return _SinEmpresas(onCrear: _nuevaEmpresa);

          final visibles = _filtrar(empresas);

          return Column(
            children: <Widget>[
              _Resumen(empresas: empresas),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: TextField(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Buscar por nombre o NIT',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (String valor) =>
                      setState(() => _busqueda = valor),
                ),
              ),
              Expanded(
                child: visibles.isEmpty
                    ? const Center(child: Text('Sin resultados.'))
                    : ListView.separated(
                        padding: const EdgeInsets.only(bottom: 96),
                        itemCount: visibles.length,
                        separatorBuilder: (_, _) =>
                            const Divider(height: 1),
                        itemBuilder: (context, i) => _EmpresaTile(
                          empresa: visibles[i],
                          onTap: () => _abrirDetalle(visibles[i]),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Resumen de conteos por estado (RF-10).
class _Resumen extends StatelessWidget {
  const _Resumen({required this.empresas});

  final List<Empresa> empresas;

  @override
  Widget build(BuildContext context) {
    final ahora = DateTime.now();
    var activas = 0, porVencer = 0, vencidas = 0, suspendidas = 0;

    for (final e in empresas) {
      switch (e.estadoLicencia(ahora)) {
        case EstadoLicenciaNegocio.activa:
        case EstadoLicenciaNegocio.prueba:
          activas++;
        case EstadoLicenciaNegocio.porVencer:
          porVencer++;
        case EstadoLicenciaNegocio.vencida:
          vencidas++;
        case EstadoLicenciaNegocio.suspendida:
          suspendidas++;
      }
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: <Widget>[
          _Contador(etiqueta: 'Activas', valor: activas, color: const Color(0xFF2E7D32)),
          _Contador(etiqueta: 'Por vencer', valor: porVencer, color: const Color(0xFFE65100)),
          _Contador(etiqueta: 'Vencidas', valor: vencidas, color: Theme.of(context).colorScheme.error),
          _Contador(etiqueta: 'Suspendidas', valor: suspendidas, color: const Color(0xFF455A64)),
        ],
      ),
    );
  }
}

class _Contador extends StatelessWidget {
  const _Contador({
    required this.etiqueta,
    required this.valor,
    required this.color,
  });

  final String etiqueta;
  final int valor;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Card(
        elevation: 0,
        color: color.withValues(alpha: 0.10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
          child: Column(
            children: <Widget>[
              Text(
                '$valor',
                style: theme.textTheme.titleLarge
                    ?.copyWith(color: color, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(
                etiqueta,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmpresaTile extends StatelessWidget {
  const _EmpresaTile({required this.empresa, required this.onTap});

  final Empresa empresa;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ahora = DateTime.now();

    return ListTile(
      onTap: onTap,
      leading: LogoEmpresa(empresa: empresa),
      title: Text(
        empresa.nombre,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const SizedBox(height: 2),
          Text(
            'NIT ${empresa.nit.isEmpty ? "—" : empresa.nit} · '
            '${describirDiasRestantes(empresa.licencia.diasRestantes(ahora))}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: EstadoLicenciaChip(
              estado: empresa.estadoLicencia(ahora),
              compacto: true,
            ),
          ),
        ],
      ),
      isThreeLine: true,
      trailing: const Icon(Icons.chevron_right),
    );
  }
}

class _SinEmpresas extends StatelessWidget {
  const _SinEmpresas({required this.onCrear});

  final VoidCallback onCrear;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.business_outlined, size: 64),
            const SizedBox(height: 16),
            const Text(
              'Todavía no hay empresas',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Crea la primera empresa para empezar.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onCrear,
              icon: const Icon(Icons.add_business_outlined),
              label: const Text('Nueva empresa'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorCarga extends StatelessWidget {
  const _ErrorCarga({required this.error, required this.onReintentar});

  final Object error;
  final VoidCallback onReintentar;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.cloud_off_outlined, size: 48, color: scheme.error),
            const SizedBox(height: 16),
            const Text('No se pudieron cargar las empresas'),
            const SizedBox(height: 8),
            Text(
              '$error',
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: onReintentar,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

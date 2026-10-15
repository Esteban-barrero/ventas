import 'package:flutter/material.dart';

import '../../../core/formato/fechas.dart';
import '../data/empresas_repository.dart';
import '../domain/empresa.dart';
import '../domain/resumen_empresas.dart';
import 'empresa_detalle_screen.dart';
import 'widgets/estado_licencia_chip.dart';
import 'widgets/logo_empresa.dart';

/// Tablero de vencimientos (spec 002, T023 / RF-10).
///
/// Muestra las empresas agrupadas: por vencer, vencidas, suspendidas,
/// en prueba y activas.
class TableroVencimientosScreen extends StatefulWidget {
  const TableroVencimientosScreen({super.key, this.repository});

  final EmpresasRepository? repository;

  @override
  State<TableroVencimientosScreen> createState() =>
      _TableroVencimientosScreenState();
}

class _TableroVencimientosScreenState extends State<TableroVencimientosScreen> {
  late final EmpresasRepository _repo =
      widget.repository ?? EmpresasRepository();

  late Future<ResumenEmpresas> _futuro;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  void _cargar() {
    setState(() {
      _futuro = _repo.resumen();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tablero de vencimientos'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Actualizar',
            icon: const Icon(Icons.refresh),
            onPressed: _cargar,
          ),
        ],
      ),
      body: FutureBuilder<ResumenEmpresas>(
        future: _futuro,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text('No se pudo cargar el tablero: ${snapshot.error}'),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: _cargar,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            );
          }

          final resumen = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              _TarjetasResumen(resumen: resumen),
              const SizedBox(height: 8),
              _Grupo(
                titulo: 'Por vencer',
                empresas: resumen.porVencer,
                onAbrir: _abrirDetalle,
                vacio: 'Ninguna empresa está por vencer.',
              ),
              _Grupo(
                titulo: 'Vencidas',
                empresas: resumen.vencidas,
                onAbrir: _abrirDetalle,
                vacio: 'Ninguna licencia vencida.',
              ),
              _Grupo(
                titulo: 'Suspendidas',
                empresas: resumen.suspendidas,
                onAbrir: _abrirDetalle,
                vacio: 'Ninguna empresa suspendida.',
              ),
              _Grupo(
                titulo: 'En prueba',
                empresas: resumen.enPrueba,
                onAbrir: _abrirDetalle,
                vacio: 'Ninguna empresa en prueba.',
              ),
              _Grupo(
                titulo: 'Activas',
                empresas: resumen.activas,
                onAbrir: _abrirDetalle,
                vacio: 'Ninguna empresa activa.',
              ),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
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
}

class _TarjetasResumen extends StatelessWidget {
  const _TarjetasResumen({required this.resumen});

  final ResumenEmpresas resumen;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: <Widget>[
        _Mini('Por vencer', resumen.porVencer.length, const Color(0xFFE65100)),
        _Mini('Vencidas', resumen.vencidas.length,
            Theme.of(context).colorScheme.error),
        _Mini('Suspendidas', resumen.suspendidas.length,
            const Color(0xFF455A64)),
        _Mini('Activas', resumen.activas.length, const Color(0xFF2E7D32)),
        _Mini('En prueba', resumen.enPrueba.length, const Color(0xFF6A1B9A)),
      ],
    );
  }
}

class _Mini extends StatelessWidget {
  const _Mini(this.etiqueta, this.valor, this.color);

  final String etiqueta;
  final int valor;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 132,
      child: Card(
        elevation: 0,
        color: color.withValues(alpha: 0.10),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                '$valor',
                style: theme.textTheme.headlineSmall
                    ?.copyWith(color: color, fontWeight: FontWeight.bold),
              ),
              Text(etiqueta, style: theme.textTheme.labelMedium),
            ],
          ),
        ),
      ),
    );
  }
}

class _Grupo extends StatelessWidget {
  const _Grupo({
    required this.titulo,
    required this.empresas,
    required this.onAbrir,
    required this.vacio,
  });

  final String titulo;
  final List<Empresa> empresas;
  final void Function(Empresa) onAbrir;
  final String vacio;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '$titulo (${empresas.length})',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (empresas.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                vacio,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            )
          else
            for (final empresa in empresas)
              Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  onTap: () => onAbrir(empresa),
                  leading: LogoEmpresa(empresa: empresa, radio: 18),
                  title: Text(empresa.nombre),
                  subtitle: Text(
                    describirDiasRestantes(
                      empresa.licencia.diasRestantes(DateTime.now()),
                    ),
                  ),
                  trailing: EstadoLicenciaChip(
                    estado: empresa.estadoLicencia(DateTime.now()),
                    compacto: true,
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

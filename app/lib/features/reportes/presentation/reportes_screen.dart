import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/archivos/descargar_texto.dart';
import '../../../core/formato/fechas.dart';
import '../../auth/domain/usuario.dart';
import '../data/reportes_repository.dart';
import '../domain/reportes.dart';

/// Pantalla de **Reportes** (spec 015): panel con KPIs y resúmenes de ventas,
/// utilidad, inventario, cartera, dinero y pedidos, con filtro por fechas.
class ReportesScreen extends StatefulWidget {
  const ReportesScreen({
    super.key,
    required this.usuario,
    this.reportesRepository,
  });

  final Usuario usuario;
  final ReportesRepository? reportesRepository;

  @override
  State<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends State<ReportesScreen> {
  late final ReportesRepository _repo =
      widget.reportesRepository ?? ReportesRepository();

  DatosReportes? _datos;
  bool _cargando = true;
  String? _error;
  RangoFechas _rango = RangoFechas.mes();
  String _preset = 'Mes';

  String get _empresaId => widget.usuario.empresaId ?? '';

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
      final datos = await _repo.cargar(_empresaId);
      if (!mounted) return;
      setState(() {
        _datos = datos;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudieron cargar los reportes: $e';
        _cargando = false;
      });
    }
  }

  /// Exporta el panel a **CSV** (spec 015, RF-10). En web descarga el archivo;
  /// en otras plataformas copia el contenido al portapapeles.
  Future<void> _exportarCsv() async {
    final datos = _datos;
    if (datos == null) return;
    final rv = calcularResumenVentas(datos.ventas, _rango);
    final ri = calcularResumenInventario(datos.productos);
    final rc = calcularResumenCartera(datos.creditos);
    final rd = calcularResumenDinero(datos.movimientos, _rango);
    final rp = calcularResumenPedidos(datos.pedidos, _rango);

    final b = StringBuffer()
      ..writeln('Reporte;Valor')
      ..writeln('Ventas;${rv.total}')
      ..writeln('Contado;${rv.contado}')
      ..writeln('Credito;${rv.credito}')
      ..writeln('Utilidad;${rv.utilidad}')
      ..writeln('Numero de ventas;${rv.numero}')
      ..writeln('Cartera;${rc.total}')
      ..writeln('Cartera vencida;${rc.vencida}')
      ..writeln('Clientes en mora;${rc.morosos}')
      ..writeln('Valorizacion inventario;${ri.valorizacion}')
      ..writeln('Bajo stock;${ri.bajoStock}')
      ..writeln('Agotados;${ri.agotados}')
      ..writeln('Ingresos;${rd.ingresos}')
      ..writeln('Egresos;${rd.egresos}')
      ..writeln('Neto;${rd.neto}')
      ..writeln('Pedidos pendientes;${rp.pendientes}')
      ..writeln();
    b.writeln('Producto;Unidades;Utilidad');
    for (final p in rv.topProductos) {
      b.writeln('${p.nombre};${p.unidades};${p.utilidad}');
    }

    final csv = b.toString();
    final nombre =
        'reporte_${DateTime.now().toIso8601String().substring(0, 10)}.csv';
    final descargado =
        await descargarTexto(nombre, csv, mime: 'text/csv');
    if (!mounted) return;
    if (descargado) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Descargado: $nombre')),
      );
    } else {
      await Clipboard.setData(ClipboardData(text: csv));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('CSV copiado al portapapeles.')),
        );
      }
    }
  }

  void _cambiarRango(String preset) {
    setState(() {
      _preset = preset;
      _rango = switch (preset) {
        'Hoy' => RangoFechas.hoy(),
        'Semana' => RangoFechas.semana(),
        'Año' => RangoFechas.anio(),
        'Todo' => RangoFechas.todo,
        _ => RangoFechas.mes(),
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_empresaId.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Reportes')),
        body: const Center(child: Text('No perteneces a ninguna empresa.')),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Exportar CSV',
            icon: const Icon(Icons.download_outlined),
            onPressed: _cargando || _datos == null ? null : _exportarCsv,
          ),
          IconButton(
            tooltip: 'Actualizar',
            icon: const Icon(Icons.refresh),
            onPressed: _cargando ? null : _cargar,
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
              : _cuerpo(_datos!),
    );
  }

  Widget _cuerpo(DatosReportes datos) {
    final rv = calcularResumenVentas(datos.ventas, _rango);
    final ri = calcularResumenInventario(datos.productos);
    final rc = calcularResumenCartera(datos.creditos);
    final rd = calcularResumenDinero(datos.movimientos, _rango);
    final rp = calcularResumenPedidos(datos.pedidos, _rango);
    final tema = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Wrap(
          spacing: 8,
          children: <Widget>[
            for (final p in <String>['Hoy', 'Semana', 'Mes', 'Año', 'Todo'])
              ChoiceChip(
                label: Text(p),
                selected: _preset == p,
                onSelected: (_) => _cambiarRango(p),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: <Widget>[
            _kpi('Ventas', formatearValor(rv.total), Icons.point_of_sale_outlined),
            _kpi('Utilidad', formatearValor(rv.utilidad), Icons.trending_up),
            _kpi('N.º ventas', '${rv.numero}', Icons.receipt_long_outlined),
            _kpi('Cartera', formatearValor(rc.total), Icons.request_quote_outlined),
            _kpi('Inventario', formatearValor(ri.valorizacion), Icons.warehouse_outlined),
          ],
        ),
        const SizedBox(height: 16),
        _seccion(tema, 'Gráficos'),
        _tarjeta(<Widget>[
          ..._grafico('Ventas por medio de pago', rv.porMedio,
              tema.colorScheme.primary),
          ..._grafico('Ventas por vendedor', rv.porVendedor,
              tema.colorScheme.secondary),
          ..._grafico(
            'Utilidad por producto',
            <String, double>{
              for (final p in rv.topProductos)
                '${p.unidades} × ${p.nombre}': p.utilidad,
            },
            tema.colorScheme.tertiary,
          ),
        ]),
        _seccion(tema, 'Ventas'),
        _tarjeta(<Widget>[
          _fila('Total', formatearValor(rv.total), negrita: true),
          _fila('Contado', formatearValor(rv.contado)),
          _fila('Crédito', formatearValor(rv.credito)),
        ]),
        _seccion(tema, 'Inventario'),
        _tarjeta(<Widget>[
          _fila('Valorización', formatearValor(ri.valorizacion)),
          _fila('Productos', '${ri.productos}'),
          _fila('Bajo stock', '${ri.bajoStock}'),
          _fila('Agotados', '${ri.agotados}'),
        ]),
        _seccion(tema, 'Cartera'),
        _tarjeta(<Widget>[
          _fila('Saldo por cobrar', formatearValor(rc.total), negrita: true),
          _fila('Vencida', formatearValor(rc.vencida)),
          _fila('Clientes en mora', '${rc.morosos}'),
          _fila('Créditos activos', '${rc.creditos}'),
        ]),
        _seccion(tema, 'Dinero (caja/tesorería)'),
        _tarjeta(<Widget>[
          _fila('Ingresos', formatearValor(rd.ingresos)),
          _fila('Egresos', formatearValor(rd.egresos)),
          _fila('Neto', formatearValor(rd.neto), negrita: true),
          ..._barras('Ingresos por medio', rd.porMedio, tema.colorScheme.primary),
        ]),
        _seccion(tema, 'Pedidos'),
        _tarjeta(<Widget>[
          _fila('Total', '${rp.total}', negrita: true),
          _fila('Pendientes', '${rp.pendientes}'),
          _fila('Confirmados', '${rp.confirmados}'),
          _fila('Cancelados', '${rp.cancelados}'),
        ]),
        const SizedBox(height: 32),
      ],
    );
  }

  /// Un gráfico con su título; avisa si no hay datos en el período.
  List<Widget> _grafico(
    String titulo,
    Map<String, double> valores,
    Color color,
  ) {
    final tema = Theme.of(context);
    final header = Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(titulo,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
    );
    if (valores.isEmpty) {
      return <Widget>[
        header,
        Text('Sin datos para graficar en el período.',
            style: tema.textTheme.bodySmall),
        const SizedBox(height: 10),
      ];
    }
    final max = valores.values.reduce((double a, double b) => a > b ? a : b);
    final ordenados = valores.entries.toList()
      ..sort((MapEntry<String, double> a, MapEntry<String, double> b) =>
          b.value.compareTo(a.value));
    return <Widget>[
      header,
      for (final e in ordenados.take(8)) _barra(e.key, e.value, max, color),
      const SizedBox(height: 10),
    ];
  }

  /// Barras horizontales con el valor de cada elemento.
  List<Widget> _barras(String titulo, Map<String, double> valores, Color color) {
    if (valores.isEmpty) return const <Widget>[];
    final ordenados = valores.entries.toList()
      ..sort((MapEntry<String, double> a, MapEntry<String, double> b) =>
          b.value.compareTo(a.value));
    final max = ordenados.first.value;
    return <Widget>[
      const Divider(),
      Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(titulo,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
      ),
      for (final e in ordenados) _barra(e.key, e.value, max, color),
    ];
  }

  Widget _barra(String etiqueta, double valor, double max, Color color) {
    final factor = max <= 0 ? 0.0 : (valor / max).clamp(0.0, 1.0);
    final tema = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(etiqueta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: tema.textTheme.bodySmall),
              ),
              Text(formatearValor(valor), style: tema.textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 3),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: factor,
              minHeight: 8,
              backgroundColor: tema.colorScheme.surfaceContainerHighest,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _kpi(String titulo, String valor, IconData icono) {
    final tema = Theme.of(context);
    return SizedBox(
      width: 150,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(icono, size: 20, color: tema.colorScheme.primary),
              const SizedBox(height: 6),
              Text(titulo, style: tema.textTheme.bodySmall),
              const SizedBox(height: 2),
              Text(valor,
                  style: tema.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _seccion(ThemeData tema, String titulo) => Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 6),
        child: Text(titulo, style: tema.textTheme.titleMedium),
      );

  Widget _tarjeta(List<Widget> filas) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: filas,
          ),
        ),
      );

  Widget _fila(String etiqueta, String valor, {bool negrita = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: <Widget>[
          Expanded(child: Text(etiqueta)),
          Text(
            valor,
            style: TextStyle(
              fontWeight: negrita ? FontWeight.bold : FontWeight.normal,
              fontSize: negrita ? 16 : null,
            ),
          ),
        ],
      ),
    );
  }
}

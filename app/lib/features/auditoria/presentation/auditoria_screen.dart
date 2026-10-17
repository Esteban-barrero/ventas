import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/archivos/descargar_texto.dart';
import '../../../core/formato/fechas.dart';
import '../../auth/domain/usuario.dart';
import '../../empresas/data/empresas_repository.dart';
import '../../empresas/domain/empresa.dart';
import '../data/auditoria_repository.dart';
import '../domain/auditoria.dart';

/// Consulta de **auditoría** (spec 012): quién cambió qué, cuándo y de qué valor
/// a cuál. Los registros son de solo lectura.
class AuditoriaScreen extends StatefulWidget {
  const AuditoriaScreen({
    super.key,
    required this.usuario,
    this.auditoriaRepository,
  });

  final Usuario usuario;
  final AuditoriaRepository? auditoriaRepository;

  @override
  State<AuditoriaScreen> createState() => _AuditoriaScreenState();
}

class _AuditoriaScreenState extends State<AuditoriaScreen> {
  late final AuditoriaRepository _repo =
      widget.auditoriaRepository ?? AuditoriaRepository();
  late final EmpresasRepository _empresasRepo = EmpresasRepository();

  final TextEditingController _busqueda = TextEditingController();
  String? _operacion;
  String? _tabla;
  DateTime? _desde;
  DateTime? _hasta;

  /// Super Admin: empresas a elegir (`null` = todas).
  List<Empresa> _empresas = const <Empresa>[];
  String? _empresaFiltro;

  bool get _esSuper => widget.usuario.esSuperAdmin;
  String get _empresaUsuario => widget.usuario.empresaId ?? '';

  @override
  void initState() {
    super.initState();
    _busqueda.addListener(() => setState(() {}));
    if (_esSuper) _cargarEmpresas();
  }

  Future<void> _cargarEmpresas() async {
    try {
      final lista = await _empresasRepo.listar();
      if (!mounted) return;
      setState(() {
        _empresas = lista
          ..sort((Empresa a, Empresa b) =>
              a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));
      });
    } catch (_) {
      // Si no se puede leer, queda "Todas".
    }
  }

  /// Stream de auditoría según el rol y la empresa seleccionada.
  Stream<List<RegistroAuditoria>> _stream() {
    if (!_esSuper) return _repo.escuchar(_empresaUsuario);
    final id = _empresaFiltro;
    return (id == null || id.isEmpty)
        ? _repo.escucharTodos()
        : _repo.escuchar(id);
  }

  @override
  void dispose() {
    _busqueda.dispose();
    super.dispose();
  }

  Future<void> _elegirFecha({required bool esDesde}) async {
    final hoy = DateTime.now();
    final elegida = await showDatePicker(
      context: context,
      initialDate: (esDesde ? _desde : _hasta) ?? hoy,
      firstDate: DateTime(2020),
      lastDate: hoy,
    );
    if (elegida == null) return;
    setState(() {
      if (esDesde) {
        _desde = elegida;
      } else {
        _hasta = elegida;
      }
    });
  }

  void _limpiar() {
    setState(() {
      _busqueda.clear();
      _operacion = null;
      _tabla = null;
      _desde = null;
      _hasta = null;
    });
  }

  /// Exporta los registros filtrados a CSV (spec 012, RF-09).
  Future<void> _exportar() async {
    final registros = _esSuper
        ? ((_empresaFiltro == null || _empresaFiltro!.isEmpty)
            ? await _repo.listarTodos(
                busqueda: _busqueda.text,
                operacion: _operacion,
                tabla: _tabla,
                desde: _desde,
                hasta: _hasta,
              )
            : await _repo.listar(
                _empresaFiltro!,
                busqueda: _busqueda.text,
                operacion: _operacion,
                tabla: _tabla,
                desde: _desde,
                hasta: _hasta,
              ))
        : await _repo.listar(
            _empresaUsuario,
            busqueda: _busqueda.text,
            operacion: _operacion,
            tabla: _tabla,
            desde: _desde,
            hasta: _hasta,
          );
    final b = StringBuffer()
      ..writeln('Fecha;Usuario;Operacion;Tabla;Documento;Campo;Viejo;Nuevo');
    for (final r in registros) {
      b.writeln(
        '${r.fecha?.toIso8601String() ?? ''};${r.usuario};${r.operacion};'
        '${r.tabla};${r.documentoId};${r.campo};'
        '${textoValor(r.valorViejo)};${textoValor(r.valorNuevo)}',
      );
    }
    final csv = b.toString();
    final nombre =
        'auditoria_${DateTime.now().toIso8601String().substring(0, 10)}.csv';
    final ok = await descargarTexto(nombre, csv, mime: 'text/csv');
    if (!mounted) return;
    if (ok) {
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

  @override
  Widget build(BuildContext context) {
    if (!_esSuper && _empresaUsuario.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Auditoría')),
        body: const Center(child: Text('No perteneces a ninguna empresa.')),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Auditoría'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Exportar CSV',
            icon: const Icon(Icons.download_outlined),
            onPressed: _exportar,
          ),
        ],
      ),
      body: StreamBuilder<List<RegistroAuditoria>>(
        stream: _stream(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final todos = snap.data ?? const <RegistroAuditoria>[];
          final tablas = todos
              .map((RegistroAuditoria r) => r.tabla)
              .where((String t) => t.isNotEmpty)
              .toSet()
              .toList()
            ..sort();
          final visibles = AuditoriaRepository.filtrar(
            todos,
            busqueda: _busqueda.text,
            operacion: _operacion,
            tabla: _tabla,
            desde: _desde,
            hasta: _hasta,
          );

          return Column(
            children: <Widget>[
              _filtros(tablas),
              Expanded(
                child: visibles.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text('No hay registros de auditoría.'),
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

  Widget _filtros(List<String> tablas) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      child: Column(
        children: <Widget>[
          if (_esSuper) ...<Widget>[
            DropdownButtonFormField<String?>(
              initialValue: _empresaFiltro,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Empresa',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: <DropdownMenuItem<String?>>[
                const DropdownMenuItem<String?>(
                    value: null, child: Text('Todas las empresas')),
                for (final e in _empresas)
                  DropdownMenuItem<String?>(value: e.id, child: Text(e.nombre)),
              ],
              onChanged: (String? v) => setState(() => _empresaFiltro = v),
            ),
            const SizedBox(height: 8),
          ],
          TextField(
            controller: _busqueda,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Buscar usuario, documento, campo o valor',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              Expanded(
                child: DropdownButtonFormField<String?>(
                  initialValue: _operacion,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Operación',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: <DropdownMenuItem<String?>>[
                    const DropdownMenuItem<String?>(
                        value: null, child: Text('Todas')),
                    for (final o in OperacionAuditoria.values)
                      DropdownMenuItem<String?>(
                          value: o.id, child: Text(o.id)),
                  ],
                  onChanged: (String? v) => setState(() => _operacion = v),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String?>(
                  initialValue: _tabla,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Tabla',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: <DropdownMenuItem<String?>>[
                    const DropdownMenuItem<String?>(
                        value: null, child: Text('Todas')),
                    for (final t in tablas)
                      DropdownMenuItem<String?>(value: t, child: Text(t)),
                  ],
                  onChanged: (String? v) => setState(() => _tabla = v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              ActionChip(
                avatar: const Icon(Icons.calendar_today_outlined, size: 16),
                label: Text('Desde: ${formatearFecha(_desde)}'),
                onPressed: () => _elegirFecha(esDesde: true),
              ),
              ActionChip(
                avatar: const Icon(Icons.calendar_today_outlined, size: 16),
                label: Text('Hasta: ${formatearFecha(_hasta)}'),
                onPressed: () => _elegirFecha(esDesde: false),
              ),
              TextButton.icon(
                onPressed: _limpiar,
                icon: const Icon(Icons.clear, size: 16),
                label: const Text('Limpiar'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tile(RegistroAuditoria r) {
    final tema = Theme.of(context);
    final color = switch (r.operacion) {
      'INSERT' => Colors.green,
      'DELETE' => tema.colorScheme.error,
      _ => Colors.orange,
    };
    final icono = switch (r.operacion) {
      'INSERT' => Icons.add_circle_outline,
      'DELETE' => Icons.delete_outline,
      _ => Icons.edit_outlined,
    };
    return ListTile(
      leading: Icon(icono, color: color),
      title: Text('${r.tabla} · ${r.documentoId}',
          maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        '${r.descripcion}\n${r.usuarioMostrar} · ${formatearFecha(r.fecha)}'
        '${_esSuper ? ' · ${r.empresaMostrar}' : ''}',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      isThreeLine: true,
      onTap: () => _detalle(r),
    );
  }

  Future<void> _detalle(RegistroAuditoria r) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detalle de auditoría'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _fila('Empresa', '${r.empresaMostrar} (${r.empresaId})'),
              _fila('Usuario', '${r.usuarioMostrar} (${r.usuario})'),
              _fila('Correo', r.usuarioEmail.isEmpty ? '—' : r.usuarioEmail),
              _fila('Operación', r.operacion),
              _fila('Tabla', r.tabla),
              _fila('Documento', r.documentoId),
              _fila('Campo', r.campo.isEmpty ? '—' : r.campo),
              _fila('Valor anterior', textoValor(r.valorViejo)),
              _fila('Valor nuevo', textoValor(r.valorNuevo)),
              _fila('Fecha', formatearFecha(r.fecha)),
              _fila('ID', r.id),
            ],
          ),
        ),
        actions: <Widget>[
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _fila(String etiqueta, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 110,
            child: Text(etiqueta,
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(child: Text(valor)),
        ],
      ),
    );
  }
}

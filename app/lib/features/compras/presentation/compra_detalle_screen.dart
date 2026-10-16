import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/formato/fechas.dart';
import '../../auth/domain/usuario.dart';
import '../../empresas/presentation/widgets/tarjeta_datos.dart';
import '../data/compras_repository.dart';
import '../domain/anexo.dart';
import '../domain/compra.dart';

/// Detalle de una compra con sus anexos legales (spec 007, T032).
class CompraDetalleScreen extends StatefulWidget {
  const CompraDetalleScreen({
    super.key,
    required this.compraId,
    required this.usuario,
    this.comprasRepository,
  });

  final String compraId;
  final Usuario usuario;
  final ComprasRepository? comprasRepository;

  @override
  State<CompraDetalleScreen> createState() => _CompraDetalleScreenState();
}

class _CompraDetalleScreenState extends State<CompraDetalleScreen> {
  late final ComprasRepository _repo =
      widget.comprasRepository ?? ComprasRepository();

  Compra? _compra;
  bool _cargando = true;
  String? _error;
  bool _subiendo = false;

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
      final compra = await _repo.obtener(widget.compraId);
      if (!mounted) return;
      setState(() {
        _compra = compra;
        _cargando = false;
        if (compra == null) _error = 'La compra ya no existe.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _cargando = false;
      });
    }
  }

  void _avisar(String m, {bool error = false}) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(m),
        backgroundColor: error ? Theme.of(context).colorScheme.error : null,
      ),
    );
  }

  Future<void> _escanearFactura() async {
    try {
      final archivo = await ImagePicker().pickImage(
        source: ImageSource.camera,
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (archivo == null) return;
      final bytes = await archivo.readAsBytes();
      final ext = archivo.name.contains('.')
          ? archivo.name.split('.').last.toLowerCase()
          : 'jpg';
      await _subir(
        bytes,
        archivo.name,
        TipoAnexo.facturaEscaneada,
        _contentType(ext),
      );
    } catch (e) {
      if (mounted) _avisar('No se pudo escanear: $e', error: true);
    }
  }

  Future<void> _subirArchivo(TipoAnexo tipo) async {
    try {
      final f = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: <String>['pdf', 'jpg', 'jpeg', 'png'],
      );
      if (f == null) return;
      final bytes = await f.readAsBytes();
      final ext = f.extension?.toLowerCase() ?? 'pdf';
      await _subir(bytes, f.name, tipo, _contentType(ext));
    } catch (e) {
      if (mounted) _avisar('No se pudo subir: $e', error: true);
    }
  }

  Future<void> _subir(
    Uint8List bytes,
    String nombre,
    TipoAnexo tipo,
    String contentType,
  ) async {
    final compra = _compra;
    if (compra == null) return;
    setState(() => _subiendo = true);
    try {
      await _repo.subirAnexo(
        compra.empresaId,
        compra.id,
        bytes,
        nombre: nombre,
        tipo: tipo,
        contentType: contentType,
      );
      if (mounted) _avisar('Anexo subido.');
    } catch (e) {
      if (mounted) _avisar('No se pudo subir el anexo: $e', error: true);
    } finally {
      if (mounted) setState(() => _subiendo = false);
    }
  }

  Future<void> _anular() async {
    final compra = _compra;
    if (compra == null) return;
    final motivo = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Anular compra'),
        content: TextField(
          controller: motivo,
          decoration: const InputDecoration(
            labelText: 'Motivo',
            border: OutlineInputBorder(),
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Volver'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Anular'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _repo.anular(compra.id, motivo.text.trim());
      await _cargar();
      if (mounted) _avisar('Compra anulada.');
    } catch (e) {
      if (mounted) _avisar('No se pudo anular: $e', error: true);
    }
  }

  Future<void> _marcarPagada() async {
    final compra = _compra;
    if (compra == null) return;
    try {
      await _repo.marcarPagada(compra.id);
      await _cargar();
      if (mounted) _avisar('Compra marcada como pagada.');
    } catch (e) {
      if (mounted) _avisar('No se pudo marcar: $e', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final compra = _compra;
    return Scaffold(
      appBar: AppBar(
        title: Text(compra == null ? 'Compra' : 'Compra ${compra.numeroOrden}'),
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
              : _cuerpo(compra!),
    );
  }

  Widget _cuerpo(Compra compra) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        TarjetaDatos(
          titulo: 'Compra',
          icono: Icons.receipt_long_outlined,
          filas: <FilaDato>[
            FilaDato('Orden', compra.numeroOrden),
            FilaDato('Proveedor', compra.proveedorNombre),
            FilaDato('Fecha', formatearFecha(compra.fecha)),
            FilaDato('Forma de pago', compra.formaPago.nombre),
            FilaDato('Estado', compra.estado.nombre),
          ],
        ),
        const SizedBox(height: 12),
        TarjetaDatos(
          titulo: 'Productos',
          icono: Icons.inventory_2_outlined,
          filas: <FilaDato>[
            for (final it in compra.items)
              FilaDato('${it.cantidad}× ${it.nombre}', formatearValor(it.subtotal)),
          ],
        ),
        const SizedBox(height: 12),
        TarjetaDatos(
          titulo: 'Totales',
          icono: Icons.summarize_outlined,
          filas: <FilaDato>[
            FilaDato('Subtotal', formatearValor(compra.subtotal)),
            FilaDato('IVA', formatearValor(compra.iva)),
            if (compra.retencionFuente > 0)
              FilaDato('Retención fuente', '-${formatearValor(compra.retencionFuente)}'),
            if (compra.retencionIva > 0)
              FilaDato('ReteIVA', '-${formatearValor(compra.retencionIva)}'),
            if (compra.retencionIca > 0)
              FilaDato('ReteICA', '-${formatearValor(compra.retencionIca)}'),
            FilaDato('Total a pagar', formatearValor(compra.valorTotal)),
          ],
        ),
        const SizedBox(height: 12),
        _Anexos(
          anexos: _repo.escucharAnexos(compra.id),
          subiendo: _subiendo,
          puedeEliminar: widget.usuario.esSuperAdmin,
          onEscanear: compra.anulada ? null : _escanearFactura,
          onPdf: compra.anulada ? null : () => _subirArchivo(TipoAnexo.facturaPdf),
          onOtro: compra.anulada ? null : () => _subirArchivo(TipoAnexo.anexoLegal),
          onEliminar: (Anexo a) => _repo.eliminarAnexo(a, compraId: compra.id),
        ),
        const SizedBox(height: 24),
        if (!compra.anulada) ...<Widget>[
          if (compra.estado == EstadoCompra.pendiente)
            FilledButton.icon(
              onPressed: _marcarPagada,
              icon: const Icon(Icons.payments_outlined),
              label: const Text('Marcar como pagada'),
            ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _anular,
            icon: const Icon(Icons.cancel_outlined),
            label: const Text('Anular compra'),
            style: OutlinedButton.styleFrom(foregroundColor: scheme.error),
          ),
        ],
        const SizedBox(height: 32),
      ],
    );
  }

  static String _contentType(String ext) {
    switch (ext.toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'jpg':
      case 'jpeg':
      default:
        return 'image/jpeg';
    }
  }
}

/// Sección de anexos legales de una compra (RF-04..RF-06).
class _Anexos extends StatelessWidget {
  const _Anexos({
    required this.anexos,
    required this.subiendo,
    required this.puedeEliminar,
    required this.onEscanear,
    required this.onPdf,
    required this.onOtro,
    required this.onEliminar,
  });

  final Stream<List<Anexo>> anexos;
  final bool subiendo;
  final bool puedeEliminar;
  final VoidCallback? onEscanear;
  final VoidCallback? onPdf;
  final VoidCallback? onOtro;
  final Future<void> Function(Anexo) onEliminar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Icon(Icons.attach_file),
                const SizedBox(width: 8),
                Text('Anexos legales', style: theme.textTheme.titleMedium),
                const SizedBox(width: 8),
                if (subiendo)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: <Widget>[
                OutlinedButton.icon(
                  onPressed: onEscanear,
                  icon: const Icon(Icons.photo_camera_outlined, size: 18),
                  label: const Text('Escanear factura'),
                ),
                OutlinedButton.icon(
                  onPressed: onPdf,
                  icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                  label: const Text('Subir PDF'),
                ),
                OutlinedButton.icon(
                  onPressed: onOtro,
                  icon: const Icon(Icons.description_outlined, size: 18),
                  label: const Text('Otro anexo'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            StreamBuilder<List<Anexo>>(
              stream: anexos,
              builder: (context, snap) {
                final lista = snap.data ?? const <Anexo>[];
                if (lista.isEmpty) {
                  return const Text('Sin anexos todavía.');
                }
                return Column(
                  children: <Widget>[
                    for (final a in lista)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(a.tipo == TipoAnexo.facturaPdf
                            ? Icons.picture_as_pdf
                            : Icons.image_outlined),
                        title: Text(a.nombre,
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text(
                          '${a.tipo.nombre} · ${formatearFecha(a.fechaSubida)}'
                          ' · ${a.subidoPor.isEmpty ? "—" : a.subidoPor}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: puedeEliminar
                            ? IconButton(
                                tooltip: 'Eliminar',
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => onEliminar(a),
                              )
                            : null,
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

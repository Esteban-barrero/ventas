import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../auth/domain/usuario.dart';
import '../data/categorias_repository.dart';
import '../data/imagenes_productos_repository.dart';
import '../data/productos_repository.dart';
import '../domain/categoria.dart';
import '../domain/producto.dart';

/// Formulario de creación/edición de un producto (spec 003, T022).
///
/// Devuelve `true` al guardar para que el catálogo se recargue.
class ProductoFormScreen extends StatefulWidget {
  const ProductoFormScreen({
    super.key,
    required this.usuario,
    this.producto,
    this.productosRepository,
    this.categoriasRepository,
    this.imagenesRepository,
    this.selectorImagen,
  });

  final Usuario usuario;

  /// Producto a editar. `null` para crear uno nuevo.
  final Producto? producto;

  final ProductosRepository? productosRepository;
  final CategoriasRepository? categoriasRepository;
  final ImagenesProductosRepository? imagenesRepository;

  /// Permite inyectar el selector de imagen en las pruebas.
  final Future<XFile?> Function()? selectorImagen;

  @override
  State<ProductoFormScreen> createState() => _ProductoFormScreenState();
}

class _ProductoFormScreenState extends State<ProductoFormScreen> {
  late final ProductosRepository _repo =
      widget.productosRepository ?? ProductosRepository();
  late final CategoriasRepository _categoriasRepo =
      widget.categoriasRepository ?? CategoriasRepository();
  late final ImagenesProductosRepository _imagenes =
      widget.imagenesRepository ?? ImagenesProductosRepository();

  final _codigo = TextEditingController();
  final _nombre = TextEditingController();
  final _descripcion = TextEditingController();
  final _material = TextEditingController();
  final _dimensiones = TextEditingController();
  final _peso = TextEditingController();
  final _color = TextEditingController();
  final _costo = TextEditingController();
  final _margenContado = TextEditingController();
  final _margenCredito = TextEditingController();
  final _costoEnvio = TextEditingController();
  final _stock = TextEditingController();
  final _stockMinimo = TextEditingController();

  List<Categoria> _categorias = const <Categoria>[];
  String? _categoriaId;
  Uint8List? _fotoBytes;
  String _fotoExtension = 'png';
  String _fotoUrl = '';
  bool _guardando = false;

  String get _empresaId => widget.usuario.empresaId ?? '';
  bool get _esEdicion => widget.producto != null;

  @override
  void initState() {
    super.initState();
    final p = widget.producto;
    if (p != null) {
      _codigo.text = p.codigo;
      _nombre.text = p.nombre;
      _descripcion.text = p.descripcion;
      _material.text = p.medidas.material;
      _dimensiones.text = p.medidas.dimensiones;
      _peso.text = p.medidas.peso;
      _color.text = p.medidas.color;
      _costo.text = _textoNumero(p.costo);
      _margenContado.text =
          p.margenContado == null ? '' : _textoNumero(p.margenContado!);
      _margenCredito.text =
          p.margenCredito == null ? '' : _textoNumero(p.margenCredito!);
      _costoEnvio.text =
          p.costoEnvio == null ? '' : _textoNumero(p.costoEnvio!);
      _stock.text = '${p.stock}';
      _stockMinimo.text = '${p.stockMinimo}';
      _categoriaId = p.categoriaId.isEmpty ? null : p.categoriaId;
      _fotoUrl = p.fotoPrincipal;
    }
    _cargarCategorias();
  }

  @override
  void dispose() {
    for (final c in <TextEditingController>[
      _codigo,
      _nombre,
      _descripcion,
      _material,
      _dimensiones,
      _peso,
      _color,
      _costo,
      _margenContado,
      _margenCredito,
      _costoEnvio,
      _stock,
      _stockMinimo,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _cargarCategorias() async {
    if (_empresaId.isEmpty) return;
    try {
      final lista = await _categoriasRepo.listar(_empresaId, soloActivas: true);
      if (mounted) setState(() => _categorias = lista);
    } catch (_) {
      // Sin categorías: el producto queda sin categoría.
    }
  }

  void _avisar(String mensaje) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(mensaje)));
  }

  Future<void> _elegirFoto() async {
    try {
      final archivo = widget.selectorImagen != null
          ? await widget.selectorImagen!()
          : await ImagePicker().pickImage(
              source: ImageSource.gallery,
              maxWidth: 1200,
              maxHeight: 1200,
              imageQuality: 85,
            );
      if (archivo == null) return;

      final bytes = await archivo.readAsBytes();
      final extension = archivo.name.contains('.')
          ? archivo.name.split('.').last.toLowerCase()
          : 'png';
      try {
        ImagenesProductosRepository.validar(bytes, extension: extension);
      } on ImagenInvalidaException catch (e) {
        if (mounted) _avisar(e.mensaje);
        return;
      }
      if (mounted) {
        setState(() {
          _fotoBytes = bytes;
          _fotoExtension = extension;
        });
      }
    } catch (e) {
      if (mounted) _avisar('No se pudo leer la imagen: $e');
    }
  }

  Future<void> _guardar() async {
    final codigo = _codigo.text.trim();
    if (codigo.isEmpty) return _avisar('El código es obligatorio.');
    if (_nombre.text.trim().isEmpty) return _avisar('El nombre es obligatorio.');

    final costo = double.tryParse(_costo.text.trim()) ?? 0;
    if (costo < 0) return _avisar('El costo no puede ser negativo.');

    final margenContado = _opcional(_margenContado.text);
    final margenCredito = _opcional(_margenCredito.text);
    if ((margenContado ?? 0) < 0 || (margenCredito ?? 0) < 0) {
      return _avisar('Los márgenes no pueden ser negativos.');
    }

    final stock = int.tryParse(_stock.text.trim()) ?? 0;
    final stockMinimo = int.tryParse(_stockMinimo.text.trim()) ?? 0;
    if (stock < 0 || stockMinimo < 0) {
      return _avisar('El stock no puede ser negativo.');
    }

    setState(() => _guardando = true);
    try {
      final id = widget.producto?.id ?? _repo.nuevoId();

      var fotoUrl = _fotoUrl;
      if (_fotoBytes != null) {
        fotoUrl = await _imagenes.subir(
          _empresaId,
          id,
          _fotoBytes!,
          nombre: 'foto',
          extension: _fotoExtension,
        );
      }

      final producto = Producto(
        id: id,
        empresaId: _empresaId,
        codigo: codigo,
        nombre: _nombre.text.trim(),
        descripcion: _descripcion.text.trim(),
        medidas: Medidas(
          material: _material.text.trim(),
          dimensiones: _dimensiones.text.trim(),
          peso: _peso.text.trim(),
          color: _color.text.trim(),
        ),
        categoriaId: _categoriaId ?? '',
        fotoPrincipal: fotoUrl,
        galeria: widget.producto?.galeria ?? const <String>[],
        costo: costo,
        margenContado: margenContado,
        margenCredito: margenCredito,
        costoEnvio: _opcional(_costoEnvio.text),
        stock: stock,
        stockMinimo: stockMinimo,
        activo: widget.producto?.activo ?? true,
        fechaCreacion: widget.producto?.fechaCreacion,
      );

      if (_esEdicion) {
        await _repo.actualizar(producto);
      } else {
        await _repo.crear(producto);
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on CodigoDuplicadoException catch (e) {
      if (mounted) _avisar(e.toString());
    } catch (e) {
      if (mounted) _avisar('No se pudo guardar: $e');
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(_esEdicion ? 'Editar producto' : 'Nuevo producto'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          _Foto(fotoBytes: _fotoBytes, url: _fotoUrl, onElegir: _elegirFoto),
          const SizedBox(height: 16),
          _seccion(theme, 'Datos'),
          _campo(_codigo, 'Código *'),
          _campo(_nombre, 'Nombre *'),
          _campo(_descripcion, 'Descripción', maxLines: 2),
          const SizedBox(height: 8),
          _seccion(theme, 'Medidas'),
          _campo(_material, 'Material'),
          _campo(_dimensiones, 'Dimensiones / tallas'),
          _campo(_peso, 'Peso'),
          _campo(_color, 'Color'),
          const SizedBox(height: 8),
          _seccion(theme, 'Categoría'),
          _dropdownCategoria(),
          const SizedBox(height: 8),
          _seccion(theme, 'Precios y márgenes'),
          _campo(_costo, 'Costo *', numero: true),
          _campo(_margenContado, 'Margen contado % (vacío = general)',
              numero: true),
          _campo(_margenCredito, 'Margen crédito % (vacío = general)',
              numero: true),
          _campo(_costoEnvio, 'Costo de envío (vacío = general)', numero: true),
          const SizedBox(height: 8),
          _seccion(theme, 'Inventario'),
          _campo(_stock, 'Stock', numero: true),
          _campo(_stockMinimo, 'Stock mínimo (alerta)', numero: true),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _guardando ? null : _guardar,
            icon: _guardando
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: Text(_guardando ? 'Guardando…' : 'Guardar'),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _seccion(ThemeData theme, String titulo) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(titulo, style: theme.textTheme.titleMedium),
      );

  Widget _campo(
    TextEditingController controller,
    String etiqueta, {
    bool numero = false,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: numero ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: etiqueta,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _dropdownCategoria() {
    return DropdownButtonFormField<String?>(
      initialValue: _categoriaId,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Categoría',
        border: OutlineInputBorder(),
      ),
      items: <DropdownMenuItem<String?>>[
        const DropdownMenuItem<String?>(value: null, child: Text('Sin categoría')),
        for (final c in _categorias)
          DropdownMenuItem<String?>(value: c.id, child: Text(c.nombre)),
      ],
      onChanged: (String? v) => setState(() => _categoriaId = v),
    );
  }

  /// Convierte el texto en un número opcional (`null` si está vacío o no es
  /// válido), para distinguir "heredar" de "0".
  static double? _opcional(String texto) {
    final t = texto.trim();
    if (t.isEmpty) return null;
    return double.tryParse(t);
  }

  /// Muestra un número sin decimales innecesarios (20000 en lugar de 20000.0).
  static String _textoNumero(double valor) {
    if (valor == valor.roundToDouble()) return valor.round().toString();
    return valor.toString();
  }
}

/// Selector y vista previa de la foto principal.
class _Foto extends StatelessWidget {
  const _Foto({
    required this.fotoBytes,
    required this.url,
    required this.onElegir,
  });

  final Uint8List? fotoBytes;
  final String url;
  final VoidCallback onElegir;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget contenido;
    if (fotoBytes != null) {
      contenido = Image.memory(fotoBytes!, fit: BoxFit.cover);
    } else if (url.trim().isNotEmpty) {
      contenido = Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) =>
            Icon(Icons.image_not_supported_outlined, color: scheme.outline),
      );
    } else {
      contenido = Center(
        child: Icon(Icons.add_a_photo_outlined, size: 40, color: scheme.outline),
      );
    }

    return Column(
      children: <Widget>[
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 180,
            width: double.infinity,
            color: scheme.surfaceContainerHighest,
            child: contenido,
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: onElegir,
          icon: const Icon(Icons.photo_library_outlined),
          label: Text(fotoBytes != null || url.trim().isNotEmpty
              ? 'Cambiar foto'
              : 'Elegir foto'),
        ),
      ],
    );
  }
}

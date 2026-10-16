import 'package:flutter/material.dart';

import '../../../core/formato/fechas.dart';
import '../../auth/domain/permisos.dart';
import '../../auth/domain/usuario.dart';
import '../../empresas/data/empresas_repository.dart';
import '../../empresas/domain/parametros_empresa.dart';
import '../data/categorias_repository.dart';
import '../data/productos_repository.dart';
import '../domain/categoria.dart';
import '../domain/precio.dart';
import '../domain/producto.dart';
import 'categorias_screen.dart';
import 'producto_detalle_screen.dart';
import 'producto_form_screen.dart';
import 'widgets/imagen_producto.dart';

/// Catálogo de productos de la empresa (spec 003, RF-11).
///
/// Muestra las tarjetas (foto, nombre, medidas y precio), permite **buscar** y
/// **filtrar por categoría**, y —si el usuario tiene `catalogo.editar`— crear,
/// editar y gestionar categorías. Los clientes solo ven los productos activos.
class CatalogoScreen extends StatefulWidget {
  const CatalogoScreen({
    super.key,
    required this.usuario,
    this.productosRepository,
    this.categoriasRepository,
    this.empresasRepository,
  });

  final Usuario usuario;
  final ProductosRepository? productosRepository;
  final CategoriasRepository? categoriasRepository;
  final EmpresasRepository? empresasRepository;

  @override
  State<CatalogoScreen> createState() => _CatalogoScreenState();
}

class _CatalogoScreenState extends State<CatalogoScreen> {
  late final ProductosRepository _productos =
      widget.productosRepository ?? ProductosRepository();
  late final CategoriasRepository _categorias =
      widget.categoriasRepository ?? CategoriasRepository();
  late final EmpresasRepository _empresas =
      widget.empresasRepository ?? EmpresasRepository();

  final TextEditingController _busqueda = TextEditingController();
  ParametrosEmpresa _parametros = const ParametrosEmpresa();
  String? _categoriaId;
  String? _colorFiltro;
  bool _soloConStock = false;

  /// Filtro de estado: `null` = todos, `true` = activos, `false` = inactivos.
  bool? _estadoFiltro;

  String get _empresaId => widget.usuario.empresaId ?? '';
  bool get _puedeEditar => widget.usuario.puede(Permiso.catalogoEditar);

  @override
  void initState() {
    super.initState();
    _busqueda.addListener(() => setState(() {}));
    _cargarParametros();
    _sembrarCategorias();
  }

  /// Si la empresa no tiene categorías y el usuario puede editar, crea la lista
  /// estándar para que el formulario de producto tenga opciones.
  Future<void> _sembrarCategorias() async {
    if (_empresaId.isEmpty || !_puedeEditar) return;
    try {
      await _categorias.sembrarEstandar(_empresaId);
    } catch (_) {
      // Si falla (p. ej. sin conexión), se reintenta en la próxima apertura.
    }
  }

  @override
  void dispose() {
    _busqueda.dispose();
    super.dispose();
  }

  Future<void> _cargarParametros() async {
    if (_empresaId.isEmpty) return;
    try {
      final empresa = await _empresas.obtener(_empresaId);
      if (!mounted || empresa == null) return;
      setState(() => _parametros = empresa.parametros);
    } catch (_) {
      // Si no se pueden leer, se usan los parámetros por defecto.
    }
  }

  Future<void> _nuevoProducto() async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => ProductoFormScreen(usuario: widget.usuario),
      ),
    );
  }

  Future<void> _abrirCategorias() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => CategoriasScreen(usuario: widget.usuario),
      ),
    );
  }

  Future<void> _abrirProducto(Producto producto) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ProductoDetalleScreen(
          productoId: producto.id,
          usuario: widget.usuario,
          parametros: _parametros,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_empresaId.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Catálogo')),
        body: const Center(child: Text('No perteneces a ninguna empresa.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catálogo'),
        actions: <Widget>[
          if (_puedeEditar)
            IconButton(
              tooltip: 'Categorías',
              icon: const Icon(Icons.category_outlined),
              onPressed: _abrirCategorias,
            ),
        ],
      ),
      floatingActionButton: _puedeEditar
          ? FloatingActionButton.extended(
              onPressed: _nuevoProducto,
              icon: const Icon(Icons.add),
              label: const Text('Nuevo producto'),
            )
          : null,
      body: StreamBuilder<List<Producto>>(
        stream: _productos.escuchar(_empresaId),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('No se pudo cargar el catálogo: ${snap.error}'));
          }
          final todos = snap.data ?? const <Producto>[];
          final visibles = ProductosRepository.filtrar(
            todos,
            categoriaId: _categoriaId,
            color: _colorFiltro,
            busqueda: _busqueda.text,
            soloConStock: _soloConStock,
            activo: _puedeEditar ? _estadoFiltro : true,
          );
          return Column(
            children: <Widget>[
              _Filtros(
                busqueda: _busqueda,
                categorias: _categorias.escuchar(_empresaId),
                categoriaId: _categoriaId,
                onCategoria: (String? id) => setState(() => _categoriaId = id),
                colores: ProductosRepository.coloresDisponibles(todos),
                color: _colorFiltro,
                onColor: (String? c) => setState(() => _colorFiltro = c),
                soloConStock: _soloConStock,
                onSoloConStock: (bool v) => setState(() => _soloConStock = v),
                puedeEditar: _puedeEditar,
                estado: _estadoFiltro,
                onEstado: (bool? v) => setState(() => _estadoFiltro = v),
              ),
              Expanded(
                child: visibles.isEmpty
                    ? _Vacio(todos: todos.isEmpty)
                    : _Grid(
                        productos: visibles,
                        parametros: _parametros,
                        onAbrir: _abrirProducto,
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Búsqueda por texto y filtros por categoría y color (RF-09).
class _Filtros extends StatelessWidget {
  const _Filtros({
    required this.busqueda,
    required this.categorias,
    required this.categoriaId,
    required this.onCategoria,
    required this.colores,
    required this.color,
    required this.onColor,
    required this.soloConStock,
    required this.onSoloConStock,
    required this.puedeEditar,
    required this.estado,
    required this.onEstado,
  });

  final TextEditingController busqueda;
  final Stream<List<Categoria>> categorias;
  final String? categoriaId;
  final ValueChanged<String?> onCategoria;
  final List<String> colores;
  final String? color;
  final ValueChanged<String?> onColor;
  final bool soloConStock;
  final ValueChanged<bool> onSoloConStock;
  final bool puedeEditar;
  final bool? estado;
  final ValueChanged<bool?> onEstado;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        children: <Widget>[
          TextField(
            controller: busqueda,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Buscar por nombre o código',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              Expanded(
                child: StreamBuilder<List<Categoria>>(
                  stream: categorias,
                  builder: (context, snap) {
                    final lista = snap.data ?? const <Categoria>[];
                    // Si la categoría elegida desaparece, se limpia el filtro.
                    final valor =
                        lista.any((Categoria c) => c.id == categoriaId)
                            ? categoriaId
                            : null;
                    return DropdownButtonFormField<String?>(
                      initialValue: valor,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Categoría',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: <DropdownMenuItem<String?>>[
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Todas'),
                        ),
                        for (final c in lista)
                          DropdownMenuItem<String?>(
                            value: c.id,
                            child: Text(c.nombre),
                          ),
                      ],
                      onChanged: onCategoria,
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String?>(
                  initialValue:
                      colores.contains(color) ? color : null,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Color',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: <DropdownMenuItem<String?>>[
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Todos'),
                    ),
                    for (final c in colores)
                      DropdownMenuItem<String?>(value: c, child: Text(c)),
                  ],
                  onChanged: onColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              FilterChip(
                label: const Text('Solo con stock'),
                selected: soloConStock,
                onSelected: onSoloConStock,
              ),
              const SizedBox(width: 8),
              if (puedeEditar)
                Expanded(
                  child: DropdownButtonFormField<bool?>(
                    initialValue: estado,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Estado',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: const <DropdownMenuItem<bool?>>[
                      DropdownMenuItem<bool?>(
                          value: null, child: Text('Todos')),
                      DropdownMenuItem<bool?>(
                          value: true, child: Text('Activos')),
                      DropdownMenuItem<bool?>(
                          value: false, child: Text('Inactivos')),
                    ],
                    onChanged: onEstado,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Rejilla de tarjetas del catálogo (CA-06).
class _Grid extends StatelessWidget {
  const _Grid({
    required this.productos,
    required this.parametros,
    required this.onAbrir,
  });

  final List<Producto> productos;
  final ParametrosEmpresa parametros;
  final ValueChanged<Producto> onAbrir;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.62,
      ),
      itemCount: productos.length,
      itemBuilder: (context, i) =>
          _TarjetaProducto(
            producto: productos[i],
            parametros: parametros,
            onTap: () => onAbrir(productos[i]),
          ),
    );
  }
}

/// Tarjeta de un producto: foto, nombre, medidas y precio de contado.
class _TarjetaProducto extends StatelessWidget {
  const _TarjetaProducto({
    required this.producto,
    required this.parametros,
    required this.onTap,
  });

  final Producto producto;
  final ParametrosEmpresa parametros;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final precio = producto.precio(TipoPrecio.contado, parametros);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Stack(
              children: <Widget>[
                AspectRatio(
                  aspectRatio: 1.2,
                  child: ImagenProducto(producto: producto),
                ),
                if (!producto.activo)
                  Positioned(
                    left: 6,
                    top: 6,
                    child: _Etiqueta(
                      texto: 'Inactivo',
                      color: scheme.error,
                      onColor: scheme.onError,
                    ),
                  )
                else if (producto.stockBajo)
                  Positioned(
                    left: 6,
                    top: 6,
                    child: _Etiqueta(
                      texto: producto.stock <= 0 ? 'Agotado' : 'Stock bajo',
                      color: scheme.tertiaryContainer,
                      onColor: scheme.onTertiaryContainer,
                    ),
                  ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      producto.nombre,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall,
                    ),
                    if (!producto.medidas.vacio) ...<Widget>[
                      const SizedBox(height: 2),
                      Text(
                        producto.medidas.resumen,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ],
                    if (producto.color.trim().isNotEmpty) ...<Widget>[
                      const SizedBox(height: 2),
                      Row(
                        children: <Widget>[
                          Icon(Icons.circle,
                              size: 10, color: _colorDe(producto.color)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              producto.color,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(color: scheme.onSurfaceVariant),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const Spacer(),
                    Text(
                      formatearValor(precio),
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Stock: ${producto.stock}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Etiqueta extends StatelessWidget {
  const _Etiqueta({
    required this.texto,
    required this.color,
    required this.onColor,
  });

  final String texto;
  final Color color;
  final Color onColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        texto,
        style: TextStyle(color: onColor, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}

/// Color visual aproximado a partir del nombre (para el punto de color).
///
/// Es solo una ayuda visual; el color real lo describe el texto del producto.
Color _colorDe(String nombre) {
  switch (nombre.trim().toLowerCase()) {
    case 'negro':
      return Colors.black;
    case 'blanco':
      return Colors.white;
    case 'rojo':
      return Colors.red;
    case 'azul':
      return Colors.blue;
    case 'verde':
      return Colors.green;
    case 'amarillo':
      return Colors.amber;
    case 'naranja':
      return Colors.orange;
    case 'rosa':
      return Colors.pink;
    case 'morado':
    case 'violeta':
    case 'púrpura':
      return Colors.purple;
    case 'marrón':
    case 'marron':
    case 'café':
    case 'cafe':
      return Colors.brown;
    case 'gris':
      return Colors.grey;
    case 'dorado':
      return const Color(0xFFB8860B);
    case 'plateado':
      return const Color(0xFFB0B0B0);
    case 'beige':
      return const Color(0xFFD8C3A5);
    default:
      return Colors.blueGrey;
  }
}

class _Vacio extends StatelessWidget {
  const _Vacio({required this.todos});

  /// `true` si la empresa no tiene ningún producto todavía.
  final bool todos;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.inventory_2_outlined, size: 48),
            const SizedBox(height: 12),
            Text(
              todos
                  ? 'Todavía no hay productos en el catálogo.'
                  : 'No se encontraron productos con esos filtros.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

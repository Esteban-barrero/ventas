import 'package:flutter/material.dart';

import '../../empresas/data/empresas_repository.dart';
import '../../empresas/domain/plan.dart';
import '../data/usuarios_repository.dart';
import '../domain/usuario.dart';
import 'usuario_form_screen.dart';

/// Lista y gestión de usuarios (spec 001, CA-06 / RF-03, RF-04).
///
/// - El **Administrador** ve y gestiona los usuarios de su empresa.
/// - El **Super Admin** ve los de todas las empresas (columna Empresa).
///
/// Tocar un usuario abre el formulario en modo edición; el botón inferior crea
/// uno nuevo.
class UsuariosListScreen extends StatefulWidget {
  const UsuariosListScreen({
    super.key,
    required this.usuario,
    this.repository,
    this.empresasRepository,
  });

  final Usuario usuario;
  final UsuariosRepository? repository;
  final EmpresasRepository? empresasRepository;

  @override
  State<UsuariosListScreen> createState() => _UsuariosListScreenState();
}

class _UsuariosListScreenState extends State<UsuariosListScreen> {
  late final UsuariosRepository _repo =
      widget.repository ?? UsuariosRepository();
  late final EmpresasRepository _empresasRepo =
      widget.empresasRepository ?? EmpresasRepository();

  final _busqueda = TextEditingController();
  int? _maxUsuarios;

  bool get _esSuperAdmin => widget.usuario.esSuperAdmin;

  String? get _empresaId {
    final id = widget.usuario.empresaId;
    return (id == null || id.isEmpty) ? null : id;
  }

  @override
  void initState() {
    super.initState();
    _busqueda.addListener(_alCambiarBusqueda);
    if (!_esSuperAdmin && _empresaId != null) _cargarLimite();
  }

  @override
  void dispose() {
    _busqueda
      ..removeListener(_alCambiarBusqueda)
      ..dispose();
    super.dispose();
  }

  void _alCambiarBusqueda() => setState(() {});

  Future<void> _cargarLimite() async {
    try {
      final empresa = await _empresasRepo.obtener(_empresaId!);
      if (!mounted || empresa == null) return;
      setState(() => _maxUsuarios = empresa.limites.maxUsuarios);
    } catch (_) {
      // El límite es informativo; si falla, no rompe la pantalla.
    }
  }

  Stream<List<Usuario>> get _usuarios {
    if (_esSuperAdmin) return _repo.escucharTodos();
    final id = _empresaId;
    if (id == null) return Stream<List<Usuario>>.value(const <Usuario>[]);
    return _repo.escucharDeEmpresa(id);
  }

  Future<void> _abrirFormulario({Usuario? usuario}) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => UsuarioFormScreen(
          usuarioActual: widget.usuario,
          usuario: usuario,
          repository: widget.repository,
          empresasRepository: widget.empresasRepository,
        ),
      ),
    );
  }

  List<Usuario> _filtrar(List<Usuario> usuarios) {
    final consulta = _busqueda.text.trim().toLowerCase();
    if (consulta.isEmpty) return usuarios;
    return usuarios
        .where((u) =>
            u.nombre.toLowerCase().contains(consulta) ||
            u.email.toLowerCase().contains(consulta))
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Usuarios')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirFormulario(),
        icon: const Icon(Icons.person_add_alt),
        label: const Text('Nuevo usuario'),
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _busqueda,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre o correo',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                suffixIcon: _busqueda.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: _busqueda.clear,
                      ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Usuario>>(
              stream: _usuarios,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return _Mensaje(
                    icono: Icons.error_outline,
                    texto: 'No se pudieron cargar los usuarios.\n'
                        '${snapshot.error}',
                  );
                }

                final todos = snapshot.data ?? const <Usuario>[];
                final visibles = _filtrar(todos);

                return ListView(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 96),
                  children: <Widget>[
                    _Encabezado(total: todos.length, maximo: _maxUsuarios),
                    if (visibles.isEmpty)
                      _Mensaje(
                        icono: Icons.group_outlined,
                        texto: todos.isEmpty
                            ? 'Aún no hay usuarios.'
                            : 'Sin resultados para "${_busqueda.text}".',
                      )
                    else
                      for (final usuario in visibles)
                        _TarjetaUsuario(
                          usuario: usuario,
                          mostrarEmpresa: _esSuperAdmin,
                          onTap: () => _abrirFormulario(usuario: usuario),
                        ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Encabezado con el total de usuarios y el límite del plan (si aplica).
class _Encabezado extends StatelessWidget {
  const _Encabezado({required this.total, this.maximo});

  final int total;
  final int? maximo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final plural = total == 1 ? 'usuario' : 'usuarios';

    String texto = '$total $plural';
    if (maximo != null) {
      texto += LimitesPlan.esIlimitado(maximo!)
          ? ' · sin límite'
          : ' de $maximo permitidos';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
      child: Row(
        children: <Widget>[
          Icon(Icons.people_outline, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(texto, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

/// Tarjeta de un usuario con sus roles y estado.
class _TarjetaUsuario extends StatelessWidget {
  const _TarjetaUsuario({
    required this.usuario,
    required this.mostrarEmpresa,
    required this.onTap,
  });

  final Usuario usuario;
  final bool mostrarEmpresa;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final nombre = usuario.nombre.isEmpty ? usuario.email : usuario.nombre;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              CircleAvatar(
                backgroundColor:
                    usuario.activo ? scheme.primary : scheme.surfaceContainerHighest,
                child: Text(
                  _iniciales(nombre),
                  style: TextStyle(
                    color: usuario.activo ? scheme.onPrimary : scheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            nombre,
                            style: theme.textTheme.titleMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!usuario.activo)
                          const _Etiqueta(
                            texto: 'Inactivo',
                            icono: Icons.block,
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      usuario.email,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: scheme.secondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (mostrarEmpresa) ...<Widget>[
                      const SizedBox(height: 2),
                      Text(
                        'Empresa: ${usuario.empresaId ?? 'sin asignar'}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                    const SizedBox(height: 8),
                    if (usuario.rolesTipados.isEmpty)
                      Text('Sin rol', style: theme.textTheme.bodySmall)
                    else
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: <Widget>[
                          for (final rol in usuario.rolesTipados)
                            Chip(
                              label: Text(rol.nombre),
                              visualDensity: VisualDensity.compact,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                        ],
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.edit_outlined, size: 18, color: scheme.outline),
            ],
          ),
        ),
      ),
    );
  }

  static String _iniciales(String texto) {
    final partes =
        texto.trim().split(RegExp(r'[\s@._-]+')).where((p) => p.isNotEmpty);
    if (partes.isEmpty) return '?';
    return partes.take(2).map((p) => p[0].toUpperCase()).join();
  }
}

class _Etiqueta extends StatelessWidget {
  const _Etiqueta({required this.texto, required this.icono});

  final String texto;
  final IconData icono;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icono, size: 12, color: scheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            texto,
            style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _Mensaje extends StatelessWidget {
  const _Mensaje({required this.icono, required this.texto});

  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: <Widget>[
          Icon(icono, size: 48, color: theme.colorScheme.outline),
          const SizedBox(height: 12),
          Text(
            texto,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

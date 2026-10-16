import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../empresas/data/empresas_repository.dart';
import '../../empresas/domain/empresa.dart';
import '../data/usuarios_repository.dart';
import '../domain/datos_usuario.dart';
import '../domain/roles.dart';
import '../domain/usuario.dart';

/// Formulario para crear o editar un usuario (spec 001, CA-06 / RF-03, RF-04).
///
/// - El **Administrador** crea usuarios dentro de su propia empresa.
/// - El **Super Admin** elige la empresa destino y puede crear en cualquiera.
///
/// El rol `superadmin` no se reparte desde aquí (ver [Rol.asignables]).
class UsuarioFormScreen extends StatefulWidget {
  const UsuarioFormScreen({
    super.key,
    required this.usuarioActual,
    this.usuario,
    this.repository,
    this.empresasRepository,
  });

  /// Quien realiza la acción (define empresa y roles permitidos).
  final Usuario usuarioActual;

  /// Usuario a editar. Si es `null`, se está creando uno nuevo.
  final Usuario? usuario;

  final UsuariosRepository? repository;
  final EmpresasRepository? empresasRepository;

  @override
  State<UsuarioFormScreen> createState() => _UsuarioFormScreenState();
}

class _UsuarioFormScreenState extends State<UsuarioFormScreen> {
  late final UsuariosRepository _repo =
      widget.repository ?? UsuariosRepository();
  late final EmpresasRepository _empresasRepo =
      widget.empresasRepository ?? EmpresasRepository();

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombre;
  late final TextEditingController _email;
  late final TextEditingController _telefono;

  late Set<String> _roles;
  late bool _activo;
  String? _empresaId;

  List<Empresa> _empresas = const <Empresa>[];
  bool _cargandoEmpresas = false;
  bool _guardando = false;
  bool _restableciendo = false;
  String? _error;

  bool get _esEdicion => widget.usuario != null;
  bool get _esSuperAdmin => widget.usuarioActual.esSuperAdmin;

  /// El Super Admin que crea debe indicar la empresa destino.
  bool get _requiereEmpresa => _esSuperAdmin && !_esEdicion;

  /// Roles que se muestran como opción.
  ///
  /// Son los asignables más los que ya tiene el usuario pero no son asignables
  /// (por ejemplo `superadmin`), para no retirarlos sin querer al guardar. Esos
  /// extra solo los ve el propio Super Admin.
  List<Rol> get _rolesDisponibles {
    final extras = (widget.usuario?.rolesTipados ?? const <Rol>[])
        .where((r) => !Rol.asignables.contains(r))
        .where((_) => _esSuperAdmin)
        .toList(growable: false);
    return <Rol>[...Rol.asignables, ...extras];
  }

  @override
  void initState() {
    super.initState();
    final u = widget.usuario;
    _nombre = TextEditingController(text: u?.nombre ?? '');
    _email = TextEditingController(text: u?.email ?? '');
    _telefono = TextEditingController(text: u?.telefono ?? '');
    _roles = <String>{...(u?.roles ?? const <String>[])};
    _activo = u?.activo ?? true;
    _empresaId = u?.empresaId ?? widget.usuarioActual.empresaId;

    if (_requiereEmpresa) _cargarEmpresas();
  }

  @override
  void dispose() {
    _nombre.dispose();
    _email.dispose();
    _telefono.dispose();
    super.dispose();
  }

  Future<void> _cargarEmpresas() async {
    setState(() => _cargandoEmpresas = true);
    try {
      final lista = await _empresasRepo.listar();
      if (!mounted) return;
      setState(() {
        _empresas = lista;
        _cargandoEmpresas = false;
        if (_empresaId == null && lista.length == 1) {
          _empresaId = lista.first.id;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _cargandoEmpresas = false);
    }
  }

  void _alternarRol(Rol rol) {
    setState(() {
      if (_roles.contains(rol.id)) {
        _roles.remove(rol.id);
      } else {
        _roles.add(rol.id);
      }
    });
  }

  Future<void> _guardar() async {
    setState(() => _error = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_roles.isEmpty) {
      setState(() => _error = 'Asigna al menos un rol.');
      return;
    }

    setState(() => _guardando = true);
    try {
      if (_esEdicion) {
        await _guardarEdicion();
      } else {
        await _crear();
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _mensajeDeError(e);
        _guardando = false;
      });
    }
  }

  Future<void> _crear() async {
    final datos = DatosNuevoUsuario(
      nombre: _nombre.text,
      email: _email.text,
      telefono: _telefono.text,
      roles: _roles.toList(growable: false),
      activo: _activo,
      empresaId: _empresaId ?? widget.usuarioActual.empresaId,
    );

    final resultado = await _repo.crear(
      datos,
      requiereEmpresa: _requiereEmpresa,
    );

    if (!mounted) return;
    await _mostrarCreado(resultado);
  }

  Future<void> _guardarEdicion() async {
    final original = widget.usuario!;
    final autor = widget.usuarioActual.uid;

    if (_nombre.text.trim() != original.nombre) {
      await _repo.actualizarDatos(
        original.uid,
        nombre: _nombre.text,
        autor: autor,
      );
    }
    if (_telefono.text.trim() != original.telefono) {
      await _repo.actualizarDatos(
        original.uid,
        telefono: _telefono.text,
        autor: autor,
      );
    }

    final rolesNuevos = _roles.toList(growable: false);
    if (!_mismosRoles(rolesNuevos, original.roles)) {
      await _repo.actualizarRoles(original.uid, rolesNuevos, autor: autor);
    }

    if (_activo != original.activo) {
      await _repo.actualizarActivo(original.uid, _activo, autor: autor);
    }
  }

  static bool _mismosRoles(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    final conjunto = b.toSet();
    return a.every(conjunto.contains);
  }

  Future<void> _mostrarCreado(ResultadoCrearUsuario resultado) async {
    final enlace = resultado.enlaceActivacion;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Usuario creado'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Se creó la cuenta de "${_nombre.text.trim()}".'),
            const SizedBox(height: 8),
            const Text(
              'El usuario debe definir su contraseña. Compártele el enlace de '
              'activación:',
            ),
            const SizedBox(height: 8),
            if (enlace != null)
              SelectableText(
                enlace,
                style: Theme.of(context).textTheme.bodySmall,
              )
            else
              Text(
                'No se pudo generar el enlace. Pídele que use "¿Olvidaste tu '
                'contraseña?" en la pantalla de ingreso.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            if (resultado.desdeRespaldo) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                'Nota: se usó el respaldo local porque la Cloud Function no '
                'estaba disponible.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
        actions: <Widget>[
          if (enlace != null)
            TextButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: enlace));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Enlace copiado.')),
                  );
                }
              },
              icon: const Icon(Icons.copy, size: 18),
              label: const Text('Copiar'),
            ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  /// Genera un enlace de restablecimiento de contraseña para el usuario
  /// (spec 001). Sirve aunque el correo no exista: el enlace se copia.
  Future<void> _restablecerContrasena() async {
    final u = widget.usuario;
    if (u == null) return;
    final nombre = u.nombre.isEmpty ? u.email : u.nombre;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restablecer contraseña'),
        content: Text(
          'Se generará un enlace para que "$nombre" defina una contraseña '
          'nueva.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Generar enlace'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _restableciendo = true);
    try {
      final enlace =
          await _repo.restablecerContrasena(email: u.email, uid: u.uid);
      if (!mounted) return;
      await _mostrarEnlace(enlace, u.email);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = _mensajeDeError(e));
    } finally {
      if (mounted) setState(() => _restableciendo = false);
    }
  }

  /// Muestra el enlace generado (copiable) o confirma que se envió por correo.
  Future<void> _mostrarEnlace(String? enlace, String email) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restablecer contraseña'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (enlace != null) ...<Widget>[
              const Text(
                'Comparte este enlace para que defina su contraseña:',
              ),
              const SizedBox(height: 8),
              SelectableText(
                enlace,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ] else
              Text('Se envió un enlace de restablecimiento a $email.'),
          ],
        ),
        actions: <Widget>[
          if (enlace != null)
            TextButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: enlace));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Enlace copiado.')),
                  );
                }
              },
              icon: const Icon(Icons.copy, size: 18),
              label: const Text('Copiar'),
            ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  String _mensajeDeError(Object e) {    final texto = e.toString();
    if (texto.contains('already-exists')) {
      return 'Ese correo ya está registrado.';
    }
    if (texto.contains('failed-precondition')) {
      return 'No se pudo crear el usuario: revisa el límite de usuarios de tu '
          'plan o los datos de la empresa.';
    }
    if (texto.contains('permission-denied')) {
      return 'No tienes permisos para gestionar usuarios.';
    }
    if (texto.contains('network') || texto.contains('unavailable')) {
      return 'No hay conexión. Revisa tu red e inténtalo de nuevo.';
    }
    if (texto.contains('ArgumentError')) {
      return texto.replaceFirst(RegExp(r'^.*ArgumentError:\s*'), '');
    }
    return 'No se pudo guardar el usuario: $e';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_esEdicion ? 'Editar usuario' : 'Nuevo usuario'),
      ),
      body: AbsorbPointer(
        absorbing: _guardando,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              _Seccion(
                titulo: 'Datos del usuario',
                icono: Icons.person_outline,
              ),
              _campo(_nombre, 'Nombre *', obligatorio: true),
              _campo(
                _email,
                'Correo (acceso) *',
                obligatorio: true,
                tipo: TextInputType.emailAddress,
                validadorEmail: true,
                habilitado: !_esEdicion,
                ayuda: _esEdicion
                    ? 'El correo de acceso no se cambia desde aquí.'
                    : null,
              ),
              _campo(_telefono, 'Teléfono', tipo: TextInputType.phone),
              const SizedBox(height: 8),
              if (_requiereEmpresa) ...<Widget>[
                _Seccion(
                  titulo: 'Empresa',
                  icono: Icons.business_outlined,
                ),
                _selectorEmpresa(theme),
                const SizedBox(height: 8),
              ],
              _Seccion(titulo: 'Roles', icono: Icons.badge_outlined),
              Text(
                'Selecciona uno o varios. Los permisos son la unión de todos '
                'los roles.',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  for (final rol in _rolesDisponibles)
                    FilterChip(
                      label: Text(rol.nombre),
                      selected: _roles.contains(rol.id),
                      onSelected: (_) => _alternarRol(rol),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Usuario activo'),
                subtitle: const Text(
                  'Si se desactiva, el usuario no puede ingresar.',
                ),
                value: _activo,
                onChanged: (valor) => setState(() => _activo = valor),
              ),
              if (_error != null) ...<Widget>[
                const SizedBox(height: 16),
                _MensajeError(mensaje: _error!),
              ],
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
                label: Text(
                  _guardando
                      ? 'Guardando…'
                      : (_esEdicion ? 'Guardar cambios' : 'Crear usuario'),
                ),
              ),
              if (_esEdicion) ...<Widget>[
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _restableciendo ? null : _restablecerContrasena,
                  icon: _restableciendo
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.lock_reset_outlined),
                  label: const Text('Restablecer contraseña'),
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _selectorEmpresa(ThemeData theme) {
    if (_cargandoEmpresas) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: LinearProgressIndicator(),
      );
    }
    if (_empresas.isEmpty) {
      return Text(
        'No se encontraron empresas activas.',
        style: theme.textTheme.bodySmall,
      );
    }
    return DropdownButtonFormField<String>(
      initialValue: _empresas.any((e) => e.id == _empresaId) ? _empresaId : null,
      decoration: const InputDecoration(
        labelText: 'Empresa *',
        border: OutlineInputBorder(),
      ),
      items: <DropdownMenuItem<String>>[
        for (final empresa in _empresas)
          DropdownMenuItem<String>(
            value: empresa.id,
            child: Text(empresa.nombre),
          ),
      ],
      onChanged: (valor) => setState(() => _empresaId = valor),
      validator: (valor) =>
          (valor == null || valor.isEmpty) ? 'Selecciona la empresa.' : null,
    );
  }

  Widget _campo(
    TextEditingController controller,
    String etiqueta, {
    bool obligatorio = false,
    bool validadorEmail = false,
    bool habilitado = true,
    String? ayuda,
    TextInputType? tipo,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        enabled: habilitado,
        keyboardType: tipo,
        decoration: InputDecoration(
          labelText: etiqueta,
          helperText: ayuda,
          border: const OutlineInputBorder(),
        ),
        validator: (String? valor) {
          final texto = (valor ?? '').trim();
          if (obligatorio && texto.isEmpty) return 'Campo obligatorio.';
          if (validadorEmail &&
              texto.isNotEmpty &&
              !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(texto)) {
            return 'Correo no válido.';
          }
          return null;
        },
      ),
    );
  }
}

class _Seccion extends StatelessWidget {
  const _Seccion({required this.titulo, required this.icono});

  final String titulo;
  final IconData icono;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      child: Row(
        children: <Widget>[
          Icon(icono, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            titulo,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _MensajeError extends StatelessWidget {
  const _MensajeError({required this.mensaje});

  final String mensaje;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.error_outline, color: scheme.onErrorContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              mensaje,
              style: TextStyle(color: scheme.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}

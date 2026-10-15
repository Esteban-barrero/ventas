import 'package:flutter/material.dart';

import '../../firebase_options.dart';
import '../auth/domain/permisos.dart';
import '../auth/domain/roles.dart';
import '../auth/domain/usuario.dart';
import '../licencia/domain/licencia.dart';
import '../licencia/presentation/aviso_licencia.dart';

/// Pantalla de inicio (esqueleto). Muestra el usuario autenticado, sus roles y
/// los modulos a los que tiene permiso. Ver spec 001.
class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
    required this.usuario,
    required this.onCerrarSesion,
    this.avisoLicencia,
  });

  final Usuario usuario;
  final Future<void> Function() onCerrarSesion;

  /// Si la licencia esta por vencer, se muestra un aviso (RN-06).
  final EstadoLicencia? avisoLicencia;

  static const List<_Modulo> _todosLosModulos = <_Modulo>[
    _Modulo('Catálogo', Icons.inventory_2_outlined, Permiso.catalogoVer),
    _Modulo('Clientes', Icons.people_outline, Permiso.clientesVer),
    _Modulo('Ventas', Icons.point_of_sale_outlined, Permiso.ventasVer),
    _Modulo('Inventario', Icons.warehouse_outlined, Permiso.inventarioVer),
    _Modulo('Caja', Icons.account_balance_wallet_outlined, Permiso.cajaVer),
    _Modulo('Reportes', Icons.bar_chart_outlined, Permiso.reportesVer),
    _Modulo('Logs de errores', Icons.bug_report_outlined, Permiso.logsVer),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    // Solo los modulos para los que el usuario tiene permiso.
    final modulos = _todosLosModulos
        .where((m) => usuario.puede(m.permiso))
        .toList(growable: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Aplicativo de Ventas'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: () async => onCerrarSesion(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          _Encabezado(usuario: usuario, scheme: scheme),
          const SizedBox(height: 16),
          if (avisoLicencia != null) ...<Widget>[
            AvisoLicencia(estado: avisoLicencia!),
            const SizedBox(height: 16),
          ],
          _TarjetaRoles(usuario: usuario),
          const SizedBox(height: 24),
          Text('Módulos', style: theme.textTheme.titleLarge),
          const SizedBox(height: 12),
          if (modulos.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('No tienes módulos habilitados.'),
              ),
            )
          else
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: <Widget>[
                for (final m in modulos)
                  Card(
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => _proximamente(context, m.nombre),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Icon(m.icono, size: 40, color: scheme.primary),
                          const SizedBox(height: 8),
                          Text(m.nombre, style: theme.textTheme.titleMedium),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              'Proyecto: ${DefaultFirebaseOptions.currentPlatform.projectId}',
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  void _proximamente(BuildContext context, String nombre) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$nombre: módulo en construcción')),
    );
  }
}

/// Encabezado con avatar, nombre y correo.
class _Encabezado extends StatelessWidget {
  const _Encabezado({required this.usuario, required this.scheme});

  final Usuario usuario;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iniciales = _iniciales(usuario.nombre.isEmpty
        ? usuario.email
        : usuario.nombre);

    return Row(
      children: <Widget>[
        CircleAvatar(
          radius: 32,
          backgroundColor: scheme.primary,
          child: Text(
            iniciales,
            style: theme.textTheme.titleLarge?.copyWith(
              color: scheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                usuario.nombre.isEmpty ? 'Usuario' : usuario.nombre,
                style: theme.textTheme.titleLarge,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                usuario.email,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.secondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  static String _iniciales(String texto) {
    final partes =
        texto.trim().split(RegExp(r'[\s@._-]+')).where((p) => p.isNotEmpty);
    if (partes.isEmpty) return '?';
    return partes.take(2).map((p) => p[0].toUpperCase()).join();
  }
}

/// Tarjeta con los roles del usuario y cuantos permisos tiene.
class _TarjetaRoles extends StatelessWidget {
  const _TarjetaRoles({required this.usuario});

  final Usuario usuario;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final roles = usuario.rolesTipados;

    return Card(
      color: scheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(Icons.badge_outlined, color: scheme.primary, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Roles asignados',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (roles.isEmpty)
              const Text('Sin rol asignado')
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  for (final rol in roles)
                    Chip(
                      avatar: Icon(
                        rol == Rol.developer
                            ? Icons.code
                            : Icons.verified_user_outlined,
                        size: 18,
                      ),
                      label: Text(rol.nombre),
                      backgroundColor: scheme.surface,
                    ),
                ],
              ),
            const SizedBox(height: 12),
            Text(
              'Permisos efectivos: ${usuario.permisos.length} '
              '· Empresa: ${(usuario.empresaId == null || usuario.empresaId!.isEmpty) ? "sin asignar" : usuario.empresaId}',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _Modulo {
  const _Modulo(this.nombre, this.icono, this.permiso);

  final String nombre;
  final IconData icono;
  final Permiso permiso;
}

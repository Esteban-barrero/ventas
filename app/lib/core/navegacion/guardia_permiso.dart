import 'package:flutter/material.dart';

import '../../features/auth/domain/permisos.dart';
import '../../features/auth/domain/usuario.dart';
import '../avisos/marco_aviso.dart';

/// Guardas de navegación por permisos (spec 001, T023 / RF-06).
///
/// Doble protección:
/// 1. [irAProtegido] no navega si el usuario no tiene el permiso (evita que
///    siquiera se abra la pantalla desde la interfaz).
/// 2. [RutaProtegida] vuelve a comprobarlo al construir la pantalla, de modo
///    que un acceso directo (deep link, restauración de ruta) tampoco pase.

/// Navega a [constructor] solo si [usuario] tiene [permiso].
///
/// Si no lo tiene, muestra un aviso y no navega.
void irAProtegido(
  BuildContext context, {
  required Usuario usuario,
  required Permiso permiso,
  required WidgetBuilder constructor,
}) {
  if (!usuario.puede(permiso)) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text('No tienes acceso a "${permiso.etiqueta}".'),
      ),
    );
    return;
  }

  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (context) => RutaProtegida(
        usuario: usuario,
        permiso: permiso,
        child: constructor(context),
      ),
    ),
  );
}

/// Envuelve una pantalla y solo la muestra si el usuario tiene el permiso.
///
/// Pensado para usarse como segunda barrera dentro de cada ruta protegida.
class RutaProtegida extends StatelessWidget {
  const RutaProtegida({
    super.key,
    required this.usuario,
    required this.permiso,
    required this.child,
  });

  final Usuario usuario;
  final Permiso permiso;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!usuario.puede(permiso)) {
      return AccesoDenegadoScreen(permiso: permiso);
    }
    return child;
  }
}

/// Pantalla mostrada cuando un usuario intenta entrar a un módulo sin permiso.
class AccesoDenegadoScreen extends StatelessWidget {
  const AccesoDenegadoScreen({super.key, required this.permiso});

  final Permiso permiso;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Acceso restringido')),
      body: MarcoAviso(
        icono: Icons.lock_outline,
        titulo: 'No tienes acceso a este módulo',
        mensaje: 'Tu rol actual no incluye el permiso '
            '"${permiso.etiqueta}".',
        detalleExtra: 'Si crees que es un error, contacta al administrador '
            'de tu empresa.',
        acciones: <Widget>[
          FilledButton.icon(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Volver'),
          ),
        ],
      ),
    );
  }
}

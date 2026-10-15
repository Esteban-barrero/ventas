import 'usuario.dart';

/// Resultado de cargar el perfil: el usuario y si vino de la cache local.
///
/// [desdeCache] es `true` cuando no hubo conexion y se uso la copia guardada
/// en el dispositivo (spec 001, T014).
class PerfilCargado {
  const PerfilCargado({required this.usuario, this.desdeCache = false});

  final Usuario usuario;
  final bool desdeCache;
}

import '../../../core/validacion/correo.dart';
import 'cliente.dart';

/// Validaciones de un cliente (spec 004, RN-01, RN-02, RN-03).
///
/// Devuelve la lista de errores; vacía si el cliente es válido. La unicidad de
/// la cédula se comprueba contra [existentes] (los de la misma empresa),
/// excluyendo el propio documento al editar ([exceptoId]).
List<String> validarCliente(
  Cliente cliente, {
  List<Cliente> existentes = const <Cliente>[],
  String? exceptoId,
}) {
  final errores = <String>[];

  if (cliente.nombreCompleto.trim().isEmpty) {
    errores.add('El nombre completo es obligatorio.');
  }
  if (cliente.cedula.trim().isEmpty) {
    errores.add('La cédula es obligatoria.');
  }
  if (cliente.telefono.trim().isEmpty) {
    errores.add('El teléfono es obligatorio.');
  } else if (!telefonoValido(cliente.telefono)) {
    errores.add('El teléfono no tiene un formato válido.');
  }

  final d = cliente.direccion;
  if (d.departamento.trim().isEmpty) {
    errores.add('El departamento es obligatorio.');
  }
  if (d.ciudad.trim().isEmpty) {
    errores.add('La ciudad es obligatoria.');
  }
  if (d.direccion.trim().isEmpty) {
    errores.add('La dirección es obligatoria.');
  }

  if (cliente.correo.trim().isNotEmpty && !esCorreoValido(cliente.correo)) {
    errores.add('El correo no es válido.');
  }

  final cedula = cliente.cedula.trim().toLowerCase();
  final duplicada = existentes.any((Cliente e) =>
      e.id != exceptoId && e.cedula.trim().toLowerCase() == cedula);
  if (duplicada) {
    errores.add('Ya existe un cliente con esa cédula.');
  }

  return errores;
}

/// `true` si el teléfono tiene al menos 7 dígitos (RN-03).
bool telefonoValido(String telefono) {
  final digitos = telefono.replaceAll(RegExp(r'[^0-9]'), '');
  return digitos.length >= 7;
}

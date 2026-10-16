import 'permisos.dart';

/// Roles del sistema (RBAC). Ver spec 001.
///
/// Un usuario puede tener **varios** roles; sus permisos efectivos son la
/// UNION de los permisos de todos sus roles (ver [permisosDeRoles]).
enum Rol {
  superAdmin('superadmin', 'Super Admin'),
  administrador('administrador', 'Administrador'),
  gerente('gerente', 'Gerente'),
  vendedor('vendedor', 'Vendedor'),
  marketing('marketing', 'Marketing'),
  cajero('cajero', 'Cajero'),
  domiciliario('domiciliario', 'Domiciliario'),
  cliente('cliente', 'Cliente'),
  invitado('invitado', 'Invitado'),
  developer('developer', 'Developer');

  const Rol(this.id, this.nombre);

  /// Identificador que se persiste en Firestore (`usuarios.roles`).
  final String id;

  /// Nombre visible.
  final String nombre;

  /// Permisos que otorga este rol.
  Set<Permiso> get permisos => switch (this) {
        // Acceso global a todo.
        Rol.superAdmin => Permiso.values.toSet(),

        // Acceso total dentro de su empresa (menos gestion global de empresas
        // y los logs de errores, que son del proveedor).
        Rol.administrador => Permiso.values
            .where((p) =>
                p != Permiso.empresasGestionar && p != Permiso.logsVer)
            .toSet(),

        // Reportes, supervision y aprobaciones.
        Rol.gerente => <Permiso>{
            Permiso.catalogoVer,
            Permiso.clientesVer,
            Permiso.ventasVer,
            Permiso.inventarioVer,
            Permiso.cajaVer,
            Permiso.creditosVer,
            Permiso.comprasVer,
            Permiso.enviosVer,
            Permiso.pedidosVer,
            Permiso.reportesVer,
            Permiso.auditoriaVer,
          },

        // Ventas y sus clientes.
        Rol.vendedor => <Permiso>{
            Permiso.catalogoVer,
            Permiso.clientesVer,
            Permiso.clientesEditar,
            Permiso.ventasVer,
            Permiso.ventasCrear,
            Permiso.creditosVer,
            Permiso.enviosVer,
            Permiso.pedidosVer,
          },

        // Catalogo y promociones.
        Rol.marketing => <Permiso>{
            Permiso.catalogoVer,
            Permiso.catalogoEditar,
            Permiso.clientesVer,
            Permiso.pedidosVer,
          },

        // Caja y cobros.
        Rol.cajero => <Permiso>{
            Permiso.clientesVer,
            Permiso.ventasVer,
            Permiso.cajaVer,
            Permiso.cajaOperar,
            Permiso.creditosVer,
            Permiso.creditosEditar,
          },

        // Entregas y cobros en la calle (spec 011, MVP "pendientes por
        // entregar"): ve clientes, gestiona envíos y opera su caja para rendir.
        Rol.domiciliario => <Permiso>{
            Permiso.clientesVer,
            Permiso.enviosVer,
            Permiso.enviosEditar,
            Permiso.cajaVer,
            Permiso.cajaOperar,
            Permiso.creditosVer,
          },

        // Compra y consulta de sus propios pedidos.
        Rol.cliente => <Permiso>{
            Permiso.catalogoVer,
            Permiso.pedidosVer,
            Permiso.pedidosCrear,
          },

        // Solo catalogo.
        Rol.invitado => <Permiso>{Permiso.catalogoVer},

        // Solo logs de errores (no accede a datos del negocio).
        Rol.developer => <Permiso>{Permiso.logsVer},
      };

  /// Roles que se pueden asignar desde la gestión de usuarios (spec 001,
  /// CA-06).
  ///
  /// Se excluye [Rol.superAdmin]: ese rol pertenece al proveedor del
  /// aplicativo y no a una empresa (RN-04), así que no se reparte desde la
  /// interfaz de una empresa.
  static List<Rol> get asignables =>
      values.where((Rol r) => r != Rol.superAdmin).toList(growable: false);

  /// Devuelve el rol con ese id, o `null` si no existe.
  static Rol? desdeId(String id) {
    for (final r in values) {
      if (r.id == id) return r;
    }
    return null;
  }
}

/// Permisos efectivos = union de los permisos de todos los roles.
Set<Permiso> permisosDeRoles(Iterable<Rol> roles) {
  final resultado = <Permiso>{};
  for (final rol in roles) {
    resultado.addAll(rol.permisos);
  }
  return resultado;
}

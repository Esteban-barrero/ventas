/// Codigos de permiso del sistema (RBAC). Ver spec 001.
///
/// Los permisos se agrupan por modulo (`modulo.accion`). El permiso efectivo
/// de un usuario es la UNION de los permisos de todos sus roles.
enum Permiso {
  // Catalogo
  catalogoVer('catalogo.ver', 'Ver catálogo'),
  catalogoEditar('catalogo.editar', 'Editar catálogo'),

  // Clientes
  clientesVer('clientes.ver', 'Ver clientes'),
  clientesEditar('clientes.editar', 'Gestionar clientes'),

  // Ventas
  ventasVer('ventas.ver', 'Ver ventas'),
  ventasCrear('ventas.crear', 'Registrar ventas'),
  ventasAnular('ventas.anular', 'Anular ventas'),

  // Inventario
  inventarioVer('inventario.ver', 'Ver inventario'),
  inventarioEditar('inventario.editar', 'Gestionar inventario'),

  // Caja
  cajaVer('caja.ver', 'Ver caja'),
  cajaOperar('caja.operar', 'Operar caja'),

  // Creditos y cobros
  creditosVer('creditos.ver', 'Ver créditos'),
  creditosEditar('creditos.editar', 'Gestionar créditos'),

  // Proveedores y compras
  comprasVer('compras.ver', 'Ver compras'),
  comprasEditar('compras.editar', 'Gestionar compras'),

  // Envios
  enviosVer('envios.ver', 'Ver envíos'),
  enviosEditar('envios.editar', 'Gestionar envíos'),

  // Pedidos
  pedidosVer('pedidos.ver', 'Ver pedidos'),
  pedidosCrear('pedidos.crear', 'Crear pedidos'),

  // Reportes
  reportesVer('reportes.ver', 'Ver reportes'),

  // Administracion
  usuariosGestionar('usuarios.gestionar', 'Gestionar usuarios'),
  empresasGestionar('empresas.gestionar', 'Gestionar empresas'),
  parametrosEditar('parametros.editar', 'Editar parámetros'),
  auditoriaVer('auditoria.ver', 'Ver auditoría'),

  // Solo Developer
  logsVer('logs.ver', 'Ver logs de errores');

  const Permiso(this.codigo, this.etiqueta);

  /// Codigo unico del permiso (se persiste en Firestore/custom claims).
  final String codigo;

  /// Nombre legible para mostrar al usuario.
  final String etiqueta;

  /// Devuelve el permiso con ese codigo, o `null` si no existe.
  static Permiso? desdeCodigo(String codigo) {
    for (final p in values) {
      if (p.codigo == codigo) return p;
    }
    return null;
  }
}

import 'package:flutter/material.dart';

import '../domain/licencia.dart';

/// Pantalla de licencia agotada / acceso bloqueado (spec 001, T022).
///
/// Se muestra con un tono suave (no de alarma) y un mensaje cordial que invita
/// a comunicarse con el proveedor para renovar la licencia (RF-09, RN-05).
class LicenciaBloqueadaScreen extends StatelessWidget {
  const LicenciaBloqueadaScreen({
    super.key,
    required this.estado,
    required this.onCerrarSesion,
    this.onReintentar,
  });

  final EstadoLicencia estado;
  final Future<void> Function() onCerrarSesion;
  final Future<void> Function()? onReintentar;

  @override
  Widget build(BuildContext context) {
    return _MarcoLicencia(
      titulo: 'Tu licencia se ha agotado',
      mensaje: 'Comunícate con tu proveedor para renovarla y recuperar el '
          'acceso.',
      detalleExtra: 'Todos los usuarios de la empresa volverán a ingresar '
          'cuando se renueve la licencia.',
      onCerrarSesion: onCerrarSesion,
      onReintentar: onReintentar,
      cuerpo: <Widget>[
        _DetalleLicencia(estado: estado),
        const SizedBox(height: 16),
        _ContactoProveedor(contacto: estado.contactoProveedor),
      ],
    );
  }
}

/// Pantalla mostrada cuando no se puede verificar la licencia.
class LicenciaNoDisponibleScreen extends StatelessWidget {
  const LicenciaNoDisponibleScreen({
    super.key,
    required this.detalle,
    required this.onCerrarSesion,
    this.onReintentar,
  });

  final String detalle;
  final Future<void> Function() onCerrarSesion;
  final Future<void> Function()? onReintentar;

  @override
  Widget build(BuildContext context) {
    return _MarcoLicencia(
      titulo: 'No pudimos verificar tu licencia',
      mensaje: detalle,
      detalleExtra: 'Comunícate con tu proveedor si el problema continúa.',
      onCerrarSesion: onCerrarSesion,
      onReintentar: onReintentar,
    );
  }
}

/// Estructura visual compartida de las pantallas de bloqueo.
///
/// Usa tonos ámbar suaves (nada de rojo) para que el mensaje resulte amable.
class _MarcoLicencia extends StatelessWidget {
  const _MarcoLicencia({
    required this.titulo,
    required this.mensaje,
    required this.detalleExtra,
    required this.onCerrarSesion,
    this.onReintentar,
    this.cuerpo = const <Widget>[],
  });

  final String titulo;
  final String mensaje;
  final String detalleExtra;
  final Future<void> Function() onCerrarSesion;
  final Future<void> Function()? onReintentar;
  final List<Widget> cuerpo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final acentos = _AcentosLicencia.de(theme.brightness);

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: acentos.fondo,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.hourglass_bottom,
                    size: 44,
                    color: acentos.icono,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  titulo,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  mensaje,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  detalleExtra,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                ...cuerpo,
                const SizedBox(height: 24),
                Row(
                  children: <Widget>[
                    if (onReintentar != null)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async => onReintentar!(),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reintentar'),
                        ),
                      ),
                    if (onReintentar != null) const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () async => onCerrarSesion(),
                        icon: const Icon(Icons.logout),
                        label: const Text('Cerrar sesión'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Colores suaves (ámbar) para las pantallas de bloqueo.
class _AcentosLicencia {
  const _AcentosLicencia({required this.icono, required this.fondo});

  final Color icono;
  final Color fondo;

  factory _AcentosLicencia.de(Brightness brightness) {
    if (brightness == Brightness.dark) {
      return const _AcentosLicencia(
        icono: Color(0xFFFFCC80),
        fondo: Color(0xFF4E342E),
      );
    }
    return const _AcentosLicencia(
      icono: Color(0xFFE65100),
      fondo: Color(0xFFFFF3E0),
    );
  }
}

/// Fechas y dias restantes de la licencia.
class _DetalleLicencia extends StatelessWidget {
  const _DetalleLicencia({required this.estado});

  final EstadoLicencia estado;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[
      if (estado.fechaInicio != null)
        _fila('Fecha de inicio', _fecha(estado.fechaInicio)),
      if (estado.fechaFin != null)
        _fila('Fecha de vencimiento', _fecha(estado.fechaFin)),
      // Solo se muestran los días cuando ya venció: si está suspendida con
      // días por delante, mostrarlos confundiría con el mensaje.
      if (estado.diasRestantes != null && estado.diasRestantes! < 0)
        _fila(
          'Vencida hace',
          '${estado.diasRestantes!.abs()} día(s)',
        ),
    ];

    if (rows.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: rows,
        ),
      ),
    );
  }

  Widget _fila(String etiqueta, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(child: Text(etiqueta)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              valor,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  static String _fecha(DateTime? f) {
    if (f == null) return '—';
    final d = f.day.toString().padLeft(2, '0');
    final m = f.month.toString().padLeft(2, '0');
    return '$d/$m/${f.year}';
  }
}

/// Tarjeta con el contacto del proveedor (RF-09).
class _ContactoProveedor extends StatelessWidget {
  const _ContactoProveedor({required this.contacto});

  final String contacto;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(Icons.support_agent, color: scheme.primary),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Contacto del proveedor',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              contacto.isEmpty
                  ? 'No hay un contacto configurado.'
                  : contacto,
            ),
          ],
        ),
      ),
    );
  }
}

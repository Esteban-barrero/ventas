import 'package:flutter/material.dart';

import '../domain/licencia.dart';

/// Pantalla de "Licencia vencida / empresa suspendida" (spec 001, T022).
///
/// Muestra el motivo, las fechas de la licencia y el contacto del proveedor,
/// para que el usuario sepa que debe renovar (RF-09, RN-05).
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  estado.estado == EstadoEmpresa.suspendida
                      ? Icons.block
                      : Icons.event_busy,
                  size: 64,
                  color: scheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  estado.estado == EstadoEmpresa.suspendida
                      ? 'Empresa suspendida'
                      : 'Licencia vencida',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  estado.motivoBloqueo,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'El acceso queda bloqueado para todos los usuarios de la '
                  'empresa hasta que se renueve la licencia.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: 24),
                _DetalleLicencia(estado: estado),
                const SizedBox(height: 16),
                _ContactoProveedor(contacto: estado.contactoProveedor),
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(Icons.gpp_maybe_outlined, size: 64, color: scheme.error),
                const SizedBox(height: 16),
                Text(
                  'No se pudo verificar la licencia',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  detalle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Por seguridad no se permite el ingreso. Si el problema '
                  'continúa, contacta al proveedor del aplicativo.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
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

/// Fechas y dias restantes de la licencia.
class _DetalleLicencia extends StatelessWidget {
  const _DetalleLicencia({required this.estado});

  final EstadoLicencia estado;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[
      _fila('Fecha de inicio', _fecha(estado.fechaInicio)),
      _fila('Fecha de vencimiento', _fecha(estado.fechaFin)),
      if (estado.diasRestantes != null)
        _fila(
          'Días restantes',
          estado.diasRestantes! < 0
              ? 'vencida hace ${estado.diasRestantes!.abs()} día(s)'
              : '${estado.diasRestantes} día(s)',
        ),
    ];

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
      color: scheme.primaryContainer,
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
                    'Contacta al proveedor',
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

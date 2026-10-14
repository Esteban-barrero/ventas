import 'package:flutter/material.dart';

/// Pantalla de inicio (esqueleto) con los modulos principales.
///
/// Es una prueba inicial de la aplicacion; los modulos se iran implementando
/// segun las specs 001-015.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const List<_Modulo> _modulos = <_Modulo>[
    _Modulo('Catálogo', Icons.inventory_2_outlined),
    _Modulo('Clientes', Icons.people_outline),
    _Modulo('Ventas', Icons.point_of_sale_outlined),
    _Modulo('Inventario', Icons.warehouse_outlined),
    _Modulo('Caja', Icons.account_balance_wallet_outlined),
    _Modulo('Reportes', Icons.bar_chart_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Aplicativo de Ventas')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          _Encabezado(scheme: scheme),
          const SizedBox(height: 24),
          Text('Módulos', style: theme.textTheme.titleLarge),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: <Widget>[
              for (final m in _modulos)
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

class _Encabezado extends StatelessWidget {
  const _Encabezado({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: <Widget>[
        CircleAvatar(
          radius: 32,
          backgroundColor: scheme.primary,
          child: Text(
            'AV',
            style: theme.textTheme.headlineSmall?.copyWith(
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
              Text('Mi Empresa', style: theme.textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(
                'Aplicativo de Ventas · Multitenant',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.secondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Modulo {
  const _Modulo(this.nombre, this.icono);

  final String nombre;
  final IconData icono;
}

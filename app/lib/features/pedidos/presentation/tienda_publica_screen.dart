import 'package:flutter/material.dart';

import '../../empresas/data/empresas_repository.dart';
import '../../empresas/domain/empresa.dart';
import '../../empresas/presentation/widgets/logo_empresa.dart';
import 'catalogo_tienda_screen.dart';

/// Selector público de tiendas (spec 010). Sin sesión, el invitado ve las
/// empresas; si hay una sola, entra directo a su catálogo.
class TiendaPublicaScreen extends StatefulWidget {
  const TiendaPublicaScreen({
    super.key,
    required this.onIngresar,
    this.empresasRepository,
  });

  /// Abre el login para el personal.
  final VoidCallback onIngresar;

  final EmpresasRepository? empresasRepository;

  @override
  State<TiendaPublicaScreen> createState() => _TiendaPublicaScreenState();
}

class _TiendaPublicaScreenState extends State<TiendaPublicaScreen> {
  late final EmpresasRepository _repo =
      widget.empresasRepository ?? EmpresasRepository();

  List<Empresa> _empresas = const <Empresa>[];
  String _busqueda = '';
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final lista = await _repo.listar();
      final activas = lista
          .where((Empresa e) => e.nombre.trim().isNotEmpty)
          .toList(growable: false)
        ..sort((Empresa a, Empresa b) =>
            a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));
      if (!mounted) return;
      setState(() {
        _empresas = activas;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudieron cargar las tiendas: $e';
        _cargando = false;
      });
    }
  }

  void _abrir(Empresa empresa) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => CatalogoTiendaScreen(
          empresa: empresa,
          onIngresar: widget.onIngresar,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tienda'),
        actions: <Widget>[
          TextButton.icon(
            onPressed: widget.onIngresar,
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
            icon: const Icon(Icons.login),
            label: const Text('Iniciar sesión'),
          ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(_error!, textAlign: TextAlign.center),
                  ),
                )
              : _empresas.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('No hay tiendas disponibles todavía.'),
                      ),
                    )
                  : _empresas.length == 1
                      ? CatalogoTiendaScreen(
                          empresa: _empresas.first,
                          onIngresar: widget.onIngresar,
                        )
                      : _lista(),
    );
  }

  Widget _lista() {
    final q = _busqueda.trim().toLowerCase();
    final visibles = _empresas
        .where((Empresa e) => q.isEmpty || e.nombre.toLowerCase().contains(q))
        .toList(growable: false);

    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            onChanged: (v) => setState(() => _busqueda = v),
            decoration: const InputDecoration(
              hintText: 'Buscar tienda',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ),
        Expanded(
          child: visibles.isEmpty
              ? const Center(child: Text('No se encontraron tiendas.'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: visibles.length,
                  itemBuilder: (context, i) {
                    final e = visibles[i];
                    return Card(
                      child: ListTile(
                        leading: LogoEmpresa(empresa: e, radio: 26),
                        title: Text(e.nombre),
                        subtitle: Text(
                          e.parametros.ciudades.isEmpty
                              ? 'Ver catálogo'
                              : e.parametros.ciudades.join(' · '),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _abrir(e),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

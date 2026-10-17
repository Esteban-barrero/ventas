import 'package:flutter/material.dart';

import '../../auth/domain/usuario.dart';
import '../../empresas/data/empresas_repository.dart';
import '../../empresas/domain/empresa.dart';
import 'catalogo_tienda_screen.dart';

/// **Tienda** para un cliente logueado (spec 010). Carga su empresa y muestra el
/// mismo catálogo de la tienda pública, con acceso a "Mis pedidos".
class MiTiendaScreen extends StatefulWidget {
  const MiTiendaScreen({
    super.key,
    required this.usuario,
    this.empresasRepository,
  });

  final Usuario usuario;
  final EmpresasRepository? empresasRepository;

  @override
  State<MiTiendaScreen> createState() => _MiTiendaScreenState();
}

class _MiTiendaScreenState extends State<MiTiendaScreen> {
  late final EmpresasRepository _repo =
      widget.empresasRepository ?? EmpresasRepository();

  Empresa? _empresa;
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final empresaId = widget.usuario.empresaId ?? '';
    if (empresaId.isEmpty) {
      setState(() {
        _error = 'No perteneces a ninguna empresa.';
        _cargando = false;
      });
      return;
    }
    try {
      final empresa = await _repo.obtener(empresaId);
      if (!mounted) return;
      setState(() {
        _empresa = empresa;
        _cargando = false;
        if (empresa == null) _error = 'La empresa ya no existe.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudo cargar la tienda: $e';
        _cargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return Scaffold(
        appBar: AppBar(title: const Text('Tienda')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_empresa == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Tienda')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(_error ?? 'No hay tienda disponible.',
                textAlign: TextAlign.center),
          ),
        ),
      );
    }
    return CatalogoTiendaScreen(
      empresa: _empresa!,
      usuario: widget.usuario,
    );
  }
}

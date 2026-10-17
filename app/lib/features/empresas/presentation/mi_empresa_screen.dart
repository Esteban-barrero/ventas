import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/formato/fechas.dart';
import '../../../core/imagen/medir_imagen.dart';
import '../../tesoreria/data/tesoreria_repository.dart';
import '../../ventas/data/ventas_repository.dart';
import '../data/almacenamiento_repository.dart';
import '../data/empresas_repository.dart';
import '../domain/empresa.dart';
import 'widgets/estado_licencia_chip.dart';
import 'widgets/logo_empresa.dart';
import 'widgets/tarjeta_datos.dart';

/// Vista de la propia empresa (rol Administrador). Ver spec 002, RF-04 y RF-06.
///
/// Permite personalizar el logo y los parámetros, y consultar el estado de la
/// licencia. No permite renovar, suspender ni eliminar (eso es del Super Admin).
class MiEmpresaScreen extends StatefulWidget {
  const MiEmpresaScreen({
    super.key,
    required this.empresaId,
    this.repository,
    this.selectorImagen,
    this.tesoreriaRepository,
    this.ventasRepository,
  });

  final String empresaId;
  final EmpresasRepository? repository;
  final Future<XFile?> Function()? selectorImagen;
  final TesoreriaRepository? tesoreriaRepository;
  final VentasRepository? ventasRepository;

  @override
  State<MiEmpresaScreen> createState() => _MiEmpresaScreenState();
}

class _MiEmpresaScreenState extends State<MiEmpresaScreen> {
  late final EmpresasRepository _repo =
      widget.repository ?? EmpresasRepository();
  late final TesoreriaRepository _tesoreria =
      widget.tesoreriaRepository ?? TesoreriaRepository();
  late final VentasRepository _ventasRepo =
      widget.ventasRepository ?? VentasRepository();

  Empresa? _empresa;
  double _saldoInicial = 0;
  bool _tieneVentas = false;
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final empresa = await _repo.obtener(widget.empresaId);
      double saldo = 0;
      var hayVentas = false;
      try {
        final ap = await _tesoreria.apertura(widget.empresaId);
        saldo = ap?.monto ?? 0;
        hayVentas = await _ventasRepo.tieneVentas(widget.empresaId);
      } catch (_) {
        // Si falla, se muestra 0 y editable.
      }
      if (!mounted) return;
      setState(() {
        _empresa = empresa;
        _saldoInicial = saldo;
        _tieneVentas = hayVentas;
        _cargando = false;
        if (empresa == null) _error = 'La empresa ya no existe.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _cargando = false;
      });
    }
  }

  void _avisar(String mensaje, {bool error = false}) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: error ? Theme.of(context).colorScheme.error : null,
      ),
    );
  }

  Future<void> _cambiarLogo() async {
    final empresa = _empresa;
    if (empresa == null) return;

    try {
      final XFile? archivo = widget.selectorImagen != null
          ? await widget.selectorImagen!()
          : await ImagePicker().pickImage(
              source: ImageSource.gallery,
              maxWidth: 1024,
              maxHeight: 1024,
            );
      if (archivo == null) return;

      final bytes = await archivo.readAsBytes();
      final extension = archivo.name.contains('.')
          ? archivo.name.split('.').last.toLowerCase()
          : 'png';

      try {
        AlmacenamientoRepository.validarLogo(bytes, extension: extension);
      } on ArchivoInvalidoException catch (e) {
        if (mounted) _avisar(e.mensaje, error: true);
        return;
      }

      final dims = await medirImagen(bytes);
      await _repo.subirLogo(
        empresa.id,
        bytes,
        extension: extension,
        ancho: dims?.ancho ?? 0,
        alto: dims?.alto ?? 0,
      );
      await _cargar();
      if (mounted) _avisar('Logo actualizado.');
    } catch (e) {
      if (mounted) _avisar('No se pudo subir el logo: $e', error: true);
    }
  }

  /// Fija el **saldo inicial de caja** (spec 016, apertura). Se bloquea cuando
  /// la empresa ya tiene ventas.
  Future<void> _editarSaldoInicial() async {
    if (_tieneVentas) {
      _avisar('El saldo inicial está bloqueado: ya hay ventas registradas.',
          error: true);
      return;
    }
    final monto = TextEditingController(text: numeroParaEditar(_saldoInicial));
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Saldo inicial de caja'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Text(
                'Es el dinero con el que arranca la empresa (apertura). Queda '
                'bloqueado al registrar la primera venta.',
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: monto,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Monto',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final valor = parsearNumero(monto.text) ?? 0;
    if (valor < 0) {
      _avisar('El monto no puede ser negativo.', error: true);
      return;
    }
    try {
      await _tesoreria.fijarSaldoInicial(
        empresaId: widget.empresaId,
        monto: valor,
        usuarioUid: FirebaseAuth.instance.currentUser?.uid ?? '',
      );
      await _cargar();
      if (mounted) _avisar('Saldo inicial actualizado.');
    } catch (e) {
      if (mounted) _avisar('No se pudo guardar: $e', error: true);
    }
  }

  Future<void> _editarParametros() async {
    final empresa = _empresa;
    if (empresa == null) return;

    final p = empresa.parametros;
    final detal = TextEditingController(text: p.margenDetal.toStringAsFixed(0));
    final mayor = TextEditingController(text: p.margenMayor.toStringAsFixed(0));
    final distribuidor =
        TextEditingController(text: p.margenDistribuidor.toStringAsFixed(0));
    final envio = TextEditingController(text: p.costoEnvio.toStringAsFixed(0));
    final iva = TextEditingController(text: p.iva.toStringAsFixed(0));
    final reteFuente =
        TextEditingController(text: p.reteFuente.toStringAsFixed(0));
    final reteIva = TextEditingController(text: p.reteIva.toStringAsFixed(0));
    final reteIca = TextEditingController(text: p.reteIca.toStringAsFixed(0));
    final ciudades = TextEditingController(text: p.ciudades.join(', '));
    final whatsapp = TextEditingController(text: p.whatsappPedidos);

    final guardar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Parámetros'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: detal,
                keyboardType: TextInputType.number,
                decoration:
                    const InputDecoration(labelText: 'Margen detal (%)'),
              ),
              TextField(
                controller: mayor,
                keyboardType: TextInputType.number,
                decoration:
                    const InputDecoration(labelText: 'Margen mayor (%)'),
              ),
              TextField(
                controller: distribuidor,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'Margen distribuidores (%)'),
              ),
              TextField(
                controller: envio,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Costo de envío'),
              ),
              TextField(
                controller: iva,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'IVA (%)'),
              ),
              TextField(
                controller: reteFuente,
                keyboardType: TextInputType.number,
                decoration:
                    const InputDecoration(labelText: 'Retención fuente (%)'),
              ),
              TextField(
                controller: reteIva,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'ReteIVA (%)'),
              ),
              TextField(
                controller: reteIca,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'ReteICA (%)'),
              ),
              TextField(
                controller: ciudades,
                decoration: const InputDecoration(
                  labelText: 'Ciudades (separadas por coma)',
                  helperText: 'Ej: Bogotá, Medellín. Una entrega aquí es local.',
                ),
              ),
              TextField(
                controller: whatsapp,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'WhatsApp para pedidos',
                  helperText: 'Con indicativo. Ej: 573001234567',
                ),
              ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (guardar != true) return;

    try {
      await _repo.actualizarParametros(
        empresa,
        p.copyWith(
          margenDetal: double.tryParse(detal.text.trim()) ?? p.margenDetal,
          margenMayor: double.tryParse(mayor.text.trim()) ?? p.margenMayor,
          margenDistribuidor:
              double.tryParse(distribuidor.text.trim()) ?? p.margenDistribuidor,
          costoEnvio: double.tryParse(envio.text.trim()) ?? p.costoEnvio,
          iva: double.tryParse(iva.text.trim()) ?? p.iva,
          reteFuente: double.tryParse(reteFuente.text.trim()) ?? p.reteFuente,
          reteIva: double.tryParse(reteIva.text.trim()) ?? p.reteIva,
          reteIca: double.tryParse(reteIca.text.trim()) ?? p.reteIca,
          ciudades: ciudades.text
              .split(',')
              .map((String e) => e.trim())
              .where((String e) => e.isNotEmpty)
              .toList(growable: false),
          whatsappPedidos: whatsapp.text.trim(),
        ),
      );
      await _cargar();
      if (mounted) _avisar('Parámetros actualizados.');
    } catch (e) {
      if (mounted) _avisar('No se pudieron guardar: $e', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final empresa = _empresa;

    return Scaffold(
      appBar: AppBar(title: Text(empresa?.nombre ?? 'Mi empresa')),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(_error!, textAlign: TextAlign.center),
                  ),
                )
              : _cuerpo(empresa!),
    );
  }

  Widget _cuerpo(Empresa empresa) {
    final ahora = DateTime.now();
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Row(
          children: <Widget>[
            LogoEmpresa(empresa: empresa, radio: 34),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(empresa.nombre, style: theme.textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text('NIT ${empresa.nit.isEmpty ? "—" : empresa.nit}'),
                  const SizedBox(height: 8),
                  EstadoLicenciaChip(estado: empresa.estadoLicencia(ahora)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _cambiarLogo,
            icon: const Icon(Icons.image_outlined, size: 18),
            label: Text(empresa.tieneLogo ? 'Cambiar logo' : 'Subir logo'),
          ),
        ),
        const SizedBox(height: 8),
        TarjetaDatos(
          titulo: 'Licencia',
          icono: Icons.verified_outlined,
          filas: <FilaDato>[
            FilaDato('Tipo', empresa.licencia.tipo.nombre),
            FilaDato('Vencimiento', formatearFecha(empresa.licencia.fechaFin)),
            FilaDato(
              'Días restantes',
              describirDiasRestantes(empresa.licencia.diasRestantes(ahora)),
            ),
            FilaDato('Estado', empresa.estadoLicencia(ahora).nombre),
          ],
        ),
        const SizedBox(height: 12),
        TarjetaDatos(
          titulo: 'Parámetros',
          icono: Icons.tune_outlined,
          filas: <FilaDato>[
            FilaDato('Margen detal', '${empresa.parametros.margenDetal.round()}%'),
            FilaDato('Margen mayor', '${empresa.parametros.margenMayor.round()}%'),
            FilaDato('Margen distribuidores',
                '${empresa.parametros.margenDistribuidor.round()}%'),
            FilaDato('Costo de envío',
                formatearValor(empresa.parametros.costoEnvio)),
            FilaDato('IVA', '${empresa.parametros.iva.round()}%'),
          ],
          acciones: <Widget>[
            TextButton.icon(
              onPressed: _editarParametros,
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('Editar parámetros'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TarjetaDatos(
          titulo: 'Caja',
          icono: Icons.account_balance_wallet_outlined,
          filas: <FilaDato>[
            FilaDato('Saldo inicial', formatearValor(_saldoInicial)),
            FilaDato(
              'Edición',
              _tieneVentas
                  ? 'Bloqueada (ya hay ventas)'
                  : 'Permitida hasta la primera venta',
            ),
          ],
          acciones: <Widget>[
            TextButton.icon(
              onPressed: _tieneVentas ? null : _editarSaldoInicial,
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('Editar saldo inicial'),
            ),
          ],
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

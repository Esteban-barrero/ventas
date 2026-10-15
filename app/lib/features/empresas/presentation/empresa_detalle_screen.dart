import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/formato/fechas.dart';
import '../../../core/imagen/medir_imagen.dart';
import '../../auth/data/usuarios_repository.dart';
import '../../licencia/domain/licencia.dart' show EstadoEmpresa;
import '../data/almacenamiento_repository.dart';
import '../data/empresas_repository.dart';
import '../domain/empresa.dart';
import '../domain/licencia.dart';
import 'widgets/estado_licencia_chip.dart';
import 'widgets/logo_empresa.dart';
import 'widgets/tarjeta_datos.dart';

/// Detalle y edición de una empresa (spec 002, T022).
///
/// Devuelve `true` al salir si algo cambió, para que el listado se recargue.
class EmpresaDetalleScreen extends StatefulWidget {
  const EmpresaDetalleScreen({
    super.key,
    required this.empresaId,
    this.repository,
    this.usuariosRepository,
    this.selectorImagen,
  });

  final String empresaId;
  final EmpresasRepository? repository;
  final UsuariosRepository? usuariosRepository;
  final Future<XFile?> Function()? selectorImagen;

  @override
  State<EmpresaDetalleScreen> createState() => _EmpresaDetalleScreenState();
}

class _EmpresaDetalleScreenState extends State<EmpresaDetalleScreen> {
  late final EmpresasRepository _repo =
      widget.repository ?? EmpresasRepository();
  late final UsuariosRepository _usuarios =
      widget.usuariosRepository ?? UsuariosRepository();

  Empresa? _empresa;
  bool _cargando = true;
  bool _cambio = false;
  String? _error;

  /// Texto a mostrar como Administrador de la empresa (nombre y correo).
  String _admin = 'Sin asignar';

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
      var admin = 'Sin asignar';
      if (empresa != null && empresa.adminId.isNotEmpty) {
        admin = await _describirAdmin(empresa.adminId);
      }
      if (!mounted) return;
      setState(() {
        _empresa = empresa;
        _admin = admin;
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

  /// Nombre y correo del Administrador a partir de su UID (spec 002).
  ///
  /// Si no se puede leer el perfil, se muestra el UID como respaldo.
  Future<String> _describirAdmin(String uid) async {
    try {
      final usuario = await _usuarios.obtener(uid);
      if (usuario == null) return uid;
      final nombre = usuario.nombre.trim();
      if (nombre.isEmpty) return usuario.email;
      return '$nombre · ${usuario.email}';
    } catch (_) {
      return uid;
    }
  }

  Future<void> _ejecutar(
    Future<void> Function() accion, {
    String exito = 'Cambios guardados.',
  }) async {
    try {
      await accion();
      _cambio = true;
      await _cargar();
      if (!mounted) return;
      _avisar(exito);
    } catch (e) {
      if (!mounted) return;
      _avisar('No se pudo completar: $e', error: true);
    }
  }

  void _avisar(String mensaje, {bool error = false}) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor:
            error ? Theme.of(context).colorScheme.error : null,
      ),
    );
  }

  // ───────────────────────────── Acciones ─────────────────────────────

  Future<void> _editarDatos() async {
    final empresa = _empresa;
    if (empresa == null) return;

    final nombre = TextEditingController(text: empresa.nombre);
    final nit = TextEditingController(text: empresa.nit);
    final correo = TextEditingController(text: empresa.correoNotificacion);
    final telefono = TextEditingController(text: empresa.telefono);
    final contacto = TextEditingController(text: empresa.contactoProveedor);

    final guardar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar datos'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: nombre,
                decoration: const InputDecoration(labelText: 'Nombre'),
              ),
              TextField(
                controller: nit,
                decoration: const InputDecoration(labelText: 'NIT / RIF'),
              ),
              TextField(
                controller: correo,
                decoration:
                    const InputDecoration(labelText: 'Correo de notificación'),
              ),
              TextField(
                controller: telefono,
                decoration: const InputDecoration(labelText: 'Teléfono'),
              ),
              TextField(
                controller: contacto,
                decoration:
                    const InputDecoration(labelText: 'Contacto proveedor'),
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

    if (guardar != true || nombre.text.trim().isEmpty) return;

    await _ejecutar(
      () => _repo.editarDatos(
        empresa,
        nombre: nombre.text.trim(),
        nit: nit.text.trim(),
        correoNotificacion: correo.text.trim(),
        telefono: telefono.text.trim(),
        contactoProveedor: contacto.text.trim(),
      ),
      exito: 'Datos actualizados.',
    );
  }

  Future<void> _renovar() async {
    final empresa = _empresa;
    if (empresa == null) return;

    final base = empresa.licencia.fechaFin ?? DateTime.now();
    var tipo = empresa.licencia.tipo;
    var inicio = DateUtils.dateOnly(base);
    var fin = DateUtils.dateOnly(base.add(const Duration(days: 30)));
    final valor = TextEditingController(
      text: empresa.licencia.valorPagado.toStringAsFixed(0),
    );
    final nota = TextEditingController(text: 'Renovación');

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Renovar licencia'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                DropdownButtonFormField<TipoLicencia>(
                  initialValue: tipo,
                  decoration: const InputDecoration(labelText: 'Tipo'),
                  items: <DropdownMenuItem<TipoLicencia>>[
                    for (final t in TipoLicencia.values)
                      DropdownMenuItem<TipoLicencia>(
                        value: t,
                        child: Text(t.nombre),
                      ),
                  ],
                  onChanged: (TipoLicencia? v) {
                    if (v == null) return;
                    setDialogState(() {
                      tipo = v;
                      if (v == TipoLicencia.mensual) {
                        fin = inicio.add(const Duration(days: 30));
                      } else if (v == TipoLicencia.anual ||
                          v == TipoLicencia.gratis) {
                        fin = inicio.add(const Duration(days: 365));
                      }
                    });
                  },
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Inicio'),
                  subtitle: Text(formatearFecha(inicio)),
                  trailing: const Icon(Icons.calendar_today_outlined),
                  onTap: () async {
                    final e = await showDatePicker(
                      context: context,
                      initialDate: inicio,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (e != null) setDialogState(() => inicio = e);
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Fin'),
                  subtitle: Text(formatearFecha(fin)),
                  trailing: const Icon(Icons.calendar_today_outlined),
                  onTap: () async {
                    final e = await showDatePicker(
                      context: context,
                      initialDate: fin,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (e != null) setDialogState(() => fin = e);
                  },
                ),
                TextField(
                  controller: valor,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Valor pagado'),
                ),
                TextField(
                  controller: nota,
                  decoration: const InputDecoration(labelText: 'Nota'),
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
              child: const Text('Renovar'),
            ),
          ],
        ),
      ),
    );

    if (confirmado != true) return;
    if (fin.isBefore(inicio)) {
      _avisar('La fecha de fin no puede ser anterior al inicio.', error: true);
      return;
    }

    await _ejecutar(
      () => _repo.renovar(
        empresa.id,
        licencia: empresa.licencia.copyWith(
          tipo: tipo,
          fechaInicio: inicio,
          fechaFin: fin,
          valorPagado: double.tryParse(valor.text.trim()) ?? 0,
        ),
        nota: nota.text.trim(),
      ),
      exito: 'Licencia renovada hasta ${formatearFecha(fin)}.',
    );
  }

  Future<void> _cambiarEstado(EstadoEmpresa nuevo) async {
    final empresa = _empresa;
    if (empresa == null) return;

    if (nuevo == EstadoEmpresa.eliminada) {
      final ok = await _confirmar(
        'Eliminar empresa',
        'La empresa "${empresa.nombre}" dejará de estar disponible. La '
            'eliminación es lógica: los datos y la auditoría se conservan '
            '(RN-08). ¿Continuar?',
      );
      if (ok != true) return;
    }

    await _ejecutar(
      () => _repo.cambiarEstado(empresa.id, nuevo),
      exito: 'Estado actualizado a "${nuevo.nombre}".',
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

      await _ejecutar(
        () => _repo.subirLogo(
          empresa.id,
          bytes,
          extension: extension,
          ancho: dims?.ancho ?? 0,
          alto: dims?.alto ?? 0,
        ),
        exito: 'Logo actualizado.',
      );
    } catch (e) {
      if (mounted) _avisar('No se pudo subir el logo: $e', error: true);
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

    await _ejecutar(
      () => _repo.actualizarParametros(
        empresa,
        p.copyWith(
          margenDetal: double.tryParse(detal.text.trim()) ?? p.margenDetal,
          margenMayor: double.tryParse(mayor.text.trim()) ?? p.margenMayor,
          margenDistribuidor:
              double.tryParse(distribuidor.text.trim()) ?? p.margenDistribuidor,
          costoEnvio: double.tryParse(envio.text.trim()) ?? p.costoEnvio,
          iva: double.tryParse(iva.text.trim()) ?? p.iva,
        ),
      ),
      exito: 'Parámetros actualizados.',
    );
  }

  Future<bool?> _confirmar(String titulo, String mensaje) => showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(titulo),
          content: Text(mensaje),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Confirmar'),
            ),
          ],
        ),
      );

  // ───────────────────────────── Vista ─────────────────────────────

  @override
  Widget build(BuildContext context) {
    final empresa = _empresa;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) return;
        Navigator.of(context).pop(_cambio);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(empresa?.nombre ?? 'Empresa'),
          actions: <Widget>[
            if (empresa != null)
              IconButton(
                tooltip: 'Editar datos',
                icon: const Icon(Icons.edit_outlined),
                onPressed: _editarDatos,
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
                : _cuerpo(empresa!),
      ),
    );
  }

  Widget _cuerpo(Empresa empresa) {
    final ahora = DateTime.now();
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            LogoEmpresa(empresa: empresa, radio: 34),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    empresa.nombre,
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text('NIT ${empresa.nit.isEmpty ? "—" : empresa.nit}'),
                  const SizedBox(height: 8),
                  EstadoLicenciaChip(estado: empresa.estadoLicencia(ahora)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TarjetaDatos(
          titulo: 'Licencia',
          icono: Icons.verified_outlined,
          filas: <FilaDato>[
            FilaDato('Tipo', empresa.licencia.tipo.nombre),
            FilaDato('Inicio', formatearFecha(empresa.licencia.fechaInicio)),
            FilaDato('Vencimiento', formatearFecha(empresa.licencia.fechaFin)),
            FilaDato('Días restantes',
                describirDiasRestantes(empresa.licencia.diasRestantes(ahora))),
            FilaDato('Días de aviso', '${empresa.licencia.diasAvisoVencimiento}'),
            FilaDato('Estado empresa', empresa.estado.nombre),
            FilaDato('Plan', empresa.planId),
          ],
        ),
        const SizedBox(height: 12),
        TarjetaDatos(
          titulo: 'Contacto',
          icono: Icons.contact_mail_outlined,
          filas: <FilaDato>[
            FilaDato('Correo', empresa.correoNotificacion.isEmpty
                ? '—'
                : empresa.correoNotificacion),
            FilaDato('Teléfono', empresa.telefono.isEmpty ? '—' : empresa.telefono),
            FilaDato('Proveedor', empresa.contactoProveedor.isEmpty
                ? '—'
                : empresa.contactoProveedor),
            FilaDato('Administrador', _admin),
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
            FilaDato('Límites',
                'Usuarios: ${empresa.limites.maxUsuarios} · Productos: ${empresa.limites.maxProductos}'),
          ],
          acciones: <Widget>[
            TextButton.icon(
              onPressed: _editarParametros,
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('Editar parámetros'),
            ),
          ],
        ),
        if (empresa.licencia.historialPagos.isNotEmpty) ...<Widget>[
          const SizedBox(height: 12),
          TarjetaDatos(
            titulo: 'Historial de pagos',
            icono: Icons.receipt_long_outlined,
            filas: <FilaDato>[
              for (final pago in empresa.licencia.historialPagos.reversed)
                FilaDato(
                  formatearFecha(pago.fecha),
                  '${formatearValor(pago.valor)} · ${pago.nota.isEmpty ? "—" : pago.nota}',
                ),
            ],
          ),
        ],
        const SizedBox(height: 24),
        Text('Acciones', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: <Widget>[
            FilledButton.icon(
              onPressed: _renovar,
              icon: const Icon(Icons.autorenew),
              label: const Text('Renovar'),
            ),
            OutlinedButton.icon(
              onPressed: _cambiarLogo,
              icon: const Icon(Icons.image_outlined),
              label: const Text('Logo'),
            ),
            if (empresa.estado == EstadoEmpresa.suspendida)
              OutlinedButton.icon(
                onPressed: () => _cambiarEstado(EstadoEmpresa.activa),
                icon: const Icon(Icons.play_arrow_outlined),
                label: const Text('Reactivar'),
              )
            else
              OutlinedButton.icon(
                onPressed: () => _cambiarEstado(EstadoEmpresa.suspendida),
                icon: const Icon(Icons.pause_outlined),
                label: const Text('Suspender'),
              ),
            OutlinedButton.icon(
              onPressed: () => _cambiarEstado(EstadoEmpresa.eliminada),
              icon: const Icon(Icons.delete_outline),
              label: const Text('Eliminar'),
            ),
          ],
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

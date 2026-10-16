import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/formato/fechas.dart';
import '../../../core/imagen/medir_imagen.dart';
import '../../../core/validacion/correo.dart';
import '../data/almacenamiento_repository.dart';
import '../data/empresas_repository.dart';
import '../data/planes_repository.dart';
import '../domain/empresa.dart';
import '../domain/licencia.dart';
import '../domain/plan.dart';

/// Formulario de creación de empresa (spec 002, T021 / RF-01..RF-06).
class EmpresaFormScreen extends StatefulWidget {
  const EmpresaFormScreen({
    super.key,
    this.repository,
    this.planesRepository,
    this.selectorImagen,
  });

  final EmpresasRepository? repository;
  final PlanesRepository? planesRepository;

  /// Permite inyectar un selector de imagen distinto en las pruebas.
  final Future<XFile?> Function()? selectorImagen;

  @override
  State<EmpresaFormScreen> createState() => _EmpresaFormScreenState();
}

class _EmpresaFormScreenState extends State<EmpresaFormScreen> {
  late final EmpresasRepository _repo =
      widget.repository ?? EmpresasRepository();
  late final PlanesRepository _planesRepo =
      widget.planesRepository ?? PlanesRepository();

  final _formKey = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _nit = TextEditingController();
  final _correoNotificacion = TextEditingController();
  final _telefono = TextEditingController();
  final _contactoProveedor = TextEditingController();
  final _valorPagado = TextEditingController(text: '0');
  final _diasAviso = TextEditingController(text: '5');
  final _adminNombre = TextEditingController();
  final _adminEmail = TextEditingController();

  TipoLicencia _tipo = TipoLicencia.mensual;
  DateTime _fechaInicio = DateUtils.dateOnly(DateTime.now());
  late DateTime _fechaFin = DateUtils.dateOnly(DateTime.now().add(const Duration(days: 30)));
  String _planId = 'basico';

  List<Plan> _planes = Plan.porDefecto;

  Uint8List? _logoBytes;
  String _logoExtension = 'png';
  DimensionesImagen? _logoDims;
  String? _logoAviso;

  bool _guardando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarPlanes();
  }

  @override
  void dispose() {
    _nombre.dispose();
    _nit.dispose();
    _correoNotificacion.dispose();
    _telefono.dispose();
    _contactoProveedor.dispose();
    _valorPagado.dispose();
    _diasAviso.dispose();
    _adminNombre.dispose();
    _adminEmail.dispose();
    super.dispose();
  }

  Future<void> _cargarPlanes() async {
    final planes = await _planesRepo.listar();
    if (!mounted || planes.isEmpty) return;
    setState(() {
      _planes = planes;
      if (!planes.any((Plan p) => p.id == _planId)) {
        _planId = planes.first.id;
      }
    });
  }

  /// Al cambiar el tipo de licencia se sugiere una nueva fecha de fin.
  void _aplicarTipo(TipoLicencia tipo) {
    setState(() {
      _tipo = tipo;
      switch (tipo) {
        case TipoLicencia.gratis:
          _fechaFin = _fechaInicio.add(const Duration(days: 365));
        case TipoLicencia.mensual:
          _fechaFin = _fechaInicio.add(const Duration(days: 30));
        case TipoLicencia.anual:
          _fechaFin = _fechaInicio.add(const Duration(days: 365));
        case TipoLicencia.personalizado:
          break;
      }
    });
  }

  Future<void> _elegirFecha({required bool esInicio}) async {
    final inicial = esInicio ? _fechaInicio : _fechaFin;
    final elegida = await showDatePicker(
      context: context,
      initialDate: inicial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (elegida == null) return;
    setState(() {
      if (esInicio) {
        _fechaInicio = elegida;
        if (_fechaFin.isBefore(_fechaInicio)) _fechaFin = _fechaInicio;
      } else {
        _fechaFin = elegida;
      }
    });
  }

  Future<void> _elegirLogo() async {
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

      String? aviso;
      try {
        AlmacenamientoRepository.validarLogo(bytes, extension: extension);
      } on ArchivoInvalidoException catch (e) {
        aviso = e.mensaje;
      }

      final dims = await medirImagen(bytes);
      if (dims != null && !dims.esCuadrada) {
        aviso = aviso ??
            'Se recomienda un logo cuadrado de 512×512 px (el elegido es '
                '${dims.ancho}×${dims.alto}).';
      }

      if (!mounted) return;
      setState(() {
        _logoBytes = bytes;
        _logoExtension = extension;
        _logoDims = dims;
        _logoAviso = aviso;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'No se pudo leer la imagen: $e');
    }
  }

  void _quitarLogo() {
    setState(() {
      _logoBytes = null;
      _logoDims = null;
      _logoAviso = null;
    });
  }

  Future<void> _guardar() async {
    setState(() => _error = null);

    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_fechaFin.isBefore(_fechaInicio)) {
      setState(() => _error =
          'La fecha de fin no puede ser anterior a la fecha de inicio.');
      return;
    }

    if (_logoAviso != null && _logoBytes != null) {
      final dims = _logoDims;
      final esTamanoInvalido = _logoBytes!.lengthInBytes >
          AlmacenamientoRepository.maxLogoBytes;
      if (esTamanoInvalido) {
        setState(() => _error = 'El logo supera los 500 KB permitidos.');
        return;
      }
      if (dims != null && !dims.esCuadrada) {
        final continuar = await _confirmar(
          'Logo no cuadrado',
          'El logo elegido es ${dims.ancho}×${dims.alto}. Se recomienda '
              '512×512 px. ¿Deseas continuar?',
        );
        if (continuar != true) return;
      }
    }

    setState(() => _guardando = true);

    try {
      final empresa = DatosEmpresa(
        nombre: _nombre.text.trim(),
        nit: _nit.text.trim(),
        correoNotificacion: _correoNotificacion.text.trim(),
        telefono: _telefono.text.trim(),
        contactoProveedor: _contactoProveedor.text.trim(),
        adminNombre: _adminNombre.text.trim(),
        adminEmail: _adminEmail.text.trim(),
      );

      final licencia = Licencia(
        tipo: _tipo,
        fechaInicio: _fechaInicio,
        fechaFin: _fechaFin,
        diasAvisoVencimiento: int.tryParse(_diasAviso.text.trim()) ?? 5,
        valorPagado: double.tryParse(_valorPagado.text.trim()) ?? 0,
      );

      final resultado = await _repo.crear(
        empresa,
        licencia: licencia,
        planId: _planId,
        logo: _logoBytes,
        logoExtension: _logoExtension,
        logoAncho: _logoDims?.ancho ?? 0,
        logoAlto: _logoDims?.alto ?? 0,
      );

      if (!mounted) return;
      await _mostrarResultado(resultado);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _mensajeDeError(e);
        _guardando = false;
      });
    }
  }

  String _mensajeDeError(Object e) {
    final texto = e.toString();
    if (texto.contains('already-exists') || texto.contains('duplicate')) {
      return 'Ya existe una empresa con ese NIT.';
    }
    if (texto.contains('permission-denied')) {
      return 'No tienes permisos para crear empresas.';
    }
    if (texto.contains('network') || texto.contains('unavailable')) {
      return 'No hay conexión. Revisa tu red e inténtalo de nuevo.';
    }
    return 'No se pudo crear la empresa: $e';
  }

  Future<void> _mostrarResultado(ResultadoCrearEmpresa resultado) async {
    final empresa = resultado.empresa;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Empresa creada'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Se creó "${empresa?.nombre ?? _nombre.text}".'),
            const SizedBox(height: 8),
            Text(
              resultado.aviso ??
                  'Empresa y administrador creados correctamente.',
            ),
            if (resultado.desdeRespaldo) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                'Nota: se usó el respaldo local porque la Cloud Function '
                'todavía no está desplegada.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
        actions: <Widget>[
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  Future<bool?> _confirmar(String titulo, String mensaje) {
    return showDialog<bool>(
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
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Nueva empresa')),
      body: AbsorbPointer(
        absorbing: _guardando,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              _Seccion(titulo: 'Datos de la empresa', icono: Icons.business_outlined),
              _campo(_nombre, 'Nombre / razón social', obligatorio: true),
              _campo(_nit, 'NIT / RIF', obligatorio: true),
              _campo(
                _correoNotificacion,
                'Correo de notificación',
                tipo: TextInputType.emailAddress,
              ),
              _campo(_telefono, 'Teléfono', tipo: TextInputType.phone),
              _campo(_contactoProveedor, 'Contacto del proveedor'),
              const SizedBox(height: 8),
              _Seccion(titulo: 'Licencia', icono: Icons.verified_outlined),
              DropdownButtonFormField<TipoLicencia>(
                initialValue: _tipo,
                decoration: const InputDecoration(
                  labelText: 'Tipo de licencia',
                  border: OutlineInputBorder(),
                ),
                items: <DropdownMenuItem<TipoLicencia>>[
                  for (final tipo in TipoLicencia.values)
                    DropdownMenuItem<TipoLicencia>(
                      value: tipo,
                      child: Text(tipo.nombre),
                    ),
                ],
                onChanged: (TipoLicencia? valor) {
                  if (valor != null) _aplicarTipo(valor);
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Expanded(
                    child: _campoFecha(
                      'Fecha de inicio',
                      _fechaInicio,
                      () => _elegirFecha(esInicio: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _campoFecha(
                      'Fecha de fin',
                      _fechaFin,
                      () => _elegirFecha(esInicio: false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _planId,
                      decoration: const InputDecoration(
                        labelText: 'Plan',
                        border: OutlineInputBorder(),
                      ),
                      items: <DropdownMenuItem<String>>[
                        for (final plan in _planes)
                          DropdownMenuItem<String>(
                            value: plan.id,
                            child: Text(plan.nombre),
                          ),
                      ],
                      onChanged: (String? valor) {
                        if (valor != null) setState(() => _planId = valor);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _diasAviso,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Días de aviso',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _valorPagado,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Valor pagado',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              _Seccion(
                titulo: 'Administrador de la empresa',
                icono: Icons.admin_panel_settings_outlined,
              ),
              Text(
                'Se creará su cuenta y recibirá un correo para definir su '
                'contraseña (RF-03).',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              _campo(_adminNombre, 'Nombre del administrador'),
              _campo(
                _adminEmail,
                'Correo del administrador',
                obligatorio: true,
                tipo: TextInputType.emailAddress,
                validadorEmail: true,
              ),
              const SizedBox(height: 8),
              _Seccion(titulo: 'Logo', icono: Icons.image_outlined),
              _SelectorLogo(
                bytes: _logoBytes,
                dims: _logoDims,
                aviso: _logoAviso,
                onElegir: _elegirLogo,
                onQuitar: _quitarLogo,
              ),
              if (_error != null) ...<Widget>[
                const SizedBox(height: 16),
                _MensajeError(mensaje: _error!),
              ],
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _guardando ? null : _guardar,
                icon: _guardando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(_guardando ? 'Creando…' : 'Crear empresa'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _campo(
    TextEditingController controller,
    String etiqueta, {
    bool obligatorio = false,
    bool validadorEmail = false,
    TextInputType? tipo,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: tipo,
        decoration: InputDecoration(
          labelText: obligatorio ? '$etiqueta *' : etiqueta,
          border: const OutlineInputBorder(),
        ),
        validator: (String? valor) {
          final texto = (valor ?? '').trim();
          if (obligatorio && texto.isEmpty) return 'Campo obligatorio.';
          if (validadorEmail && texto.isNotEmpty && !esCorreoValido(texto)) {
            return 'Correo no válido.';
          }
          return null;
        },
      ),
    );
  }

  Widget _campoFecha(String etiqueta, DateTime fecha, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: etiqueta,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
        ),
        child: Text(formatearFecha(fecha)),
      ),
    );
  }
}

class _Seccion extends StatelessWidget {
  const _Seccion({required this.titulo, required this.icono});

  final String titulo;
  final IconData icono;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      child: Row(
        children: <Widget>[
          Icon(icono, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            titulo,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _SelectorLogo extends StatelessWidget {
  const _SelectorLogo({
    required this.bytes,
    required this.dims,
    required this.aviso,
    required this.onElegir,
    required this.onQuitar,
  });

  final Uint8List? bytes;
  final DimensionesImagen? dims;
  final String? aviso;
  final VoidCallback onElegir;
  final VoidCallback onQuitar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                border: Border.all(color: theme.dividerColor),
                borderRadius: BorderRadius.circular(12),
                image: bytes == null
                    ? null
                    : DecorationImage(
                        image: MemoryImage(bytes!),
                        fit: BoxFit.contain,
                      ),
              ),
              child: bytes == null
                  ? Icon(
                      Icons.add_photo_alternate_outlined,
                      size: 32,
                      color: theme.colorScheme.primary,
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Recomendado: PNG 512×512 px, máximo 500 KB.',
                    style: theme.textTheme.bodySmall,
                  ),
                  if (dims != null) ...<Widget>[
                    const SizedBox(height: 4),
                    Text(
                      'Seleccionado: ${dims!} · '
                      '${((bytes?.lengthInBytes ?? 0) / 1024).round()} KB',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: <Widget>[
                      OutlinedButton.icon(
                        onPressed: onElegir,
                        icon: const Icon(Icons.upload_file_outlined, size: 18),
                        label: Text(bytes == null ? 'Elegir logo' : 'Cambiar'),
                      ),
                      if (bytes != null)
                        TextButton.icon(
                          onPressed: onQuitar,
                          icon: const Icon(Icons.close, size: 18),
                          label: const Text('Quitar'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        if (aviso != null) ...<Widget>[
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Icon(Icons.info_outline, size: 18, color: Color(0xFFE65100)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  aviso!,
                  style: const TextStyle(color: Color(0xFFE65100)),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _MensajeError extends StatelessWidget {
  const _MensajeError({required this.mensaje});

  final String mensaje;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.error_outline, color: scheme.onErrorContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              mensaje,
              style: TextStyle(color: scheme.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}

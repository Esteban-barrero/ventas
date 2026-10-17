import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/avisos/whatsapp.dart';
import '../../../core/formato/fechas.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/data/usuarios_repository.dart';
import '../../auth/domain/usuario.dart';
import '../../catalogo/domain/precio.dart';
import '../../clientes/data/clientes_repository.dart';
import '../../clientes/data/ubicaciones/departamentos_ciudades.dart';
import '../../clientes/domain/cliente.dart';
import '../../empresas/domain/empresa.dart';
import '../../ventas/domain/venta.dart' show MedioPago, TipoEntrega;
import '../data/pedidos_repository.dart';
import '../domain/pedido.dart';
import 'catalogo_tienda_screen.dart' show LineaTienda;

/// Checkout **público** (spec 010). Al confirmar, si el usuario es invitado
/// (anónimo) se crea su cuenta de cliente, se le envía el enlace para definir
/// la contraseña y se registra el pedido.
class CheckoutTiendaScreen extends StatefulWidget {
  const CheckoutTiendaScreen({
    super.key,
    required this.empresa,
    required this.lineas,
    this.onIngresar,
    this.pedidosRepository,
    this.authRepository,
    this.usuariosRepository,
    this.clientesRepository,
  });

  final Empresa empresa;
  final List<LineaTienda> lineas;
  final VoidCallback? onIngresar;
  final PedidosRepository? pedidosRepository;
  final AuthRepository? authRepository;
  final UsuariosRepository? usuariosRepository;
  final ClientesRepository? clientesRepository;

  @override
  State<CheckoutTiendaScreen> createState() => _CheckoutTiendaScreenState();
}

class _CheckoutTiendaScreenState extends State<CheckoutTiendaScreen> {
  late final PedidosRepository _pedidos =
      widget.pedidosRepository ?? PedidosRepository();
  late final AuthRepository _auth = widget.authRepository ?? AuthRepository();
  late final UsuariosRepository _usuarios =
      widget.usuariosRepository ?? UsuariosRepository();
  late final ClientesRepository _clientes =
      widget.clientesRepository ?? ClientesRepository();

  final _nombre = TextEditingController();
  final _cedula = TextEditingController();
  final _telefono = TextEditingController();
  final _email = TextEditingController();
  final _direccion = TextEditingController();
  final _barrio = TextEditingController();
  final _observaciones = TextEditingController();

  String? _departamento;
  String? _ciudad;
  Cliente? _cliente;
  bool _aDomicilio = true;
  MedioPago _medio = MedioPago.efectivo;
  bool _enviando = false;

  String get _empresaId => widget.empresa.id;
  bool get _esInvitado =>
      FirebaseAuth.instance.currentUser?.isAnonymous ?? true;

  @override
  void initState() {
    super.initState();
    if (!_esInvitado) _cargarPerfil();
  }

  /// Precarga los datos del cliente logueado (para no pedirlos de nuevo).
  Future<void> _cargarPerfil() async {
    try {
      final c = await _clientes.porUid(FirebaseAuth.instance.currentUser!.uid);
      if (c == null || !mounted) return;
      setState(() {
        _cliente = c;
        _nombre.text = c.nombreCompleto;
        _cedula.text = c.cedula;
        _telefono.text = c.telefono;
        _direccion.text = c.direccion.direccion;
        _barrio.text = c.direccion.barrio;
        final dep = c.direccion.departamento.trim();
        _departamento = departamentos.contains(dep) ? dep : null;
        final ciu = c.direccion.ciudad.trim();
        _ciudad = (_departamento != null &&
                ciudadesDe(_departamento!).contains(ciu))
            ? ciu
            : null;
      });
    } catch (_) {
      // Si no se puede leer, se llena a mano.
    }
  }

  /// Crea o actualiza la ficha del cliente para recordar sus datos. Devuelve el
  /// id de la ficha (vacío si no se pudo guardar).
  Future<String> _guardarCliente(String uid) async {
    final cliente = Cliente(
      id: _cliente?.id ?? '',
      empresaId: _empresaId,
      uid: uid,
      nombreCompleto: _nombre.text.trim(),
      cedula: _cedula.text.trim(),
      telefono: _telefono.text.trim(),
      correo: FirebaseAuth.instance.currentUser?.email ?? '',
      direccion: Direccion(
        departamento: _departamento ?? '',
        ciudad: _ciudad ?? '',
        direccion: _direccion.text.trim(),
        barrio: _barrio.text.trim(),
      ),
    );
    try {
      return await _clientes.guardarPropio(cliente);
    } catch (_) {
      // Si falla, el pedido sigue; solo no se recuerdan los datos.
      return '';
    }
  }

  @override
  void dispose() {
    _nombre.dispose();
    _cedula.dispose();
    _telefono.dispose();
    _email.dispose();
    _direccion.dispose();
    _barrio.dispose();
    _observaciones.dispose();
    super.dispose();
  }

  double get _subtotal => widget.lineas.fold(
      0.0,
      (double a, LineaTienda l) =>
          a + l.producto.precio(TipoPrecio.contado, widget.empresa.parametros) * l.cantidad);

  double get _impuestos => widget.lineas.fold(
      0.0,
      (double a, LineaTienda l) =>
          a +
          l.producto.precio(TipoPrecio.contado, widget.empresa.parametros) *
              l.cantidad *
              l.producto.ivaEfectivo(widget.empresa.parametros) /
              100);

  TipoEntrega get _tipoEntrega {
    if (!_aDomicilio) return TipoEntrega.recogerLocal;
    return widget.empresa.parametros.esCiudadLocal(_ciudad)
        ? TipoEntrega.entregaLocal
        : TipoEntrega.envio;
  }

  double get _envio =>
      _tipoEntrega.cobraEnvio ? widget.empresa.parametros.costoEnvio : 0;

  double get _total => _subtotal + _envio + _impuestos;

  void _avisar(String m, {bool error = false}) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(m),
        backgroundColor: error ? Theme.of(context).colorScheme.error : null,
      ),
    );
  }

  Future<void> _enviar() async {
    if (_nombre.text.trim().isEmpty ||
        _cedula.text.trim().isEmpty ||
        _telefono.text.trim().isEmpty ||
        _direccion.text.trim().isEmpty ||
        (_aDomicilio && (_departamento == null || _ciudad == null))) {
      return _avisar('Completa nombre, cédula, teléfono y dirección.',
          error: true);
    }
    final email = _email.text.trim();
    if (_esInvitado && !email.contains('@')) {
      return _avisar('Escribe un correo válido para crear tu cuenta.',
          error: true);
    }

    final items = widget.lineas
        .map((LineaTienda l) => ItemPedido(
              productoId: l.producto.id,
              codigo: l.producto.codigo,
              nombre: l.producto.nombre,
              cantidad: l.cantidad,
              precioUnitario:
                  l.producto.precio(TipoPrecio.contado, widget.empresa.parametros),
              iva: l.producto.ivaEfectivo(widget.empresa.parametros),
              costoUnitario: l.producto.costo,
            ))
        .toList(growable: false);

    setState(() => _enviando = true);
    try {
      String clienteUid = FirebaseAuth.instance.currentUser?.uid ?? '';

      // Invitado: se crea su cuenta de cliente (spec 010).
      if (_esInvitado) {
        final cred = await _auth.registrar(email, _claveTemporal());
        clienteUid = cred.user!.uid;
        await _usuarios.guardar(Usuario(
          uid: clienteUid,
          nombre: _nombre.text.trim(),
          email: email,
          telefono: _telefono.text.trim(),
          empresaId: _empresaId,
          roles: const <String>['cliente'],
          activo: true,
          fechaCreacion: DateTime.now(),
        ));
        try {
          await _auth.enviarCorreoRecuperacion(email);
        } catch (_) {
          // Si no se puede enviar el correo, la cuenta ya quedó creada.
        }
      }

      // Guarda/actualiza la ficha del cliente para recordar sus datos.
      final clienteId = await _guardarCliente(clienteUid);

      final pedido = Pedido(
        id: '',
        empresaId: _empresaId,
        origen: OrigenPedido.cliente,
        clienteUid: clienteUid,
        clienteId: clienteId.isEmpty ? null : clienteId,
        clienteNombre: _nombre.text.trim(),
        cedula: _cedula.text.trim(),
        telefono: _telefono.text.trim(),
        direccion: Direccion(
          departamento: _departamento ?? '',
          ciudad: _ciudad ?? '',
          direccion: _direccion.text.trim(),
          barrio: _barrio.text.trim(),
        ),
        items: items,
        subtotal: _subtotal,
        costoEnvio: _envio,
        impuestos: _impuestos,
        total: _total,
        tipoEntrega: _tipoEntrega,
        medioPago: _medio,
        observaciones: _observaciones.text.trim(),
      );
      await _pedidos.crear(pedido);

      if (!mounted) return;
      final whatsapp = widget.empresa.parametros.whatsappPedidos.trim();
      final resumen =
          'Nuevo pedido de ${_nombre.text.trim()} por ${formatearValor(_total)}.';
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('¡Pedido enviado!'),
          content: Text(
            _esInvitado
                ? 'Registramos tu pedido y creamos tu cuenta. Revisa tu correo '
                    '($email) para definir tu contraseña.'
                : 'La empresa revisará tu pedido y te contactará.',
          ),
          actions: <Widget>[
            if (whatsapp.isNotEmpty)
              TextButton.icon(
                onPressed: () => abrirWhatsApp(whatsapp, resumen),
                icon: const Icon(Icons.chat_bubble_outline),
                label: const Text('Avisar por WhatsApp'),
              ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Entendido'),
            ),
          ],
        ),
      );
      if (mounted) Navigator.of(context).pop(true);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        _avisar('Ese correo ya tiene cuenta. Inicia sesión para pedir.', error: true);
      } else {
        _avisar(AuthRepository.mensajeDeError(e), error: true);
      }
    } catch (e) {
      if (mounted) _avisar('No se pudo enviar el pedido: $e', error: true);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  /// Clave temporal (se cambia con el enlace que se envía por correo).
  String _claveTemporal() =>
      'Pv${DateTime.now().microsecondsSinceEpoch}Aa1!';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Confirmar pedido')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Text(widget.empresa.nombre, style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Text('Tus datos', style: theme.textTheme.titleMedium),
          _campo(_nombre, 'Nombre *'),
          _campo(_cedula, 'Cédula *', tipo: TextInputType.number),
          _campo(_telefono, 'Teléfono *', tipo: TextInputType.phone),
          if (_esInvitado)
            _campo(_email, 'Correo (para tu cuenta) *',
                tipo: TextInputType.emailAddress),
          const SizedBox(height: 8),
          Text('Entrega', style: theme.textTheme.titleMedium),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Entrega a domicilio'),
            subtitle: const Text('Si no, recoges en el local.'),
            value: _aDomicilio,
            onChanged: (bool v) => setState(() => _aDomicilio = v),
          ),
          if (_aDomicilio) ...<Widget>[
            _dropdownDepartamento(),
            _dropdownCiudad(),
            _campo(_direccion, 'Dirección *'),
            _campo(_barrio, 'Barrio'),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                widget.empresa.parametros.esCiudadLocal(_ciudad)
                    ? 'Entrega local'
                    : 'Envío (otra ciudad)',
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],
          const SizedBox(height: 8),
          DropdownButtonFormField<MedioPago>(
            initialValue: _medio,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Medio de pago',
              border: OutlineInputBorder(),
            ),
            items: <DropdownMenuItem<MedioPago>>[
              for (final m in MedioPago.values)
                DropdownMenuItem<MedioPago>(value: m, child: Text(m.nombre)),
            ],
            onChanged: (MedioPago? v) =>
                setState(() => _medio = v ?? MedioPago.efectivo),
          ),
          const SizedBox(height: 12),
          _campo(_observaciones, 'Observaciones'),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: <Widget>[
                  _fila('Subtotal', formatearValor(_subtotal)),
                  if (_envio > 0) _fila('Envío', formatearValor(_envio)),
                  if (_impuestos > 0)
                    _fila('Impuestos', formatearValor(_impuestos)),
                  const Divider(),
                  _fila('Total', formatearValor(_total), negrita: true),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _enviando ? null : _enviar,
            icon: _enviando
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send_outlined),
            label: Text(_enviando ? 'Enviando…' : 'Enviar pedido'),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _dropdownDepartamento() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        initialValue: _departamento,
        isExpanded: true,
        decoration: const InputDecoration(
          labelText: 'Departamento *',
          border: OutlineInputBorder(),
        ),
        items: <DropdownMenuItem<String>>[
          for (final d in departamentos)
            DropdownMenuItem<String>(value: d, child: Text(d)),
        ],
        onChanged: (String? v) => setState(() {
          _departamento = v;
          _ciudad = null;
        }),
      ),
    );
  }

  Widget _dropdownCiudad() {
    final ciudades =
        _departamento == null ? const <String>[] : ciudadesDe(_departamento!);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        initialValue: _ciudad,
        isExpanded: true,
        decoration: const InputDecoration(
          labelText: 'Ciudad *',
          border: OutlineInputBorder(),
        ),
        items: <DropdownMenuItem<String>>[
          for (final c in ciudades)
            DropdownMenuItem<String>(value: c, child: Text(c)),
        ],
        onChanged: _departamento == null
            ? null
            : (String? v) => setState(() => _ciudad = v),
      ),
    );
  }

  Widget _campo(
    TextEditingController controller,
    String label, {
    TextInputType? tipo,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: tipo,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _fila(String etiqueta, String valor, {bool negrita = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: <Widget>[
          Expanded(child: Text(etiqueta)),
          Text(
            valor,
            style: TextStyle(
              fontWeight: negrita ? FontWeight.bold : FontWeight.normal,
              fontSize: negrita ? 16 : null,
            ),
          ),
        ],
      ),
    );
  }
}

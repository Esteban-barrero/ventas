import 'package:flutter/material.dart';

import '../../../core/formato/fechas.dart';
import '../../auth/domain/usuario.dart';
import '../../clientes/domain/cliente.dart';
import '../../empresas/domain/parametros_empresa.dart';
import '../../ventas/domain/venta.dart' show MedioPago, TipoEntrega;
import '../data/pedidos_repository.dart';
import '../domain/pedido.dart';
import 'tienda_screen.dart' show LineaCarrito;

/// Checkout del pedido (spec 010): datos del cliente, entrega y confirmación.
class CheckoutPedidoScreen extends StatefulWidget {
  const CheckoutPedidoScreen({
    super.key,
    required this.usuario,
    required this.lineas,
    required this.parametros,
    this.cliente,
    this.pedidosRepository,
  });

  final Usuario usuario;
  final List<LineaCarrito> lineas;
  final ParametrosEmpresa parametros;
  final Cliente? cliente;
  final PedidosRepository? pedidosRepository;

  @override
  State<CheckoutPedidoScreen> createState() => _CheckoutPedidoScreenState();
}

class _CheckoutPedidoScreenState extends State<CheckoutPedidoScreen> {
  late final PedidosRepository _repo =
      widget.pedidosRepository ?? PedidosRepository();

  late final TextEditingController _nombre;
  late final TextEditingController _cedula;
  late final TextEditingController _telefono;
  late final TextEditingController _departamento;
  late final TextEditingController _ciudad;
  late final TextEditingController _direccion;
  late final TextEditingController _barrio;
  late final TextEditingController _observaciones;

  bool _aDomicilio = true;
  MedioPago _medio = MedioPago.efectivo;
  bool _enviando = false;

  String get _empresaId => widget.usuario.empresaId ?? '';

  @override
  void initState() {
    super.initState();
    final c = widget.cliente;
    _nombre = TextEditingController(
        text: c?.nombreCompleto ?? widget.usuario.nombre);
    _cedula = TextEditingController(text: c?.cedula ?? '');
    _telefono = TextEditingController(text: c?.telefono ?? '');
    _departamento = TextEditingController(text: c?.direccion.departamento ?? '');
    _ciudad = TextEditingController(text: c?.direccion.ciudad ?? '');
    _direccion = TextEditingController(text: c?.direccion.direccion ?? '');
    _barrio = TextEditingController(text: c?.direccion.barrio ?? '');
    _observaciones = TextEditingController();
  }

  @override
  void dispose() {
    _nombre.dispose();
    _cedula.dispose();
    _telefono.dispose();
    _departamento.dispose();
    _ciudad.dispose();
    _direccion.dispose();
    _barrio.dispose();
    _observaciones.dispose();
    super.dispose();
  }

  double get _subtotal => widget.lineas.fold(
      0.0, (double a, LineaCarrito l) => a + l.precioUnitario * l.cantidad);

  double get _impuestos => widget.lineas.fold(
      0.0,
      (double a, LineaCarrito l) =>
          a + l.precioUnitario * l.cantidad * l.producto.ivaEfectivo(widget.parametros) / 100);

  /// Local si la ciudad está entre las de la empresa; si no, envío.
  TipoEntrega get _tipoEntrega {
    if (!_aDomicilio) return TipoEntrega.recogerLocal;
    return widget.parametros.esCiudadLocal(_ciudad.text)
        ? TipoEntrega.entregaLocal
        : TipoEntrega.envio;
  }

  double get _envio =>
      _tipoEntrega.cobraEnvio ? widget.parametros.costoEnvio : 0;

  double get _total => _subtotal + _envio + _impuestos;

  Future<void> _enviar() async {
    if (_nombre.text.trim().isEmpty ||
        _cedula.text.trim().isEmpty ||
        _telefono.text.trim().isEmpty ||
        _direccion.text.trim().isEmpty ||
        (_aDomicilio && _ciudad.text.trim().isEmpty)) {
      return _avisar('Completa nombre, cédula, teléfono, dirección y ciudad.',
          error: true);
    }

    final items = widget.lineas
        .map((LineaCarrito l) => ItemPedido(
              productoId: l.producto.id,
              codigo: l.producto.codigo,
              nombre: l.producto.nombre,
              cantidad: l.cantidad,
              precioUnitario: l.precioUnitario,
              iva: l.producto.ivaEfectivo(widget.parametros),
              costoUnitario: l.producto.costo,
            ))
        .toList(growable: false);

    final pedido = Pedido(
      id: '',
      empresaId: _empresaId,
      origen: OrigenPedido.cliente,
      clienteUid: widget.usuario.uid,
      clienteId: widget.cliente?.id,
      clienteNombre: _nombre.text.trim(),
      cedula: _cedula.text.trim(),
      telefono: _telefono.text.trim(),
      direccion: Direccion(
        departamento: _departamento.text.trim(),
        ciudad: _ciudad.text.trim(),
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

    setState(() => _enviando = true);
    try {
      await _repo.crear(pedido);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) _avisar('No se pudo enviar el pedido: $e', error: true);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Confirmar pedido')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Text('Datos del cliente', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          _campo(_nombre, 'Nombre *'),
          _campo(_cedula, 'Cédula *', tipo: TextInputType.number),
          _campo(_telefono, 'Teléfono *', tipo: TextInputType.phone),
          const SizedBox(height: 8),
          Text('Entrega', style: theme.textTheme.titleMedium),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Entrega a domicilio'),
            subtitle: const Text('Si no, recoge en el local.'),
            value: _aDomicilio,
            onChanged: (bool v) => setState(() => _aDomicilio = v),
          ),
          if (_aDomicilio) ...<Widget>[
            _campo(_departamento, 'Departamento'),
            _campo(_ciudad, 'Ciudad *'),
            _campo(_direccion, 'Dirección *'),
            _campo(_barrio, 'Barrio'),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                widget.parametros.esCiudadLocal(_ciudad.text)
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
                  if (_impuestos > 0) _fila('Impuestos', formatearValor(_impuestos)),
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

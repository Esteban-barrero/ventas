import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Pantalla para **escanear** un código de barras o QR (spec 003).
///
/// Devuelve el texto leído (`String`) al detectar un código, o `null` si el
/// usuario cancela. En Web usa la cámara del navegador (requiere permiso).
class EscanearCodigoScreen extends StatefulWidget {
  const EscanearCodigoScreen({super.key});

  @override
  State<EscanearCodigoScreen> createState() => _EscanearCodigoScreenState();
}

class _EscanearCodigoScreenState extends State<EscanearCodigoScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool _yaDetectado = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _detectado(BarcodeCapture captura) {
    if (_yaDetectado) return;
    for (final barcode in captura.barcodes) {
      final valor = barcode.rawValue;
      if (valor != null && valor.trim().isNotEmpty) {
        _yaDetectado = true;
        Navigator.of(context).pop(valor.trim());
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Escanear código')),
      body: MobileScanner(
        controller: _controller,
        onDetect: _detectado,
        errorBuilder: (context, error) => const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'No se pudo acceder a la cámara.\nRevisa los permisos o usa '
              '"Agregar producto".',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

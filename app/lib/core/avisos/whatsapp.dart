import 'package:url_launcher/url_launcher.dart';

/// Abre **WhatsApp** con un mensaje prellenado hacia un número (spec 010).
///
/// Es la vía práctica para avisar al negocio de un pedido sin servidor. Un
/// envío automático requeriría una Cloud Function con la API de WhatsApp.
Future<bool> abrirWhatsApp(String numero, String mensaje) async {
  final limpio = numero.replaceAll(RegExp(r'[^0-9]'), '');
  if (limpio.isEmpty) return false;
  final url = Uri.parse(
    'https://wa.me/$limpio?text=${Uri.encodeComponent(mensaje)}',
  );
  try {
    return await launchUrl(url, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}

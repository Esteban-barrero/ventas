import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import 'core/theme.dart';
import 'features/auth/presentation/auth_gate.dart';
import 'firebase_options.dart';

Future<void> main() async {
  // Necesario antes de usar plugins (Firebase) en el arranque.
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa Firebase con la configuracion del proyecto
  // (generada por `flutterfire configure` en lib/firebase_options.dart).
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Persistencia local de Firestore para poder operar sin conexion
  // (spec 001, T014). En movil ya viene activada por defecto; en Web hay que
  // pedirla explicitamente. `cacheSizeBytes` no aplica en Web.
  final firestore = FirebaseFirestore.instance;
  firestore.settings = kIsWeb
      ? const Settings(persistenceEnabled: true)
      : const Settings(
          persistenceEnabled: true,
          cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
        );

  runApp(const VentasApp());
}

class VentasApp extends StatelessWidget {
  const VentasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aplicativo de Ventas',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      home: const AuthGate(),
    );
  }
}

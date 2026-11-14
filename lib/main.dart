import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'services/cat_backend_service.dart';
import 'theme/cat_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  bool firebaseInitialized = false;
  if (DefaultFirebaseOptions.isFirebaseConfigured) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      firebaseInitialized = true;
    } catch (e) {
      debugPrint('Firebase initialization fallback to Demo Mode: $e');
    }
  }

  final backend = CatBackendService(firebaseReady: firebaseInitialized);
  runApp(CatMsgApp(backend: backend));
}

class CatMsgApp extends StatelessWidget {
  final CatBackendService backend;

  const CatMsgApp({
    super.key,
    required this.backend,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CatMsg — PurrCord',
      debugShowCheckedModeBanner: false,
      theme: CatTheme.darkTheme,
      home: HomeScreen(backend: backend),
    );
  }
}

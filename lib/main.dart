import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'theme/cyber_theme.dart';
import 'services/payment_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  PaymentService().initialize();
  runApp(const GhostNotesApp());
}

class GhostNotesApp extends StatelessWidget {
  const GhostNotesApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ghost Notes Realist',
      debugShowCheckedModeBanner: false,
      theme: CyberTheme.theme,
      home: const SplashScreen(),
    );
  }
}

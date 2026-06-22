import 'package:flutter/material.dart';
import 'screens/settings_screen.dart';

void main() {
  runApp(const MagicShowApp());
}

class MagicShowApp extends StatelessWidget {
  const MagicShowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Magic Show Presenter',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFF0031EA),   // Codemagic No-bug-blue
          secondary: const Color(0xFF00CEFF), // Codemagic Dash Aqua
          surface: const Color(0xFF0F0F1A),
        ),
        scaffoldBackgroundColor: const Color(0xFF0A0A14),
        useMaterial3: true,
      ),
      home: const SettingsScreen(),
    );
  }
}

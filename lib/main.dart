import 'package:flutter/material.dart';
import 'login_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EpicurIA',
      debugShowCheckedModeBanner: false, // Oculta la etiqueta de "DEBUG"
      theme: ThemeData(
        // Usamos tu color principal para generar la paleta
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF016782)),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF7F9FB), // Color 'surface' de tu HTML
      ),
      home: const LoginPage(), // Arranca directamente en el Login
    );
  }
}
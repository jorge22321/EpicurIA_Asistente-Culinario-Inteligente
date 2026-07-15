import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:epicur_ia_asistente_culinario_inteligente/login_page.dart';
import 'test_ai_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EpicurIA',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF016782)),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF7F9FB),
      ),
      // En lugar de usar 'home', declaramos la ruta inicial:
      initialRoute: '/login',
      // Aquí definimos el mapa de rutas de toda tu app:
      routes: {
        '/login': (context) => const LoginPage(),
        // Más adelante puedes agregar las demás aquí, por ejemplo:
        // '/profile': (context) => const ProfilePage(),
      },
    );
  }
}
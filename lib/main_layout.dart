import 'dart:ui';
import 'package:flutter/material.dart';
import 'home_page.dart';
import 'history_page.dart';
import 'services/voice_service.dart'; // Manteniendo tu servicio de voz
import 'profile_page.dart';           // Tu pantalla de perfil vinculada

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _indiceActual = 0;
  final VoiceService _voiceService = VoiceService(); // Instancia del servicio de voz

  @override
  void initState() {
    super.initState();
    // SOLUCIÓN: Le pasamos una función vacía () {} para cumplir con el nuevo parámetro esperado
    _voiceService.initTts(() {});
  }

  // Getters con las pantallas del ecosistema EpicurIA
  List<Widget> get _pantallas => [
    HomePage(
      onNavigateToHistory: () {
        setState(() {
          _indiceActual = 3; // Salta al historial
        });
      },
    ),
    const Center(child: Text("Pantalla 2: Escanear")),
    const ProfilePage(), // <- Reemplaza el marcador del Chef por tu vista de Perfil real
    const HistoryPage(),
  ];

  // --- PALETA DE COLORES CORPORATIVA ---
  final Color primaryColor = const Color(0xFF016782);
  final Color primaryContainer = const Color(0xFFCFE6F1);
  final Color iconInactiveColor = const Color(0xFF94A3B8);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Permite que el contenido se deslice con elegancia detrás de la barra translúcida
      body: IndexedStack(
        index: _indiceActual,
        children: _pantallas,
      ),
      bottomNavigationBar: _construirBarraNavegacion(),
    );
  }

  // --- INTERFAZ BARRA DE NAVEGACIÓN ESTILO GLASSMORPHISM ---
  Widget _construirBarraNavegacion() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 32,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            color: Colors.white.withOpacity(0.85),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SafeArea(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _construirBoton(0, Icons.home_rounded, "Home"),
                  _construirBoton(2, Icons.person_rounded, "Perfil"), // <- Actualizado de Chef a Perfil
                  _construirBoton(3, Icons.history_rounded, "History"),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- COMPONENTE BÓTON INTERACTIVO ANIMADO ---
  Widget _construirBoton(int indice, IconData icono, String texto) {
    final bool estaActivo = _indiceActual == indice;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        setState(() {
          _indiceActual = indice;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: estaActivo ? primaryContainer.withOpacity(0.5) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icono,
              color: estaActivo ? primaryColor : iconInactiveColor,
              size: 26,
            ),
            const SizedBox(height: 4),
            Text(
              texto,
              style: TextStyle(
                fontSize: 11,
                fontWeight: estaActivo ? FontWeight.w700 : FontWeight.w600,
                color: estaActivo ? primaryColor : iconInactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
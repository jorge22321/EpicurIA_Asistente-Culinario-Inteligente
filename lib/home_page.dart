import 'package:flutter/material.dart';
import 'recipe_analysis_page.dart';
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  // --- PALETA DE COLORES ---
  final Color primaryColor = const Color(0xFF016782);
  final Color primaryDim = const Color(0xFF005B73);
  final Color backgroundColor = const Color(0xFFF7F9FB);
  final Color onBackground = const Color(0xFF2C3437);
  final Color surfaceContainerLow = const Color(0xFFF0F4F7);
  final Color surfaceContainerLowest = const Color(0xFFFFFFFF);
  final Color onSurfaceVariant = const Color(0xFF596064);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      // --- APP BAR (Cabecera modificada) ---
      appBar: AppBar(
        backgroundColor: backgroundColor.withOpacity(0.9),
        elevation: 0,
        automaticallyImplyLeading: false, // Oculta la flecha de atrás por defecto
        actions: [
          // Foto de perfil a la derecha
          Padding(
            padding: const EdgeInsets.only(right: 24.0),
            child: InkWell(
              onTap: () {
                print("Ir al perfil");
              },
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF94DFFE), width: 2),
                ),
                child: const CircleAvatar(
                  radius: 20,
                  backgroundImage: NetworkImage(
                    "https://images.unsplash.com/photo-1577219491135-ce391730fb2c?ixlib=rb-4.0.3&auto=format&fit=crop&w=100&q=80", // Imagen de prueba
                  ),
                ),
              ),
            ),
          ),
        ],
      ),

      // --- CUERPO PRINCIPAL ---
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. SALUDO
              Text(
                "¿Qué se te antoja\npreparar hoy?",
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: onBackground,
                  height: 1.1,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 16),
              // Línea decorativa
              Container(
                height: 6,
                width: 48,
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 48),

              // 2. BOTÓN CENTRAL GIGANTE (Escanear)
              Center(
                child: Column(
                  children: [
                    _buildMainScanButton(context),
                    const SizedBox(height: 24),
                    // Botón secundario de galería
                    _buildGalleryButton(),
                  ],
                ),
              ),
              const SizedBox(height: 48),

              // 3. SECCIÓN: ÚLTIMOS ANÁLISIS
              _buildLatestAnalysisSection(),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGETS DE CONSTRUCCIÓN ---

  Widget _buildMainScanButton(BuildContext context) {
    return SizedBox(
      width: 320,
      height: 320,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF94DFFE).withOpacity(0.4),
                  blurRadius: 60,
                  spreadRadius: 20,
                ),
              ],
            ),
          ),
          Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(40),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [primaryColor, primaryDim],
              ),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.3),
                  blurRadius: 32,
                  offset: const Offset(0, 16),
                )
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(40),
                onTap: () {
                  // --- AQUÍ ESTÁ LA NAVEGACIÓN A LA NUEVA PANTALLA ---
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const RecipeAnalysisPage()),
                  );
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.filter_center_focus, size: 64, color: Colors.white),
                    ),
                    const SizedBox(height: 24),
                    const Text("Escanear Plato", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text("IA Vision Engine Activo", style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGalleryButton() {
    return ElevatedButton.icon(
      onPressed: () {
        print("Abrir galería");
      },
      icon: const Icon(Icons.add_photo_alternate_outlined),
      label: const Text("Subir desde la galería"),
      style: ElevatedButton.styleFrom(
        backgroundColor: surfaceContainerLow,
        foregroundColor: primaryColor,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildLatestAnalysisSection() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              "Últimos Análisis",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: onBackground,
              ),
            ),
            InkWell(
              onTap: () {},
              child: Row(
                children: [
                  Text(
                    "Ver todos",
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Icon(Icons.arrow_forward, color: primaryColor, size: 16),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Lista horizontal de tarjetas
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none, // Para que las sombras no se corten
          child: Row(
            children: [
              _buildDishCard(
                category: "ENSALADA",
                title: "Bowl de Salmón",
                imageUrl: "https://images.unsplash.com/photo-1546069901-ba9599a7e63c?ixlib=rb-4.0.3&auto=format&fit=crop&w=300&q=80",
              ),
              const SizedBox(width: 16),
              _buildDishCard(
                category: "ITALIANA",
                title: "Penne Pomodoro",
                imageUrl: "https://images.unsplash.com/photo-1621996346565-e3dbc646d9a9?ixlib=rb-4.0.3&auto=format&fit=crop&w=300&q=80",
              ),
              const SizedBox(width: 16),
              _buildDishCard(
                category: "PIZZA",
                title: "Margherita Especial",
                imageUrl: "https://images.unsplash.com/photo-1574071318508-1cdbab80d002?ixlib=rb-4.0.3&auto=format&fit=crop&w=300&q=80",
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDishCard({required String category, required String title, required String imageUrl}) {
    return Container(
      width: 160,
      decoration: BoxDecoration(
        color: surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              imageUrl,
              height: 140,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Text(
              category,
              style: TextStyle(
                color: primaryColor,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 4.0, bottom: 8.0, right: 4.0),
            child: Text(
              title,
              style: TextStyle(
                color: onBackground,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
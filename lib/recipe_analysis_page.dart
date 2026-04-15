import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart'; // <-- Importación de FontAwesome

class RecipeAnalysisPage extends StatelessWidget {
  const RecipeAnalysisPage({super.key});

  // --- PALETA DE COLORES ---
  final Color primaryColor = const Color(0xFF016782);
  final Color primaryDim = const Color(0xFF005B73);
  final Color backgroundColor = const Color(0xFFF7F9FB);
  final Color onSurface = const Color(0xFF2C3437);
  final Color onSurfaceVariant = const Color(0xFF596064);
  final Color surfaceContainerLowest = const Color(0xFFFFFFFF);
  final Color surfaceContainerLow = const Color(0xFFF0F4F7);
  final Color surfaceContainerHighest = const Color(0xFFDCE4E8);
  final Color secondaryContainer = const Color(0xFFCFE6F1);
  final Color onSecondaryContainer = const Color(0xFF3F555E);
  final Color primaryContainer = const Color(0xFF94DFFE);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      // --- APP BAR (Sin título) ---
      appBar: AppBar(
        backgroundColor: backgroundColor.withOpacity(0.9),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF016782)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 24.0),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person, color: Color(0xFF747C80)),
            ),
          ),
        ],
      ),

      // --- CUERPO PRINCIPAL ---
      // Reduje el padding inferior de 120 a 100 porque ya no hay barra inferior
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 16.0, bottom: 100.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // BADGE "Analysis Complete"
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: secondaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                "ANALYSIS COMPLETE",
                style: TextStyle(
                  color: onSecondaryContainer,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // TÍTULO Y FOTO DE LA COMIDA
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    "Salmón con\nEspárragos",
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: onSurface,
                      height: 1.1,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    "https://images.unsplash.com/photo-1546069901-ba9599a7e63c?ixlib=rb-4.0.3&auto=format&fit=crop&w=150&q=80",
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // NUTRITION BENTO
            Row(
              children: [
                _buildNutritionBox("CALORIES", "420", "kcal"),
                const SizedBox(width: 12),
                _buildNutritionBox("PROTEIN", "34", "g"),
                const SizedBox(width: 12),
                _buildNutritionBox("TIME", "25", "min"),
              ],
            ),
            const SizedBox(height: 32),

            // TABS
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildTab("Ingredientes", isActive: true),
                  const SizedBox(width: 24),
                  _buildTab("Preparación", isActive: false),
                  const SizedBox(width: 24),
                  _buildTab("Información Nutricional", isActive: false),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // CHECKLIST DE INGREDIENTES
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: surfaceContainerLowest,
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.shopping_basket, color: primaryColor),
                      const SizedBox(width: 8),
                      const Text(
                        "Checklist de Ingredientes",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildChecklistItem("2 Filetes de Salmón Fresco", "200g cada uno, con piel", false),
                  _buildChecklistItem("1 Manojo de Espárragos", "Retirar la parte leñosa del tallo", false),
                  _buildChecklistItem("Aceite de Oliva Virgen Extra", "2 cucharadas soperas", true),
                  _buildChecklistItem("Limón y Eneldo", "Para aromatizar y decorar", false),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // AI INTELLIGENCE PULSE
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: primaryContainer.withOpacity(0.4),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white.withOpacity(0.5)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(color: primaryColor, shape: BoxShape.circle),
                    child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      '"He ajustado las cantidades basándome en tu perfil de entrenamiento de hoy."',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF005065)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),

            // PREPARATION SNEAK PEEK
            Opacity(
              opacity: 0.8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Próximos Pasos", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("01", style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: surfaceContainerHighest)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Precalentar y Sazonar", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: onSurface)),
                            const SizedBox(height: 4),
                            Text(
                              "Lleva el horno a 200°C. Sazona el salmón con sal, pimienta y eneldo fresco sobre papel para hornear.",
                              style: TextStyle(color: onSurfaceVariant, fontSize: 14, height: 1.5),
                            ),
                          ],
                        ),
                      )
                    ],
                  )
                ],
              ),
            )
          ],
        ),
      ),

      // --- BOTÓN FLOTANTE (Ahora más abajo y con FontAwesome) ---
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 24), // <--- Reducido de 80 a 24 para que baje
        child: ElevatedButton.icon(
          onPressed: () {
            print("Iniciando modo voz...");
          },
          // Uso de FontAwesome aquí 👇
          icon: const FaIcon(FontAwesomeIcons.microphone, size: 20),
          label: const Text(
            "Empezar a Cocinar (Modo Voz)",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            elevation: 8,
            shadowColor: primaryColor.withOpacity(0.5),
          ),
        ),
      ),
      // --- SE ELIMINÓ EL BOTTOM NAVIGATION BAR ---
    );
  }

  // --- WIDGETS DE APOYO ---

  Widget _buildNutritionBox(String label, String value, String unit) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: surfaceContainerLow, borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: onSurfaceVariant, letterSpacing: 1.2)),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: primaryColor)),
                const SizedBox(width: 2),
                Text(unit, style: TextStyle(fontSize: 12, color: onSurfaceVariant)),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String text, {required bool isActive}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          text,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
            color: isActive ? primaryColor : onSurfaceVariant.withOpacity(0.6),
          ),
        ),
        if (isActive) ...[
          const SizedBox(height: 4),
          Container(height: 4, width: 30, decoration: BoxDecoration(color: primaryColor, borderRadius: BorderRadius.circular(2))),
        ]
      ],
    );
  }

  Widget _buildChecklistItem(String title, String subtitle, bool isCrossedOut) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(  
            width: 24,
            height: 24,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: isCrossedOut ? primaryColor : surfaceContainerHighest,
              borderRadius: BorderRadius.circular(6),
            ),
            child: isCrossedOut ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Opacity(
              opacity: isCrossedOut ? 0.4 : 1.0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      decoration: isCrossedOut ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: onSurfaceVariant,
                      decoration: isCrossedOut ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'register_page.dart';
import 'home_page.dart';
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  // Colores de tu diseño EpicurIA
  final Color primaryColor = const Color(0xFF016782);
  final Color surfaceContainerHighest = const Color(0xFFDCE4E8);
  final Color onSurfaceVariant = const Color(0xFF596064);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Fondo decorativo
          Positioned(
            top: -50,
            left: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF94DFFE).withOpacity(0.2),
                boxShadow: const [BoxShadow(blurRadius: 100, color: Color(0xFF94DFFE))],
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // --- HEADER ---
                    _buildLogoHeader(),
                    const SizedBox(height: 48),

                    // --- FORMULARIO ---
                    _buildTextField(
                      label: "Email",
                      hintText: "nombre@ejemplo.com",
                      icon: Icons.mail_outline,
                      isPassword: false,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      label: "Contraseña",
                      hintText: "••••••••",
                      icon: Icons.lock_outline,
                      isPassword: true,
                    ),

                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {},
                        child: Text(
                          "¿Olvidaste tu contraseña?",
                          style: TextStyle(
                            color: primaryColor.withOpacity(0.8),
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Botón Principal

                    _buildMainButton(context),

                    const SizedBox(height: 32),

                    // --- SECCIÓN SOCIAL (Solo Google) ---
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            "O CONTINÚA CON",
                            style: TextStyle(
                                fontSize: 10,
                                letterSpacing: 1.5,
                                color: onSurfaceVariant,
                                fontWeight: FontWeight.bold
                            ),
                          ),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // AQUÍ ESTÁ TU BOTÓN DE GOOGLE ÚNICO
                    _buildGoogleButton(),

                    const SizedBox(height: 32),

                    // --- FOOTER ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("¿Nuevo en EpicurIA?", style: TextStyle(color: onSurfaceVariant, fontSize: 14)),
                        TextButton(
                          onPressed: () {

                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const RegisterPage()),
                            );
                          },
                          child: Text("Regístrate", style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 14)),
                        )
                      ],
                    )
                  ],
                ),
              ),
            ),
          ),

          // Barra decorativa inferior
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 6,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF016782), Color(0xFF94DFFE), Color(0xFF5C5C7F)],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  // --- WIDGETS DE APOYO ---

  Widget _buildLogoHeader() {
    return Column(
      children: [
        SizedBox(
          width: 80, height: 80,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(width: 80, height: 80, decoration: BoxDecoration(color: const Color(0xFF94DFFE).withOpacity(0.4), shape: BoxShape.circle)),
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(color: primaryColor, shape: BoxShape.circle),
                child: const Icon(Icons.restaurant, color: Colors.white, size: 28),
              ),
              Positioned(
                top: 8, right: 8,
                child: Container(
                  width: 24, height: 24,
                  decoration: BoxDecoration(
                    color: const Color(0xFF94DFFE), shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFF7F9FB), width: 2),
                  ),
                  child: const Icon(Icons.auto_awesome, color: Color(0xFF016782), size: 14),
                ),
              )
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text("EpicurIA", style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: primaryColor)),
        Text("Tu Curador Gastronómico Inteligente", style: TextStyle(fontSize: 14, color: onSurfaceVariant, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildTextField({required String label, required String hintText, required IconData icon, required bool isPassword}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: onSurfaceVariant)),
        ),
        TextField(
          obscureText: isPassword,
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: Icon(icon, color: Colors.grey),
            filled: true,
            fillColor: surfaceContainerHighest,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }

  Widget _buildMainButton(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(colors: [Color(0xFF016782), Color(0xFF005B73)]),
        boxShadow: [BoxShadow(color: primaryColor.withOpacity(0.2), blurRadius: 24, offset: const Offset(0, 12))],
      ),
      child: ElevatedButton(
        onPressed: () {
          // Ahora este context sí será reconocido
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        },
        style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent
        ),
        child: const Text(
            "Iniciar Sesión",
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)
        ),
      ),
    );
  }

  // BOTÓN DE GOOGLE PERSONALIZADO
  Widget _buildGoogleButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: surfaceContainerHighest),
      ),
      child: InkWell(
        onTap: () {
          print("Iniciando con Google...");
        },
        borderRadius: BorderRadius.circular(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center, // Centra todo horizontalmente
          crossAxisAlignment: CrossAxisAlignment.center, // Centra todo verticalmente
          children: [
            // Icono de Google ajustado a un tamaño armónico
            Image.asset('assets/google_icon.png', height: 40),

            // Espacio de separación entre el logo y el texto
            const SizedBox(width: 10),

            Text(
              "Continuar con Google",
              style: TextStyle(
                color: onSurfaceVariant,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  // --- PALETA DE COLORES DE TU DISEÑO ---
  final Color primaryColor = const Color(0xFF016782);
  final Color surfaceColor = const Color(0xFFF7F9FB);
  final Color surfaceContainerHighest = const Color(0xFFDCE4E8);
  final Color onSurfaceVariant = const Color(0xFF596064);
  final Color outlineColor = const Color(0xFF747C80);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: surfaceColor,
      // --- APP BAR (Cabecera) ---
      appBar: AppBar(
        backgroundColor: surfaceColor.withOpacity(0.9),
        elevation: 0, // Sin sombra para simular el diseño web
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: primaryColor),
          onPressed: () {
            // Acción para volver atrás
            Navigator.pop(context);
          },
        ),
        title: Text(
          "EpicurIA",
          style: TextStyle(
            color: primaryColor,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5, // "tracking-tighter"
          ),
        ),
      ),

      // --- CUERPO PRINCIPAL ---
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. SECCIÓN DE FOTO DE PERFIL
              _buildAvatarSection(),
              const SizedBox(height: 40),

              // 2. FORMULARIO DE REGISTRO
              _buildTextField(
                label: "Nombre de usuario",
                hintText: "Ej: gourmet_hunter",
                icon: Icons.person_outline,
              ),
              _buildTextField(
                label: "Correo electrónico",
                hintText: "usuario@ejemplo.com",
                icon: Icons.mail_outline,
                keyboardType: TextInputType.emailAddress,
              ),
              _buildTextField(
                label: "Teléfono (verificación)",
                hintText: "+34 000 000 000",
                icon: Icons.call_outlined,
                keyboardType: TextInputType.phone,
              ),
              _buildTextField(
                label: "Contraseña",
                hintText: "••••••••",
                icon: Icons.lock_outline,
                isPassword: true,
              ),
              _buildTextField(
                label: "Confirmar contraseña",
                hintText: "••••••••",
                icon: Icons.verified_user_outlined,
                isPassword: true,
              ),

              const SizedBox(height: 16),

              // 3. BOTÓN DE CREAR CUENTA
              _buildSubmitButton(),

              const SizedBox(height: 32),

              // 4. LINK PARA INICIAR SESIÓN (Footer)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "¿Ya tienes cuenta? ",
                    style: TextStyle(
                      color: onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      // Acción para ir al Login
                      Navigator.pop(context);
                    },
                    child: Text(
                      "Iniciar sesión",
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24), // Espaciador final
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGETS DE CONSTRUCCIÓN ---

  Widget _buildAvatarSection() {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            // Círculo del Avatar
            Container(
              width: 128,
              height: 128,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: surfaceContainerHighest,
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 32,
                    offset: Offset(0, -8),
                  )
                ],
              ),
              child: Center(
                child: Icon(
                  Icons.add_a_photo,
                  size: 40,
                  color: primaryColor.withOpacity(0.8),
                ),
              ),
            ),
            // Botón flotante de "Editar"
            Container(
              margin: const EdgeInsets.only(bottom: 4, right: 4),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primaryColor,
                shape: BoxShape.circle,
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  )
                ],
              ),
              child: const Icon(Icons.edit, color: Colors.white, size: 16),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          "FOTO DE PERFIL",
          style: TextStyle(
            color: onSurfaceVariant,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5, // "tracking-widest"
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required String hintText,
    required IconData icon,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0), // space-y-6 equivalente
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 6),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: onSurfaceVariant,
              ),
            ),
          ),
          TextField(
            obscureText: isPassword,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(color: outlineColor.withOpacity(0.6)),
              prefixIcon: Icon(icon, color: outlineColor),
              filled: true,
              fillColor: surfaceContainerHighest,
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: primaryColor.withOpacity(0.5), width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56, // py-4 equivalente
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white, // on-primary
          elevation: 8, // shadow-lg
          shadowColor: primaryColor.withOpacity(0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12), // rounded-xl
          ),
        ),
        onPressed: () {
          print("Botón Crear Cuenta presionado");
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text(
              "Crear Cuenta",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.arrow_forward),
          ],
        ),
      ),
    );
  }
}
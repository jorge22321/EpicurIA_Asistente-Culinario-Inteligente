///lib/login_page.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'register_page.dart';
import 'home_page.dart';
import 'services/auth_service.dart';
import 'main_layout.dart';
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final Color primaryColor = const Color(0xFF016782);
  final Color surfaceContainerHighest = const Color(0xFFDCE4E8);
  final Color onSurfaceVariant = const Color(0xFF596064);

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final AuthService _authService = AuthService();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _authService.signInWithEmailPassword(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (response.user != null && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainLayout()),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Email o contraseña incorrectos.";
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _authService.signInWithGoogle();
      if (response != null && response.user != null && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainLayout()),
        );
      }
    } on Exception catch (e) {
      final msg = e.toString();
      if (!msg.contains('canceled') && !msg.contains('cancelled')) {
        setState(() => _errorMessage =
        "Error al iniciar con Google. Verifica tu conexión o configuración.");
      }
      print("Error Google: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
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
                    _buildLogoHeader(),
                    const SizedBox(height: 48),
                    _buildTextField(
                      label: "Email",
                      hintText: "nombre@ejemplo.com",
                      icon: Icons.mail_outline,
                      isPassword: false,
                      controller: _emailController,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      label: "Contraseña",
                      hintText: "••••••••",
                      icon: Icons.lock_outline,
                      isPassword: true,
                      controller: _passwordController,
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

                    // Mensaje de error
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red, fontSize: 13),
                        ),
                      ),

                    const SizedBox(height: 8),
                    _buildMainButton(),
                    const SizedBox(height: 32),
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
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildGoogleButton(),
                    const SizedBox(height: 32),
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
                          child: Text(
                            "Regístrate",
                            style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
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
          ),
        ],
      ),
    );
  }

  Widget _buildLogoHeader() {
    return Column(
      children: [
        SizedBox(
          width: 80,
          height: 80,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF94DFFE).withOpacity(0.4),
                  shape: BoxShape.circle,
                ),
              ),
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
                    color: const Color(0xFF94DFFE),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFF7F9FB), width: 2),
                  ),
                  child: const Icon(Icons.auto_awesome, color: Color(0xFF016782), size: 14),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text("EpicurIA", style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: primaryColor)),
        Text(
          "Tu Curador Gastronómico Inteligente",
          style: TextStyle(fontSize: 14, color: onSurfaceVariant, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required String hintText,
    required IconData icon,
    required bool isPassword,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: onSurfaceVariant)),
        ),
        TextField(
          controller: controller,
          obscureText: isPassword,
          keyboardType: isPassword ? TextInputType.visiblePassword : TextInputType.emailAddress,
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: Icon(icon, color: Colors.grey),
            filled: true,
            fillColor: surfaceContainerHighest,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMainButton() {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(colors: [Color(0xFF016782), Color(0xFF005B73)]),
        boxShadow: [
          BoxShadow(color: primaryColor.withOpacity(0.2), blurRadius: 24, offset: const Offset(0, 12)),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
            : const Text(
          "Iniciar Sesión",
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

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
        onTap: _isLoading ? null : _handleGoogleSignIn,
        borderRadius: BorderRadius.circular(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (_isLoading)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Image.asset('assets/google_icon.png', height: 40), // Tu icono

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
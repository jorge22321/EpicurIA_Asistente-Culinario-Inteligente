import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'main_layout.dart';
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final Color primaryColor = const Color(0xFF016782);
  final Color surfaceColor = const Color(0xFFF7F9FB);
  final Color surfaceContainerHighest = const Color(0xFFDCE4E8);
  final Color onSurfaceVariant = const Color(0xFF596064);
  final Color outlineColor = const Color(0xFF747C80);

  final AuthService _authService = AuthService();

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  // --- ESTADO ---
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validate() {
    if (_usernameController.text.trim().isEmpty) {
      return 'El nombre de usuario es obligatorio.';
    }
    if (_emailController.text.trim().isEmpty || !_emailController.text.contains('@')) {
      return 'Ingresa un correo válido.';
    }
    if (_passwordController.text.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres.';
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      return 'Las contraseñas no coinciden.';
    }
    return null;
  }

  // --- CREAR CUENTA ---
  Future<void> _handleRegister() async {
    final error = _validate();
    if (error != null) {
      setState(() => _errorMessage = error);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. Guardamos la respuesta de Supabase en una variable
      final response = await _authService.signUpWithEmailPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        username: _usernameController.text.trim(),
      );

      // 2. VERIFICACIÓN DE CORREO DUPLICADO (La magia de Supabase)
      // Si identities está vacío, significa que el usuario ya estaba registrado en la base de datos.
      if (response.user != null && response.user!.identities != null && response.user!.identities!.isEmpty) {
        setState(() {
          _errorMessage = 'Este correo ya está registrado. Por favor, inicia sesión.';
        });
        return; // Detenemos la ejecución aquí, no mostramos el diálogo
      }

      // 3. Si todo está bien y es un usuario nuevo, mostramos el panel del código OTP
      if (mounted) _showVerificationDialog(_emailController.text.trim());

    } catch (e) {
      debugPrint('🚨 ERROR REAL DE SUPABASE: $e');
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: Error al registrar: AuthException(message: ', '').replaceAll(')', '');      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- DIÁLOGO DE VERIFICACIÓN ---
  void _showVerificationDialog(String email) {
    final TextEditingController otpController = TextEditingController();
    bool isVerifying = false;
    String? otpError;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
          builder: (contextDialog, setStateDialog) {
            return AlertDialog(
              backgroundColor: surfaceColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF94DFFE).withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.password_rounded, size: 48, color: primaryColor),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Ingresa tu código',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryColor),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Enviamos un código de 6 dígitos a:\n$email',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: onSurfaceVariant, fontSize: 14),
                  ),
                  const SizedBox(height: 24),

                  // Input para el código
                  TextField(
                    controller: otpController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: primaryColor, letterSpacing: 8),
                    decoration: InputDecoration(
                      counterText: "",
                      hintText: "000000",
                      filled: true,
                      fillColor: surfaceContainerHighest,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  if (otpError != null) ...[
                    const SizedBox(height: 12),
                    Text(otpError!, style: const TextStyle(color: Colors.red, fontSize: 13), textAlign: TextAlign.center),
                  ],

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: isVerifying ? null : () async {
                        if (otpController.text.length < 6) {
                          setStateDialog(() => otpError = "Ingresa los 6 dígitos");
                          return;
                        }

                        setStateDialog(() {
                          isVerifying = true;
                          otpError = null;
                        });

                        try {
                          await _authService.verifyEmailOTP(email, otpController.text.trim());

                          // FIX 2: Validación de contexto montado para async gaps
                          if (!context.mounted) return;

                          // Si es exitoso, cierra el diálogo
                          Navigator.of(ctx).pop();

                          // Navega al HomePage eliminando el historial
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (_) => const MainLayout()),
                                (route) => false,
                          );

                        } catch (e) {
                          setStateDialog(() {
                            otpError = "Código inválido o expirado.";
                            isVerifying = false;
                          });
                        }
                      },
                      child: isVerifying
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Verificar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: isVerifying ? null : () {
                      Navigator.of(ctx).pop(); // Permite cancelar y volver
                    },
                    child: Text('Cancelar', style: TextStyle(color: onSurfaceVariant)),
                  )
                ],
              ),
            );
          }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: surfaceColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                _buildLogoHeader(),
                const SizedBox(height: 40),

                _buildTextField(
                  label: "Nombre de usuario",
                  hintText: "Ej: gourmet_hunter",
                  icon: Icons.person_outline,
                  controller: _usernameController,
                ),
                _buildTextField(
                  label: "Correo electrónico",
                  hintText: "usuario@ejemplo.com",
                  icon: Icons.mail_outline,
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                ),
                _buildTextField(
                  label: "Contraseña",
                  hintText: "••••••••",
                  icon: Icons.lock_outline,
                  controller: _passwordController,
                  isPassword: true,
                ),
                _buildTextField(
                  label: "Confirmar contraseña",
                  hintText: "••••••••",
                  icon: Icons.verified_user_outlined,
                  controller: _confirmPasswordController,
                  isPassword: true,
                ),

                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 13),
                    ),
                  ),

                _buildSubmitButton(),
                const SizedBox(height: 32),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("¿Ya tienes cuenta? ",
                        style: TextStyle(color: onSurfaceVariant)),
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      child: Text(
                        "Inicia sesión",
                        style: TextStyle(
                            color: primaryColor, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- LOGO  ---
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
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF94DFFE).withOpacity(0.4),
                  shape: BoxShape.circle,
                ),
              ),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(color: primaryColor, shape: BoxShape.circle),
                child: const Icon(Icons.restaurant, color: Colors.white, size: 28),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: const Color(0xFF94DFFE),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFF7F9FB), width: 2),
                  ),
                  child: const Icon(Icons.auto_awesome,
                      color: Color(0xFF016782), size: 14),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text("Crea tu cuenta",
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: primaryColor)),
        Text(
          "Únete a la comunidad de EpicurIA",
          style: TextStyle(
              fontSize: 14,
              color: onSurfaceVariant,
              fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  // --- CAMPO DE TEXTO ---
  Widget _buildTextField({
    required String label,
    required String hintText,
    required IconData icon,
    required TextEditingController controller,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 6),
            child: Text(
              label,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: onSurfaceVariant),
            ),
          ),
          TextField(
            controller: controller,
            obscureText: isPassword,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              hintText: hintText,
              prefixIcon: Icon(icon, color: outlineColor, size: 20),
              filled: true,
              fillColor: surfaceContainerHighest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- BOTÓN PRINCIPAL ---
  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        onPressed: _isLoading ? null : _handleRegister,
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
            : const Text("Registrarse",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
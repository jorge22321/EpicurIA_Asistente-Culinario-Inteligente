/// lib/services/auth_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AuthService {
  // Cliente principal de Supabase (ya inicializado en main)
  final SupabaseClient _supabase = Supabase.instance.client;

  // Client ID web (necesario para autenticación con Google)
  // Si no existe en el .env, lanza error inmediatamente
  static String get _webClientId =>
      dotenv.env['GOOGLE_WEB_CLIENT_ID'] ??
          (throw Exception('GOOGLE_WEB_CLIENT_ID no encontrado en .env'));

  // Client ID para iOS (puede estar vacío si no se usa)
  static String get _iosClientId =>
      dotenv.env['GOOGLE_IOS_CLIENT_ID'] ?? '';

  // Inicio de sesión con email y contraseña
  Future<AuthResponse> signInWithEmailPassword(
      String email, String password) async {
    try {
      return await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      // Se captura cualquier error y se lanza uno más entendible
      throw Exception('Error al iniciar sesión: ${e.toString()}');
    }
  }

  // Registro de usuario con email, contraseña y username adicional
  Future<AuthResponse> signUpWithEmailPassword({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      return await _supabase.auth.signUp(
        email: email,
        password: password,
        // data permite guardar información extra en el perfil
        data: {'username': username},
      );
    } catch (e) {
      throw Exception('Error al registrar: ${e.toString()}');
    }
  }

  // Inicio de sesión con Google
  Future<AuthResponse?> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn.instance;

      // Inicializa Google Sign-In con los client ID
      await googleSignIn.initialize(
        clientId: _iosClientId,
        serverClientId: _webClientId,
      );

      // Abre el flujo de autenticación de Google
      final GoogleSignInAccount googleUser =
      await googleSignIn.authenticate();

      // Se obtiene el token de autenticación
      final String? idToken = googleUser.authentication.idToken;

      if (idToken == null) {
        throw Exception('No se pudo obtener el idToken de Google.');
      }

      // Se envía el token a Supabase para validar e iniciar sesión
      return await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
      );
    } catch (e) {
      throw Exception('Error en Google Sign-In: ${e.toString()}');
    }
  }

  // Cerrar sesión (borra la sesión actual en Supabase)
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // Devuelve el usuario actual si existe sesión activa
  User? getCurrentUser() {
    return _supabase.auth.currentUser;
  }
  // Verificar el código (OTP) enviado al correo
  Future<AuthResponse> verifyEmailOTP(String email, String token) async {
    try {
      return await _supabase.auth.verifyOTP(
        type: OtpType.signup,
        token: token,
        email: email,
      );
    } catch (e) {
      throw Exception('Error al verificar el código: ${e.toString()}');
    }
  }
}
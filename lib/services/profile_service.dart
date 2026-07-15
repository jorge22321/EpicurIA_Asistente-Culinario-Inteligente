///lib/services/profile_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';

class ProfileService {
  final _supabase = Supabase.instance.client;

  // Obtener perfil del usuario actual
  Future<UserProfile> getCurrentProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception("Sesión no encontrada");

    final data = await _supabase
        .from('perfiles')
        .select()
        .eq('id', user.id)
        .single();

    return UserProfile.fromMap(data);
  }
}
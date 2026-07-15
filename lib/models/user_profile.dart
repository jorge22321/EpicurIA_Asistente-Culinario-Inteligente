///lib/models/user_profile.dart
class UserProfile {
  final String id;
  final String nombre;
  final String? fotoUrl;

  UserProfile({required this.id, required this.nombre, this.fotoUrl});

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] ?? '',
      nombre: map['nombre'] ?? 'Usuario',
      fotoUrl: map['foto_url'],
    );
  }
}
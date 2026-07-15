/// lib/services/storage_service.dart
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class StorageService {
  final SupabaseClient _supabase = Supabase.instance.client;


  Future<String?> uploadImage({
    required File imageFile,
    required String bucketName,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('Usuario no logueado');

      // 2. Extraemos la extensión del archivo (ej: jpg, png)
      final fileExt = imageFile.path.split('.').last;

      String filePath;

      if (bucketName.toLowerCase() == 'avatares' || bucketName == 'avatars') {

        filePath = '${user.id}/perfil.$fileExt';
      } else {

        final timestamp = DateTime.now().millisecondsSinceEpoch;
        filePath = '${user.id}/$timestamp.$fileExt';
      }

      // 4. Subimos el archivo a Supabase
      await _supabase.storage.from(bucketName).upload(
        filePath,
        imageFile,
        fileOptions: const FileOptions(
          cacheControl: '3600',
          upsert: true,
        ),
      );

      if (bucketName.toLowerCase() == 'avatares' || bucketName == 'avatars') {
        return _supabase.storage.from(bucketName).getPublicUrl(filePath);
      } else {
        // URL Firmada (Privada para el usuario, válida por 10 años)
        return await _supabase.storage.from(bucketName).createSignedUrl(
            filePath,
            60 * 60 * 24 * 365 * 10
        );
      }

    } catch (e) {
      print("Error en StorageService (Bucket: $bucketName): $e");
      return null;
    }
  }
}
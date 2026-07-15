/// lib/services/media_service.dart

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class MediaService {
  // Instancia de ImagePicker que permite acceder a cámara o galería
  final ImagePicker _picker = ImagePicker();

  // Método para seleccionar una imagen desde la fuente indicada (cámara o galería)
  Future<File?> pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,

        // Reduce la calidad de la imagen para que pese menos
        // 70 es un buen balance entre tamaño y calidad (suficiente para IA)
        imageQuality: 70,

        // Limita el ancho máximo de la imagen
        // Evita imágenes enormes que consumen memoria y tardan en subir
        maxWidth: 800,
      );

      // Si el usuario sí seleccionó una imagen
      if (pickedFile != null) {
        // Se convierte de XFile a File para poder trabajar más fácilmente
        return File(pickedFile.path);
      }
    } catch (e) {
      // Error controlado (por ejemplo permisos, cancelación, etc.)
      debugPrint("Error al seleccionar imagen desde MediaService: $e");
    }

    // Si el usuario cancela o ocurre algún problema, se retorna null
    return null;
  }
}
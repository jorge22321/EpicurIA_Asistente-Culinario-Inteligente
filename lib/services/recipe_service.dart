///lib/services/recipe_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class RecipeService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getRecentUniqueRecipes(String userId) async {
    try {
      final response = await _supabase
          .from('recetas')
          .select()
          .eq('id_autor', userId)
          .order('fecha_creacion', ascending: false)
          .limit(3);

      List<Map<String, dynamic>> uniqueRecipes = [];
      Set<String> seenTitles = {};

      for (var recipe in response) {
        final String title = (recipe['titulo_receta'] ?? 'Sin nombre').toString().trim().toLowerCase();

        // 2. Lógica para juntar recetas repetidas
        if (!seenTitles.contains(title)) {
          seenTitles.add(title);
          uniqueRecipes.add(recipe);
        }
      }

      return uniqueRecipes;
    } catch (e) {
      debugPrint(" Error al obtener recetas: $e");
      return [];
    }
  }
  Future<Map<String, dynamic>?> buscarRecetaPorHash(String userId, String imageHash) async {
    try {
      final response = await _supabase
          .from('recetas')
          .select()
          .eq('id_autor', userId)
          .eq('hash_imagen', imageHash)
          .limit(1);

      if (response.isNotEmpty) {
        return response.first;
      }
      return null;
    } catch (e) {
      debugPrint("Error buscando hash de imagen: $e");
      return null;
    }
  }
}
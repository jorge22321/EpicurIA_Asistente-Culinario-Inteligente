import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io';

class ClarifaiService {
  // API KEY cargada de manera segura desde tu archivo .env
  static final String _apiKey = dotenv.env['CLARIFAI_API_KEY'] ?? '';

  // Endpoint oficial de Clarifai con compatibilidad OpenAI ChatCompletions
  static const String _url =
      'https://api.clarifai.com/v2/ext/openai/v1/chat/completions';

  // --- MODELO OPTIMIZADO: o4-mini (Despliegue específico de tu versión) ---
  static const String _model =
      'https://clarifai.com/openai/chat-completion/models/o4-mini/versions/efcf58b9be9243ffb6e4032e97a40040';

  /// 1. Envío de mensaje tipo chat (Solo texto plano)
  static Future<String> enviarMensaje(String mensajeUsuario) async {
    try {
      if (_apiKey.isEmpty) throw Exception('API KEY no encontrada en .env');

      final response = await http.post(
        Uri.parse(_url),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "model": _model,
          "messages": [
            {
              "role": "system",
              "content": "Eres un chef experto. Responde recetas claras, útiles y precisas."
            },
            {
              "role": "user",
              "content": mensajeUsuario
            }
          ]
          // NOTA: Se omiten max_tokens y temperature para evitar fallos internos en modelos de razonamiento de la serie 'o'
        }),
      );

      if (response.statusCode != 200) throw Exception(response.body);

      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'];
    } catch (e) {
      return "Error: $e";
    }
  }

  /// 2. Envío de imagen para análisis general (Respuesta en texto libre)
  static Future<String> enviarImagen(File imagen) async {
    try {
      if (_apiKey.isEmpty) throw Exception('API KEY no encontrada en .env');

      final bytes = await imagen.readAsBytes();
      final base64Image = base64Encode(bytes);

      final response = await http.post(
        Uri.parse(_url),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "model": _model,
          "messages": [
            {
              "role": "user",
              "content": [
                {
                  "type": "text",
                  "text": "Analiza esta imagen de comida y dime detalladamente qué es, sus ingredientes primarios y su receta estándar."
                },
                {
                  "type": "image_url",
                  "image_url": {
                    "url": "data:image/jpeg;base64,$base64Image"
                  }
                }
              ]
            }
          ]
        }),
      );

      if (response.statusCode != 200) throw Exception(response.body);

      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'];
    } catch (e) {
      return "Error: $e";
    }
  }

  /// 3. Análisis de imagen forzando salida estructurada en JSON (Súper Preciso con Pasos)
  static Future<Map<String, dynamic>?> analizarRecetaJson(File imagen) async {
    try {
      if (_apiKey.isEmpty) throw Exception('API KEY no encontrada en .env');

      final bytes = await imagen.readAsBytes();
      final base64Image = base64Encode(bytes);

      final response = await http.post(
        Uri.parse(_url),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "model": _model,
          "messages": [
            {
              "role": "system",
              "content":
              "You are an Executive Chef expert in culinary deconstruction. Apply REVERSE ENGINEERING to the dish in the image. RULES: 1. NAME DEDUCTION: For the 'plato' field, use the shortest, most popular cultural/commercial name of the dish. 2. NEVER use generic mixtures. 3. BREAK DOWN everything into RAW, basic ingredients. 4. Identify the main protein, base carb, each vegetable separately, and DEDUCE hidden spices EXACTLY on what you see in the image. 5. For calories, protein, and time, use ONLY integers inside strings. 6. CRITICAL COHERENCE RULE: You MUST include a 'pasos' array. Every step in 'pasos' must strictly and exclusively use the ingredients listed in the 'ingredientes' array. DO NOT invent extra ingredients or condiments in the steps that were not declared in the ingredients breakdown. 7. OUTPUT MUST BE IN SPANISH. EXAMPLE FORMAT: {\"plato\": \"Ceviche\", \"calorias\": \"250\", \"proteina\": \"20\", \"tiempo\": \"15\", \"ingredientes\": [{\"nombre\": \"Pescado blanco\", \"detalle\": \"200g en cubos\"}, {\"nombre\": \"Limón\", \"detalle\": \"5 unidades\"}, {\"nombre\": \"Cebolla roja\", \"detalle\": \"1 unidad en juliana\"}], \"pasos\": [\"Cortar el pescado blanco en cubos homogéneos y reservar en frío.\", \"Exprimir los limones asegurando no amargar el jugo.\", \"Mezclar el pescado con la cebolla roja y bañar con el jugo de limón.\"]} Return strictly this JSON without markdown or code blocks."
            },
            {
              "role": "user",
              "content": [
                {
                  "type": "text",
                  "text": "Analyze this image and return strictly the requested JSON matching the exact coherence rules."
                },
                {
                  "type": "image_url",
                  "image_url": {
                    "url": "data:image/jpeg;base64,$base64Image"
                  }
                }
              ]
            }
          ]
        }),
      );

      if (response.statusCode != 200) throw Exception(response.body);

      final data = jsonDecode(response.body);
      String aiResponse = data['choices'][0]['message']['content'];

      // Limpieza robusta de bloques de código markdown recursivos por si la IA los incluye
      aiResponse = aiResponse
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      return jsonDecode(aiResponse);
    } catch (e) {
      print("Error Clarifai (analizarRecetaJson): $e");
      return null;
    }
  }

  /// 4. FUNCIÓN DE RESCATE: Generar preparación para platos antiguos (Económico, rápido y basado en texto)
  static Future<List<String>?> completarPasosFaltantes(String plato, String listaIngredientes) async {
    try {
      if (_apiKey.isEmpty) throw Exception('API KEY no encontrada en .env');

      final response = await http.post(
        Uri.parse(_url),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "model": _model,
          "messages": [
            {
              "role": "system",
              "content": "Eres un chef estricto. Tu tarea es escribir secuencialmente los pasos de preparación para un plato en español. REGLA DE ORO: DEBES usar ÚNICA Y EXCLUSIVAMENTE los ingredientes proporcionados. No inventes condimentos, salsas, aceites ni agua si no están explícitamente en la lista provista. Devuelve ESTRICTAMENTE un arreglo JSON de strings con los pasos, sin formateo markdown ni texto explicativo adicional. Ejemplo: [\"Paso 1...\", \"Paso 2...\"]"
            },
            {
              "role": "user",
              "content": "Plato: $plato. Ingredientes disponibles: $listaIngredientes. Genera los pasos en un arreglo JSON de strings."
            }
          ]
        }),
      );

      if (response.statusCode != 200) throw Exception(response.body);

      final data = jsonDecode(response.body);
      String aiResponse = data['choices'][0]['message']['content'];

      // Limpieza del formato del texto devuelto por seguridad
      aiResponse = aiResponse
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      // Mapeamos el string JSON a una lista nativa de Dart
      List<dynamic> pasosDinamicos = jsonDecode(aiResponse);
      return pasosDinamicos.map((e) => e.toString()).toList();

    } catch (e) {
      print("Error Clarifai (completarPasosFaltantes): $e");
      return null;
    }
  }

  static Future<String> responderDudaChef(String contextoPlato, String preguntaUsuario) async {
    try {
      if (_apiKey.isEmpty) throw Exception('API KEY no encontrada en .env');

      final response = await http.post(
        Uri.parse(_url),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "model": _model,
          "messages": [
            {
              "role": "system",
              "content": "Eres un chef virtual ayudando a un usuario a cocinar. Tienes el siguiente contexto de la receta que el usuario está preparando: $contextoPlato. Responde a la duda del usuario de forma directa, empática y en español. IMPORTANTE: Tu respuesta será leída por un motor de voz (TTS), así que DEBE ser corta (máximo 2 oraciones), conversacional y sin emojis ni formatos especiales."
            },
            {
              "role": "user",
              "content": preguntaUsuario
            }
          ]
        }),
      );

      if (response.statusCode != 200) throw Exception(response.body);

      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'];
    } catch (e) {
      print("Error IA Asistente: $e");
      return "Hubo un pequeño problema al procesar tu duda. ¿Puedes repetirla?";
    }
  }
}
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'virtual_chef_page.dart'; // Asegúrate de que la ruta sea correcta

class RecipeDetailPage extends StatefulWidget {
  final Map<String, dynamic> recipe;

  const RecipeDetailPage({
    super.key,
    required this.recipe,
  });

  @override
  State<RecipeDetailPage> createState() => _RecipeDetailPageState();
}

class _RecipeDetailPageState extends State<RecipeDetailPage> {
  // --- PALETA DE COLORES ---
  final Color primaryColor = const Color(0xFF016782);
  final Color primaryContainer = const Color(0xFF94DFFE);
  final Color surfaceContainerLowest = const Color(0xFFFFFFFF);
  final Color surfaceContainerLow = const Color(0xFFF0F4F7);
  final Color surfaceContainerHighest = const Color(0xFFDCE4E8);
  final Color onSurface = const Color(0xFF2C3437);
  final Color onSurfaceVariant = const Color(0xFF596064);
  final Color outlineVariant = const Color(0xFFACB3B7);
  final Color backgroundColor = const Color(0xFFF7F9FB);

  // --- ESTADOS LOCALES ---
  List<String> _ingredients = [];
  List<bool> _ingredientChecks = [];
  List<String> _steps = [];

  // Estados para Favoritos
  bool _isFavorite = false;
  bool _isLoadingFavorite = true;
  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _parseData();
    _checkIfFavorite(); // Verificamos si ya es favorito al abrir la pantalla
  }

  // --- LÓGICA DE FAVORITOS ---
  Future<void> _checkIfFavorite() async {
    final userId = _supabase.auth.currentUser?.id;
    final recipeId = widget.recipe['id_receta']?.toString();

    if (userId == null || recipeId == null) {
      if (mounted) setState(() => _isLoadingFavorite = false);
      return;
    }

    try {
      final response = await _supabase
          .from('favoritos')
          .select('id_receta')
          .eq('id_usuario', userId)
          .eq('id_receta', recipeId);

      if (mounted) {
        setState(() {
          _isFavorite = response.isNotEmpty;
          _isLoadingFavorite = false;
        });
      }
    } catch (e) {
      debugPrint("Error verificando favorito: $e");
      if (mounted) setState(() => _isLoadingFavorite = false);
    }
  }

  Future<void> _toggleFavorite() async {
    final userId = _supabase.auth.currentUser?.id;
    final recipeId = widget.recipe['id_receta']?.toString();

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Debes iniciar sesión para guardar favoritos")),
      );
      return;
    }
    if (recipeId == null) return;

    // Guardamos el estado anterior por si falla la base de datos
    final bool wasFav = _isFavorite;

    // Actualizamos la UI inmediatamente (optimista)
    setState(() {
      _isFavorite = !wasFav;
    });

    try {
      if (wasFav) {
        await _supabase.from('favoritos').delete().match({
          'id_usuario': userId,
          'id_receta': recipeId,
        });
      } else {
        await _supabase.from('favoritos').insert({
          'id_usuario': userId,
          'id_receta': recipeId,
        });
      }
    } catch (e) {
      debugPrint('Error al actualizar favorito: $e');
      // Revertimos la UI si hubo un error
      if (mounted) {
        setState(() => _isFavorite = wasFav);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error al actualizar favorito. Verifica tu conexión.")),
        );
      }
    }
  }

  // --- LÓGICA DE PARSEO DE BASE DE DATOS ---
  void _parseData() {
    try {
      final data = widget.recipe['instrucciones_json'];
      Map<String, dynamic> decodedData = {};

      if (data is Map) {
        decodedData = Map<String, dynamic>.from(data);
      } else if (data is String) {
        final parsed = jsonDecode(data);
        if (parsed is Map) {
          decodedData = Map<String, dynamic>.from(parsed);
        }
      }

      List<String> extractList(String key1, String key2) {
        var rawList = decodedData[key1] ?? decodedData[key2];
        if (rawList is List) {
          return rawList.map((item) {
            if (item is String) return item;
            if (item is Map) return item.values.map((v) => v.toString()).join(' - ');
            return item.toString();
          }).toList();
        }
        return [];
      }

      _ingredients = extractList('ingredientes', 'ingredients');

      if (_ingredients.isEmpty) {
        final String rawIngredients = widget.recipe['ingredientes_input'] ?? '';
        if (rawIngredients.contains('\n')) {
          _ingredients = rawIngredients.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
        } else if (rawIngredients.contains(',')) {
          _ingredients = rawIngredients.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
        } else if (rawIngredients.trim().isNotEmpty) {
          _ingredients = [rawIngredients.trim()];
        } else {
          _ingredients = ['Sin ingredientes especificados'];
        }
      }
      _ingredientChecks = List.generate(_ingredients.length, (index) => false);

      _steps = extractList('pasos', 'steps');
      if (_steps.isEmpty) {
        _steps = ["No se encontraron instrucciones."];
      }

    } catch (e) {
      debugPrint("Error crítico parseando instrucciones_json: $e");
      _steps = ["Error al cargar las instrucciones."];
      _ingredients = ['Error al cargar ingredientes'];
      _ingredientChecks = [false];
    }
  }

  @override
  Widget build(BuildContext context) {
    final String title = widget.recipe['titulo_receta'] ?? 'Receta sin título';
    final String imageUrl = widget.recipe['imagen_url'] ?? 'https://via.placeholder.com/600';

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leadingWidth: 64,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: IconButton(
            icon: Icon(Icons.arrow_back, color: primaryColor),
            onPressed: () => Navigator.pop(context),
            style: IconButton.styleFrom(
              backgroundColor: surfaceContainerLow,
              shape: const CircleBorder(),
            ),
          ),
        ),
        title: Text(
          "The Digital Curator",
          style: TextStyle(
            color: primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: false,
        // Eliminados los botones de buscar y compartir
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Container(
          width: double.infinity,
          height: 64,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withValues(alpha: 0.3),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: FloatingActionButton.extended(
            onPressed: () {
              // Redirección al Virtual Chef Page, pasándole la receta actual
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => VirtualChefPage(recipeData: widget.recipe), // <--- CAMBIADO A recipeData
                ),
              );
            },
            backgroundColor: primaryColor,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            label: Row(
              children: [
                const Icon(Icons.mic, color: Colors.white),
                const SizedBox(width: 12),
                const Text(
                  "Empezar a Cocinar (Modo Voz)",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HERO IMAGE ---
            SizedBox(
              height: 397,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        Container(color: Colors.grey[300], child: const Icon(Icons.image_not_supported, size: 50)),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          backgroundColor,
                          backgroundColor.withValues(alpha: 0.0),
                        ],
                        stops: const [0.0, 0.4],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // --- CONTENIDO SUPERPUESTO ---
            Transform.translate(
              offset: const Offset(0, -40),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- HEADER CARD ---
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 32,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: onSurface,
                                height: 1.1,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Container(
                            decoration: BoxDecoration(
                              color: primaryContainer.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: IconButton(
                              icon: Icon(
                                _isFavorite ? Icons.favorite : Icons.favorite_border,
                                color: primaryColor,
                              ),
                              onPressed: _isLoadingFavorite ? null : _toggleFavorite,
                            ),
                          )
                        ],
                      ),
                    ),

                    // --- SECCIÓN INGREDIENTES ---
                    const SizedBox(height: 40),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Ingredientes",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: onSurface,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            "${_ingredients.length} items",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Lista de Checkboxes interactivos
                    ...List.generate(_ingredients.length, (index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _ingredientChecks[index] = !_ingredientChecks[index];
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: surfaceContainerLowest,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: Checkbox(
                                    value: _ingredientChecks[index],
                                    onChanged: (val) {
                                      setState(() {
                                        _ingredientChecks[index] = val ?? false;
                                      });
                                    },
                                    activeColor: primaryColor,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                    side: BorderSide(color: outlineVariant),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    _ingredients[index],
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: onSurface,
                                      decoration: _ingredientChecks[index] ? TextDecoration.lineThrough : null,
                                      decorationColor: onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),

                    // --- SECCIÓN PREPARACIÓN (PASOS) ---
                    const SizedBox(height: 48),
                    Text(
                      "Preparación",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: onSurface,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Stack para la línea vertical y los pasos
                    Stack(
                      children: [
                        Positioned(
                          left: 23,
                          top: 24,
                          bottom: 24,
                          child: Container(
                            width: 2,
                            color: surfaceContainerHighest,
                          ),
                        ),
                        Column(
                          children: List.generate(_steps.length, (index) {
                            final bool isFirst = index == 0;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 40.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: isFirst ? primaryColor : surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: isFirst
                                          ? [BoxShadow(color: primaryColor.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))]
                                          : [],
                                    ),
                                    child: Center(
                                      child: Text(
                                        "${index + 1}",
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: isFirst ? Colors.white : onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 24),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Paso ${index + 1}",
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: onSurface,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          _steps[index],
                                          style: TextStyle(
                                            fontSize: 15,
                                            height: 1.6,
                                            color: onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
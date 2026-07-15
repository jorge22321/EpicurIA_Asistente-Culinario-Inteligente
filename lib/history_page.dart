import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'recipe_detail_page.dart';
class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  // --- PALETA DE COLORES ---
  final Color primaryColor = const Color(0xFF016782);
  final Color primaryDim = const Color(0xFF005B73);
  final Color primaryContainer = const Color(0xFF94DFFE);
  final Color backgroundColor = const Color(0xFFF7F9FB);
  final Color surfaceContainerHighest = const Color(0xFFDCE4E8);
  final Color surfaceContainerLowest = const Color(0xFFFFFFFF);
  final Color onSurfaceVariant = const Color(0xFF596064);
  final Color outlineColor = const Color(0xFF747C80);
  final Color errorColor = const Color(0xFFA83836);

  // --- ESTADO LOCAL ---
  int _selectedTabIndex = 0; // 0 = Todo el Historial, 1 = Favoritos
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // --- DATOS DE SUPABASE ---
  List<Map<String, dynamic>> _allRecipes = [];
  Set<String> _favoriteRecipeIds = {};

  final SupabaseClient _supabase = Supabase.instance.client;

  StreamSubscription<List<Map<String, dynamic>>>? _recetasSubscription;
  @override
  void initState() {
    super.initState();
    _setupRealtimeHistory();
  }


  void _setupRealtimeHistory() {
    setState(() => _isLoading = true);
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    // A. Traer los favoritos una sola vez (la UI los actualiza localmente)
    _fetchFavoritesOnce(userId);

    // B. Escuchar la tabla de recetas en TIEMPO REAL
    _recetasSubscription = _supabase
        .from('recetas')
        .stream(primaryKey: ['id_receta']) // Clave primaria de tu tabla
        .eq('id_autor', userId)
        .order('fecha_creacion', ascending: false)
        .listen((datosEnTiempoReal) {
      if (mounted) {
        setState(() {
          _allRecipes = List<Map<String, dynamic>>.from(datosEnTiempoReal);
          _isLoading = false;
        });
      }
    }, onError: (error) {
      debugPrint("Error en el stream de historial: $error");
      if (mounted) setState(() => _isLoading = false);
    });
  }
  @override
  void dispose() {
    _searchController.dispose();
    _recetasSubscription?.cancel();
    super.dispose();
  }

  // --- 1. CARGAR DATOS DESDE SUPABASE ---
  Future<void> _fetchHistoryData() async {
    setState(() => _isLoading = true);
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      // Traer todas las recetas del usuario
      final recipesResponse = await _supabase
          .from('recetas')
          .select()
          .eq('id_autor', userId)
          .order('fecha_creacion', ascending: false);

      // Traer los IDs de las recetas marcadas como favoritas por este usuario
      final favoritesResponse = await _supabase
          .from('favoritos')
          .select('id_receta')
          .eq('id_usuario', userId);

      // Convertir la lista de favoritos a un Set para búsquedas ultra rápidas
      final favIds = (favoritesResponse as List)
          .map((e) => e['id_receta'].toString())
          .toSet();

      if (mounted) {
        setState(() {
          _allRecipes = List<Map<String, dynamic>>.from(recipesResponse);
          _favoriteRecipeIds = favIds;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error cargando historial: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }


  Future<void> _fetchFavoritesOnce(String userId) async {
    try {
      final favoritesResponse = await _supabase
          .from('favoritos')
          .select('id_receta')
          .eq('id_usuario', userId);

      final favIds = (favoritesResponse as List)
          .map((e) => e['id_receta'].toString())
          .toSet();

      if (mounted) {
        setState(() {
          _favoriteRecipeIds = favIds;
        });
      }
    } catch (e) {
      debugPrint("Error cargando favoritos: $e");
    }
  }
  // --- 2. LÓGICA DE FAVORITOS (TOGGLE) ---
  Future<void> _toggleFavorite(String recipeId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Debes iniciar sesión para guardar favoritos")),
      );
      return;
    }

    // Comprobamos el estado actual antes de cambiarlo
    final bool wasFav = _favoriteRecipeIds.contains(recipeId);

    setState(() {
      if (wasFav) {
        _favoriteRecipeIds.remove(recipeId);
      } else {
        _favoriteRecipeIds.add(recipeId);
      }
    });

    try {
      if (wasFav) {
        // Eliminar de favoritos
        await _supabase.from('favoritos').delete().match({
          'id_usuario': userId,
          'id_receta': recipeId,
        });
      } else {
        // Insertar en favoritos
        await _supabase.from('favoritos').insert({
          'id_usuario': userId,
          'id_receta': recipeId,
        });
      }
      // Si llegamos aquí, todo salió bien.
    } catch (e) {
      // Si hay un error (ej. falta de internet o error de base de datos), revertimos
      debugPrint('Error en Supabase Favoritos: $e');
      setState(() {
        if (wasFav) {
          _favoriteRecipeIds.add(recipeId);
        } else {
          _favoriteRecipeIds.remove(recipeId);
        }
      });

      // Avisamos al usuario del error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error al actualizar favorito. Verifica tu conexión.")),
        );
      }
    }
  }

  // --- 3. APLICAR FILTROS Y BÚSQUEDA ---
  List<Map<String, dynamic>> get _displayedRecipes {
    return _allRecipes.where((recipe) {
      final recipeId = recipe['id_receta'].toString();
      final isFav = _favoriteRecipeIds.contains(recipeId);

      // Filtro por Tab (0 = Todo, 1 = Solo Favoritos)
      if (_selectedTabIndex == 1 && !isFav) return false;

      // Filtro por Búsqueda (Texto)
      if (_searchQuery.isNotEmpty) {
        final title = (recipe['titulo_receta'] ?? '').toString().toLowerCase();
        if (!title.contains(_searchQuery.toLowerCase())) return false;
      }

      return true;
    }).toList();
  }

  // Utilidad para formatear la fecha
  String _formatDate(String? isoString) {
    if (isoString == null) return '';
    try {
      final date = DateTime.parse(isoString);
      final months = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
      return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]}, ${date.year}';
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final recipesToShow = _displayedRecipes;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),

                  // Buscador
                  _buildSearchBar(),
                  const SizedBox(height: 24),

                  // Pestañas (Filtros)
                  _buildTabs(),
                  const SizedBox(height: 10),
                ],
              ),
            ),

            // --- LISTA DE RECETAS ---
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator(color: primaryColor))
                  : recipesToShow.isEmpty
                  ? Center(
                child: Text(
                  "No se encontraron recetas.",
                  style: TextStyle(color: onSurfaceVariant),
                ),
              )
                  : ListView.separated(
                padding: const EdgeInsets.only(left: 24, right: 24, bottom: 100), // Espacio para la barra inferior
                itemCount: recipesToShow.length,
                separatorBuilder: (context, index) => const SizedBox(height: 24),
                itemBuilder: (context, index) {
                  return _buildRecipeCard(recipesToShow[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        decoration: InputDecoration(
          hintText: "Buscar por nombre de plato...",
          hintStyle: TextStyle(color: onSurfaceVariant.withOpacity(0.6), fontSize: 14),
          prefixIcon: Icon(Icons.search, color: outlineColor),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return Row(
      children: [
        _buildTabButton("Todo el Historial", 0),
        const SizedBox(width: 12),
        _buildTabButton("Favoritos", 1),
      ],
    );
  }

  Widget _buildTabButton(String text, int index) {
    final bool isSelected = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTabIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : const Color(0xFFF0F4F7),
          borderRadius: BorderRadius.circular(30),
          boxShadow: isSelected
              ? [BoxShadow(color: primaryColor.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))]
              : [],
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : onSurfaceVariant,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildRecipeCard(Map<String, dynamic> recipe) {
    final String recipeId = recipe['id_receta'].toString();
    final bool isFav = _favoriteRecipeIds.contains(recipeId);

    final String title = recipe['titulo_receta'] ?? 'Sin nombre';
    final String imageUrl = recipe['imagen_url'] ?? 'https://via.placeholder.com/600';
    final String dateFormatted = _formatDate(recipe['fecha_creacion']);
    final String time = "${recipe['tiempo_estimado'] ?? 15} min";

    return GestureDetector(
      onTap: () async { // Agregamos 'async'
        // Ponemos 'await' para que la app ESPERE a que regreses de los detalles
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RecipeDetailPage(recipe: recipe),
          ),
        );

        // ¡MAGIA! Cuando el usuario presiona "Atrás" en los detalles, el código continúa aquí.
        // Le pedimos a Supabase que traiga los favoritos actualizados silenciosamente.
        final userId = _supabase.auth.currentUser?.id;
        if (userId != null) {
          _fetchFavoritesOnce(userId);
        }
      },
        child: Container(
      height: 120,
      decoration: BoxDecoration(
        color: surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          // --- LADO IZQUIERDO: IMAGEN ---
          Stack(
            children: [
              SizedBox(
                width: 120, // Imagen cuadrada
                height: double.infinity,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                ),
              ),
              // Corazón sobre la imagen (esquina superior izquierda)
              Positioned(
                top: 8,
                left: 8,
                child: GestureDetector(
                  onTap: () => _toggleFavorite(recipeId),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isFav ? Icons.favorite : Icons.favorite_border,
                      color: isFav ? primaryColor : outlineColor,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // --- LADO DERECHO: DETALLES ---
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Fecha y Badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "ANALIZADO",
                        style: TextStyle(
                          color: primaryColor,
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.1,
                        ),
                      ),
                      Text(
                        dateFormatted,
                        style: TextStyle(
                            fontSize: 10,
                            color: outlineColor,
                            fontWeight: FontWeight.w500
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Título (Máximo 2 líneas)
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3437),
                        height: 1.1,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  // Fila inferior: Tiempo y Botón
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.access_time_rounded, size: 14, color: outlineColor),
                          const SizedBox(width: 4),
                          Text(
                            time,
                            style: TextStyle(
                              fontSize: 11,
                              color: onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      // Pequeño indicador de acción
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: primaryColor.withOpacity(0.4),
                        size: 14,
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
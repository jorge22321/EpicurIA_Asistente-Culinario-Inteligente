/// lib/home_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'recipe_analysis_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/recipe_service.dart';
import 'services/media_service.dart';
import 'services/profile_service.dart';
import 'models/user_profile.dart';

import 'widgets/profile_avatar_menu.dart';
class HomePage extends StatefulWidget {

  final VoidCallback onNavigateToHistory;
  const HomePage({super.key, required this.onNavigateToHistory});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // --- SERVICIOS ---
  final MediaService _mediaService = MediaService();
  final ProfileService _profileService = ProfileService();
  final RecipeService _recipeService = RecipeService();
  // --- ESTADO ---
  UserProfile? _userProfile;
  bool _isLoadingProfile = true;

  List<Map<String, dynamic>> _recentRecipes = [];
  bool _isLoadingRecipes = true;
  // --- PALETA DE COLORES ---
  final Color primaryColor = const Color(0xFF016782);
  final Color primaryDim = const Color(0xFF005B73);
  final Color backgroundColor = const Color(0xFFF7F9FB);
  final Color onBackground = const Color(0xFF2C3437);
  final Color surfaceContainerLow = const Color(0xFFF0F4F7);
  final Color surfaceContainerLowest = const Color(0xFFFFFFFF);
  final Color onSurfaceVariant = const Color(0xFF596064);

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;


      final results = await Future.wait([
        _profileService.getCurrentProfile(),
        _recipeService.getRecentUniqueRecipes(userId),
      ]);

      if (mounted) {
        setState(() {
          _userProfile = results[0] as UserProfile?;
          _recentRecipes = results[1] as List<Map<String, dynamic>>;
          _isLoadingProfile = false;
          _isLoadingRecipes = false;
        });
      }
    } catch (e) {
      debugPrint("Error cargando datos iniciales: $e");
      if (mounted) {
        setState(() {
          _isLoadingProfile = false;
          _isLoadingRecipes = false;
        });
      }
    }
  }


  Future<void> _handleImageSelection(ImageSource source) async {
    final File? imageFile = await _mediaService.pickImage(source);

    if (imageFile != null && mounted) {

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RecipeAnalysisPage(
            imageFile: imageFile,
            userProfile: _userProfile,
          ),
        ),
      );

      if (mounted) {
        setState(() {
          _isLoadingRecipes = true;
        });
        await _loadInitialData();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor.withOpacity(0.9),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: _isLoadingProfile
            ? const SizedBox()
            : Row(
          children: [
            const SizedBox(width: 8),
            Text(
              "Hola, ${_userProfile?.nombre ?? 'Gourmet'}",
              style: TextStyle(
                color: primaryColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          ProfileAvatarMenu(
            userProfile: _userProfile,
            radius: 20.0,
            paddingRight: 24.0,
          ),
        ],
      ),


      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(

          padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 16.0, bottom: 110.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "¿Qué se te antoja\npreparar hoy?",
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: onBackground,
                  height: 1.1,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 16),
              // Línea decorativa
              Container(
                height: 6,
                width: 48,
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 12),

              Center(
                child: Column(
                  children: [
                    _buildMainScanButton(context),
                    const SizedBox(height: 20),
                    _buildGalleryButton(),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // 3. SECCIÓN: ÚLTIMOS ANÁLISIS
              _buildLatestAnalysisSection(),
            ],
          ),
        ),
      ),
    );
  }



  Widget _buildMainScanButton(BuildContext context) {
    return SizedBox(
      width: 320,
      height: 320,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF94DFFE).withOpacity(0.4),
                  blurRadius: 60,
                  spreadRadius: 20,
                ),
              ],
            ),
          ),
          Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(40),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [primaryColor, primaryDim],
              ),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.3),
                  blurRadius: 32,
                  offset: const Offset(0, 16),
                )
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(40),
                onTap: () => _handleImageSelection(ImageSource.camera),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.filter_center_focus, size: 64, color: Colors.white),
                    ),
                    const SizedBox(height: 24),
                    const Text("Escanear Plato", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text("IA Vision Engine Activo", style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGalleryButton() {
    return ElevatedButton.icon(
      onPressed: () => _handleImageSelection(ImageSource.gallery),
      icon: const Icon(Icons.add_photo_alternate_outlined),
      label: const Text("Subir desde la galería"),
      style: ElevatedButton.styleFrom(
        backgroundColor: surfaceContainerLow,
        foregroundColor: primaryColor,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildLatestAnalysisSection() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              "Últimos Análisis",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: onBackground,
              ),
            ),
            if (_recentRecipes.isNotEmpty)
              InkWell(
                onTap: () {
                  // --- CAMBIO AQUÍ: Usamos la función en lugar de Navigator.push ---
                  widget.onNavigateToHistory();
                },
                child: Row(
                  children: [
                    Text(
                      "Ver todos",
                      style: TextStyle(
                        color: primaryColor,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Icon(Icons.arrow_forward, color: primaryColor, size: 16),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),

        if (_isLoadingRecipes)
          const Center(child: CircularProgressIndicator())
        else if (_recentRecipes.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 32.0),
              child: Text(
                "Aún no has analizado ningún plato.\n¡Anímate a escanear tu primera comida!",
                textAlign: TextAlign.center,
                style: TextStyle(color: onSurfaceVariant, fontSize: 14),
              ),
            ),
          )
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            child: Row(
              children: _recentRecipes.map((recipe) {
                final String title = recipe['titulo_receta'] ?? 'Desconocido';
                final String imageUrl = recipe['imagen_url'] ?? 'https://via.placeholder.com/300';

                final String category = "ESCANEADO";

                return Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: _buildDishCard(
                    category: category,
                    title: title,
                    imageUrl: imageUrl,
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildDishCard({required String category, required String title, required String imageUrl}) {
    return Container(
      width: 160,
      decoration: BoxDecoration(
        color: surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              imageUrl,
              height: 140,
              width: double.infinity,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  height: 140,
                  width: double.infinity,
                  color: surfaceContainerLow,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: primaryColor,
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) => Container(
                height: 140,
                width: double.infinity,
                color: surfaceContainerLow,
                child: Icon(Icons.broken_image_rounded, color: onSurfaceVariant, size: 40),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Text(
              category,
              style: TextStyle(
                color: primaryColor,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 4.0, bottom: 8.0, right: 4.0),
            child: Text(
              title,
              style: TextStyle(
                color: onBackground,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
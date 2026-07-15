/// lib/recipe_analysis_page.dart
import 'dart:io';
import 'dart:convert'; // Necesario para el Hash
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:crypto/crypto.dart';
import 'virtual_chef_page.dart';
import 'models/user_profile.dart';
import 'services/storage_service.dart';
import 'services/clarifai_service.dart';
import 'services/recipe_service.dart';
import 'widgets/profile_avatar_menu.dart';
class RecipeAnalysisPage extends StatefulWidget {
  final File imageFile;
  final UserProfile? userProfile;

  const RecipeAnalysisPage({super.key, required this.imageFile, this.userProfile});

  @override
  State<RecipeAnalysisPage> createState() => _RecipeAnalysisPageState();
}

class _RecipeAnalysisPageState extends State<RecipeAnalysisPage> {

  final RecipeService _recipeService = RecipeService();

  Map<String, dynamic>? _datosIA;
  bool _analizando = true;

  List<bool> _checksIngredientes = [];
  bool _mostrarTodosLosIngredientes = false;

  final Color primaryColor = const Color(0xFF016782);
  final Color primaryDim = const Color(0xFF005B73);
  final Color backgroundColor = const Color(0xFFF7F9FB);
  final Color onSurface = const Color(0xFF2C3437);
  final Color onSurfaceVariant = const Color(0xFF596064);
  final Color surfaceContainerLow = const Color(0xFFF0F4F7);
  final Color surfaceContainerLowest = const Color(0xFFFFFFFF);
  final Color secondaryContainer = const Color(0xFFCFE6F1);
  final Color onSecondaryContainer = const Color(0xFF3F555E);

  @override
  void initState() {
    super.initState();
    _ejecutarAnalisisCompleto();
  }

  Future<void> _ejecutarAnalisisCompleto() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) throw Exception("Usuario no autenticado");

      final bytes = await widget.imageFile.readAsBytes();
      final String hashActual = sha256.convert(bytes).toString();
      debugPrint("Huella de la imagen: $hashActual");

      final recetaExistente = await _recipeService.buscarRecetaPorHash(userId, hashActual);

      if (recetaExistente != null) {
        debugPrint("¡IMAGEN ENCONTRADA! Recuperando de la BD de forma instantánea...");

        if (mounted) {
          setState(() {
            _datosIA = Map<String, dynamic>.from(recetaExistente['instrucciones_json'] ?? {});
            _datosIA?['plato'] = recetaExistente['titulo_receta'];
            _datosIA?['tiempo'] = recetaExistente['tiempo_estimado']?.toString();
            _analizando = false;

            if (_datosIA!['ingredientes'] != null) {
              _checksIngredientes = List.generate(
                  (_datosIA!['ingredientes'] as List).length, (index) => false);
            }
          });
        }
        return;
      }

      debugPrint("Imagen nueva. Enviando a IA y subiendo a Storage...");
      final storageService = StorageService();

      var results = await Future.wait([
        storageService.uploadImage(imageFile: widget.imageFile, bucketName: 'recipes'),
        ClarifaiService.analizarRecetaJson(widget.imageFile),
      ]);

      String? url = results[0] as String?;
      Map<String, dynamic>? jsonIA = results[1] as Map<String, dynamic>?;

      if (mounted) {
        // CONTROL CRÍTICO: Si la IA falló, avisamos al usuario y NO guardamos nada en la BD
        if (jsonIA == null) {
          setState(() => _analizando = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('El servidor de IA está despertando. Por favor, regresa e inténtalo de nuevo en unos segundos.'),
              backgroundColor: Colors.amber,
            ),
          );
          return;
        }

        setState(() {
          _datosIA = jsonIA;
          _analizando = false;
          if (_datosIA != null && _datosIA!['ingredientes'] != null) {
            _checksIngredientes = List.generate(
                (_datosIA!['ingredientes'] as List).length, (index) => false);
          }
        });

        if (url != null) {
          _guardarEnBaseDeDatos(url, hashActual);
        }
      }
    } catch (e) {
      debugPrint("Error en el proceso general de análisis: $e");
      if (mounted) setState(() => _analizando = false);
    }
  }

  Future<void> _guardarEnBaseDeDatos(String url, String hash) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      await Supabase.instance.client.from('recetas').insert({
        'id_autor': userId,
        'imagen_url': url,
        'titulo_receta': _datosIA?['plato'] ?? 'Nuevo Platillo',
        'ingredientes_input': 'Analizado por IA',
        'instrucciones_json': _datosIA ?? {},
        'hash_imagen': hash,
      });
      debugPrint("Receta guardada exitosamente en BD con su Hash.");
    } catch (e) {
      debugPrint("Error DB al guardar receta: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          _buildBody(),
          _buildFloatingActionButton(),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          backgroundColor: backgroundColor.withOpacity(0.9),
          floating: true,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: primaryColor),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text("EpicurIA", style: TextStyle(
              color: primaryColor, fontWeight: FontWeight.bold)),
          actions: [
            ProfileAvatarMenu(
              userProfile: widget.userProfile,
              radius: 18.0,
              paddingRight: 16.0,
            ),
          ],
        ),

        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 120),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: secondaryContainer,
                      borderRadius: BorderRadius.circular(20)),
                  child: Text(
                    _analizando ? "ANALYZING..." : "ANALYSIS COMPLETE",
                    style: TextStyle(color: onSecondaryContainer,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      _analizando ? "Identificando..." : (_datosIA?['plato'] ??
                          "Sin nombre"),
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: onSurface,
                        height: 1.1,
                        letterSpacing: -0.5,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Hero(
                    tag: 'dish_photo',
                    child: Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: const [BoxShadow(color: Colors.black12,
                            blurRadius: 10)
                        ],
                        image: DecorationImage(image: FileImage(
                            widget.imageFile), fit: BoxFit.cover),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              Row(
                children: [
                  _buildBentoItem(
                      "CALORIES", "${_datosIA?['calorias'] ?? '---'}", "kcal"),
                  const SizedBox(width: 12),
                  _buildBentoItem(
                      "PROTEIN", "${_datosIA?['proteina'] ?? '---'}", "g"),
                  const SizedBox(width: 12),
                  _buildBentoItem(
                      "TIME", "${_datosIA?['tiempo'] ?? '---'}", "min"),
                ],
              ),
              const SizedBox(height: 32),

              _buildTabs(),
              const SizedBox(height: 24),

              _buildIngredientsCard(),

              const SizedBox(height: 24),

              _buildAIPulse(),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildBentoItem(String label, String value, String unit) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: surfaceContainerLow,
            borderRadius: BorderRadius.circular(18)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 9,
                fontWeight: FontWeight.bold,
                color: onSurfaceVariant,
                letterSpacing: 1.1)),
            const SizedBox(height: 4),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(text: value,
                      style: TextStyle(fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: primaryColor)),
                  TextSpan(text: " $unit",
                      style: TextStyle(fontSize: 12,
                          color: onSurfaceVariant,
                          fontWeight: FontWeight.normal)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Ingredientes", style: TextStyle(fontSize: 16,
                fontWeight: FontWeight.bold,
                color: primaryColor)),
            const SizedBox(height: 4),
            Container(width: 40,
                height: 4,
                decoration: BoxDecoration(color: primaryColor,
                    borderRadius: BorderRadius.circular(2))),
          ],
        ),
        const SizedBox(width: 24),
        Text("Preparación", style: TextStyle(fontSize: 16,
            fontWeight: FontWeight.bold,
            color: onSurfaceVariant.withOpacity(0.5))),
      ],
    );
  }

  Widget _buildIngredientsCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: surfaceContainerLowest,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03),
              blurRadius: 20,
              offset: const Offset(0, 10))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                  Icons.shopping_basket_rounded, color: primaryColor, size: 24),
              const SizedBox(width: 10),
              const Text("Checklist de Ingredientes",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 24),

          if (_analizando)
            const Center(child: CircularProgressIndicator())
          else
            if (_datosIA?['ingredientes'] != null)
              ...() {
                final ingredientes = _datosIA!['ingredientes'] as List<dynamic>;
                final int limite = 3;

                final int aMostrar = (_mostrarTodosLosIngredientes ||
                    ingredientes.length <= limite)
                    ? ingredientes.length
                    : limite;

                List<Widget> items = List.generate(aMostrar, (index) {
                  final item = ingredientes[index];
                  return _buildIngredientRow(
                      index, item['nombre'], item['detalle'] ?? "");
                });

                if (ingredientes.length > limite) {
                  items.add(
                    Center(
                      child: TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _mostrarTodosLosIngredientes =
                            !_mostrarTodosLosIngredientes;
                          });
                        },
                        icon: Icon(
                          _mostrarTodosLosIngredientes
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          color: primaryColor,
                        ),
                        label: Text(
                          _mostrarTodosLosIngredientes
                              ? "Ver menos"
                              : "Ver ${ingredientes.length -
                              limite} ingredientes más",
                          style: TextStyle(
                              color: primaryColor, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  );
                }
                return items;
              }()
        ],
      ),
    );
  }

  Widget _buildIngredientRow(int index, String nombre, String detalle) {
    bool checked = _checksIngredientes[index];
    return GestureDetector(
      onTap: () => setState(() => _checksIngredientes[index] = !checked),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 20.0),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: checked ? primaryColor : surfaceContainerLow,
                borderRadius: BorderRadius.circular(8),
              ),
              child: checked ? const Icon(
                  Icons.check, color: Colors.white, size: 18) : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nombre,
                    style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold,
                      decoration: checked ? TextDecoration.lineThrough : null,
                      color: checked
                          ? onSurfaceVariant.withOpacity(0.5)
                          : onSurface,
                    ),
                  ),
                  if (detalle.isNotEmpty)
                    Text(
                      detalle,
                      style: TextStyle(
                        fontSize: 13, color: onSurfaceVariant.withOpacity(0.7),
                        decoration: checked ? TextDecoration.lineThrough : null,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAIPulse() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: primaryColor.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: primaryColor, shape: BoxShape.circle),
            child: const Icon(
                Icons.auto_awesome, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              "\"He detectado estos ingredientes. ¿Quieres que busque sustitutos saludables?\"",
              style: TextStyle(fontSize: 13,
                  fontWeight: FontWeight.w600,
                  fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return Positioned(
      bottom: 30,
      left: 24,
      right: 24,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 500),
        opacity: _analizando ? 0 : 1,
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            gradient: LinearGradient(colors: [primaryColor, primaryDim]),
            boxShadow: [
              BoxShadow(color: primaryColor.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10))
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(32),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    fullscreenDialog: true,
                    // Enviamos los datos reales de la receta analizada al Chef Virtual
                    builder: (_) => VirtualChefPage(recipeData: _datosIA ?? {}),
                  ),
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.mic_rounded, color: Colors.white, size: 28),
                  SizedBox(width: 12),
                  Text(
                    "Empezar a Cocinar (Modo Voz)",
                    style: TextStyle(color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
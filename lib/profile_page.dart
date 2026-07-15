import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart'; // Asegúrate de que la ruta sea correcta
import 'widgets/profile_avatar_menu.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final supabase = Supabase.instance.client;

  // --- ESTADOS LOCALES ---
  bool _isLoading = false;
  String _userName = "Chef";
  String _userEmail = "...";
  String? _avatarUrl;

  double _cookingLevel = 2.0;
  String _selectedSpeed = 'Normal';
  String _selectedLanguage = 'Español (Latinoamérica)';
  List<String> _allergies = [];

  // --- PALETA DE COLORES ---
  final Color primaryColor = const Color(0xFF016782);
  final Color primaryContainer = const Color(0xFF94DFFE);
  final Color backgroundColor = const Color(0xFFF7F9FB);
  final Color onSurface = const Color(0xFF2C3437);
  final Color onSurfaceVariant = const Color(0xFF596064);
  final Color surfaceContainerLow = const Color(0xFFF0F4F7);
  final Color surfaceContainerHighest = const Color(0xFFDCE4E8);
  final Color surfaceContainerLowest = const Color(0xFFFFFFFF);
  final Color errorColor = const Color(0xFFA83836);

  @override
  void initState() {
    super.initState();
    _cargarDatosUsuario();
  }

  // --- LÓGICA INTELIGENTE DE CARGA DE USUARIO ---
  Future<void> _cargarDatosUsuario() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      // 1. Datos base del Auth
      _userEmail = user.email ?? "Sin correo";

      // 2. Revisar si es usuario de Google
      final esGoogle = user.appMetadata['provider'] == 'google' ||
          user.identities?.any((id) => id.provider == 'google') == true;

      if (esGoogle) {
        // Si es Google, priorizamos su Metadata nativa
        _userName = user.userMetadata?['full_name'] ?? user.userMetadata?['name'] ?? "Chef de Google";
        _avatarUrl = user.userMetadata?['avatar_url'];
      } else {
        // Si es por código/correo, intentamos traer los datos locales guardados en la tabla pública
        try {
          final datosPerfil = await supabase
              .from('user_profiles') // Ajusta al nombre exacto de tu tabla si varía
              .select()
              .eq('id', user.id)
              .maybeSingle();

          if (datosPerfil != null) {
            _userName = datosPerfil['nombre'] ?? "Chef";
            _avatarUrl = datosPerfil['foto_url'];
          } else {
            // Si no tiene registro aún, usamos el email o un tag por defecto
            _userName = user.userMetadata?['name'] ?? _userEmail.split('@').first;
          }
        } catch (e) {
          // Si falla la consulta a la tabla, caemos en un respaldo seguro sin romper la app
          _userName = user.userMetadata?['name'] ?? "Chef";
        }
      }

      // 3. Cargar el resto de preferencias desde la metadata o tu base de datos
      setState(() {
        _cookingLevel = (user.userMetadata?['cooking_level'] ?? 2.0).toDouble();
        _selectedSpeed = user.userMetadata?['voice_speed'] ?? 'Normal';
        _selectedLanguage = user.userMetadata?['language'] ?? 'Español (Latinoamérica)';
        if (user.userMetadata?['allergies'] != null) {
          _allergies = List<String>.from(user.userMetadata?['allergies']);
        }
      });
    } catch (e) {
      debugPrint("Error cargando perfil: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- SUBIR FOTO DE PERFIL ---
  Future<void> _subirImagenPerfil() async {
    final picker = ImagePicker();
    final XFile? imageFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);

    if (imageFile == null) return;

    setState(() => _isLoading = true);

    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final bytes = await imageFile.readAsBytes();
      final fileExt = imageFile.path.split('.').last;
      final fileName = '${user.id}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = 'public/$fileName';

      // Guardar en el Bucket de Storage
      await supabase.storage.from('avatars').uploadBinary(
        filePath,
        bytes,
        fileOptions: FileOptions(upsert: true, contentType: 'image/$fileExt'),
      );

      final imageUrl = supabase.storage.from('avatars').getPublicUrl(filePath);

      // Actualizamos tanto la Auth Metadata como tu tabla pública para sincronía total
      await supabase.auth.updateUser(UserAttributes(data: {'avatar_url': imageUrl}));

      await supabase.from('user_profiles').upsert({
        'id': user.id,
        'foto_url': imageUrl,
        'nombre': _userName,
      });

      setState(() => _avatarUrl = imageUrl);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("¡Foto de perfil actualizada!")));
      }
    } catch (e) {
      debugPrint("Error subiendo imagen: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error al guardar la foto"), backgroundColor: Colors.red));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- GUARDAR PREFERENCIAS ---
  Future<void> _guardarPreferencias() async {
    try {
      await supabase.auth.updateUser(
        UserAttributes(data: {
          'cooking_level': _cookingLevel,
          'voice_speed': _selectedSpeed,
          'language': _selectedLanguage,
          'allergies': _allergies,
        }),
      );
    } catch (e) {
      debugPrint("Error guardando preferencias: $e");
    }
  }

  // --- DIÁLOGO POPUP PARA ESCRIBIR ALERGIA ---
  void _mostrarDialogoNuevaAlergia() {
    final textController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: surfaceContainerLowest,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text("Añadir Alergia", style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
          content: TextField(
            controller: textController,
            autofocus: true,
            decoration: InputDecoration(
              hintText: "Ej. Maní, Mariscos...",
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: primaryColor)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancelar", style: TextStyle(color: onSurfaceVariant)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white),
              onPressed: () {
                final texto = textController.text.trim();
                if (texto.isNotEmpty) {
                  setState(() => _allergies.add(texto));
                  _guardarPreferencias();
                }
                Navigator.pop(context);
              },
              child: const Text("Agregar"),
            ),
          ],
        );
      },
    );
  }

  // --- CERRAR SESIÓN TOTAL ---
  Future<void> _ejecutarCerrarSesion() async {
    setState(() => _isLoading = true);
    try {
      await supabase.auth.signOut();
      if (mounted) {
        // rootNavigator: true asegura que limpie toda la app y vaya al login directo
        Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    } catch (e) {
      debugPrint("Error al cerrar sesión: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(top: 110, left: 24, right: 24, bottom: 32),
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProfileHeader(),
                    const SizedBox(height: 40),
                    _buildDietaryPreferences(),
                    const SizedBox(height: 40),
                    _buildVoiceConfiguration(),
                    const SizedBox(height: 40),
                    _buildAccountManagement(),
                  ],
                ),
              ),
            ),
          ),
          _buildBlurredAppBar(),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.25),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildBlurredAppBar() {
    return Positioned(
      top: 0, left: 0, right: 0,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            color: backgroundColor.withOpacity(0.6),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: SafeArea(
              bottom: false,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("EpicurIA", style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 24, fontWeight: FontWeight.bold, color: primaryColor)),
                  Row(
                    children: [
                      IconButton(icon: Icon(Icons.settings_outlined, color: primaryColor), onPressed: () {}),
                      const SizedBox(width: 8),
                      // Pasamos el modelo construido con los estados reactivos
                      ProfileAvatarMenu(
                        userProfile: UserProfile(id: '', nombre: _userName, fotoUrl: _avatarUrl),
                        radius: 20.0,
                        paddingRight: 0.0,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [primaryColor, primaryContainer], begin: Alignment.bottomLeft, end: Alignment.topRight),
                ),
                child: CircleAvatar(
                  radius: 56,
                  backgroundColor: surfaceContainerHighest,
                  backgroundImage: _avatarUrl != null && _avatarUrl!.isNotEmpty ? NetworkImage(_avatarUrl!) : null,
                  child: _avatarUrl == null || _avatarUrl!.isEmpty
                      ? Icon(Icons.person, size: 50, color: onSurfaceVariant)
                      : null,
                ),
              ),
              Positioned(
                bottom: 4, right: 4,
                child: InkWell(
                  onTap: _subirImagenPerfil,
                  borderRadius: BorderRadius.circular(99),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 8, offset: const Offset(0, 4))],
                    ),
                    child: const Icon(Icons.edit_outlined, color: Colors.white, size: 20),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(_userName, style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 28, fontWeight: FontWeight.bold, color: onSurface)),
          const SizedBox(height: 4),
          Text(_userEmail, style: TextStyle(fontSize: 16, color: onSurfaceVariant, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildDietaryPreferences() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.tune_rounded, color: primaryColor),
            const SizedBox(width: 12),
            Text("Preferencias Dietéticas", style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 20, fontWeight: FontWeight.bold, color: onSurface)),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: surfaceContainerLow, borderRadius: BorderRadius.circular(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Alergias e Intolerancias", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: onSurfaceVariant)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: [
                  ..._allergies.map((alergia) => _buildAllergyChip(alergia)),
                  _buildAddChip(),
                ],
              ),
              const SizedBox(height: 24),
              Text("Nivel de cocina", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: onSurfaceVariant)),
              SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: primaryColor, inactiveTrackColor: surfaceContainerHighest, thumbColor: primaryColor, overlayColor: primaryColor.withOpacity(0.1), trackHeight: 6,
                ),
                child: Slider(
                  value: _cookingLevel, min: 1, max: 3, divisions: 2,
                  onChanged: (value) {
                    setState(() => _cookingLevel = value);
                    _guardarPreferencias();
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildLevelLabel("Principiante", _cookingLevel == 1),
                    _buildLevelLabel("Intermedio", _cookingLevel == 2),
                    _buildLevelLabel("Chef", _cookingLevel == 3),
                  ],
                ),
              )
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAllergyChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: surfaceContainerLowest, borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFACB3B7).withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              setState(() => _allergies.remove(label));
              _guardarPreferencias();
            },
            child: Icon(Icons.close_rounded, size: 16, color: errorColor),
          ),
        ],
      ),
    );
  }

  Widget _buildAddChip() {
    return ActionChip(
      onPressed: _mostrarDialogoNuevaAlergia, // <-- Abre el cuadro de diálogo
      backgroundColor: primaryContainer.withOpacity(0.2),
      side: BorderSide(color: const Color(0xFFACB3B7).withOpacity(0.15)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      avatar: Icon(Icons.add_rounded, size: 18, color: primaryColor),
      label: Text("Añadir", style: TextStyle(color: primaryColor, fontWeight: FontWeight.w600, fontSize: 14)),
    );
  }

  Widget _buildLevelLabel(String text, bool isActive) {
    return Text(text.toUpperCase(), style: TextStyle(fontSize: 10, letterSpacing: 1.0, fontWeight: FontWeight.bold, color: isActive ? primaryColor : onSurfaceVariant));
  }

  Widget _buildVoiceConfiguration() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.settings_voice_rounded, color: primaryColor),
            const SizedBox(width: 12),
            Text("Configuración de Voz", style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 20, fontWeight: FontWeight.bold, color: onSurface)),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: surfaceContainerLow, borderRadius: BorderRadius.circular(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Velocidad de narración", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: onSurfaceVariant)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: surfaceContainerHighest, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    _buildSpeedSegment("Lento"),
                    _buildSpeedSegment("Normal"),
                    _buildSpeedSegment("Rápido"),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text("Idioma del Asistente", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: onSurfaceVariant)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(color: surfaceContainerLowest, borderRadius: BorderRadius.circular(12)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedLanguage, isExpanded: true, icon: Icon(Icons.keyboard_arrow_down_rounded, color: onSurfaceVariant),
                    style: TextStyle(color: onSurface, fontSize: 14, fontFamily: 'Manrope'),
                    items: <String>['Español (Latinoamérica)', 'English (US)', 'Français'].map((String value) {
                      return DropdownMenuItem<String>(value: value, child: Text(value));
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() => _selectedLanguage = newValue);
                        _guardarPreferencias();
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSpeedSegment(String label) {
    final bool isSelected = _selectedSpeed == label;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedSpeed = label);
          _guardarPreferencias();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? surfaceContainerLowest : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected ? [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 2))] : [],
          ),
          child: Center(child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isSelected ? primaryColor : onSurfaceVariant))),
        ),
      ),
    );
  }

  Widget _buildAccountManagement() {
    return Column(
      children: [
        ElevatedButton(
          onPressed: () async {
            if (_userEmail != "Sin correo" && _userEmail != "...") {
              await supabase.auth.resetPasswordForEmail(_userEmail);
              if(mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Se ha enviado un correo para resetear tu contraseña.")));
              }
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: surfaceContainerLowest, foregroundColor: onSurface, elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Cambiar contraseña", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
              Icon(Icons.chevron_right_rounded, color: onSurfaceVariant),
            ],
          ),
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: _ejecutarCerrarSesion, // <-- Usa el método unificado
          style: TextButton.styleFrom(foregroundColor: onSurfaceVariant, padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24)),
          icon: const Icon(Icons.logout_rounded, size: 20),
          label: const Text("Cerrar sesión", style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
        ),
      ],
    );
  }
}
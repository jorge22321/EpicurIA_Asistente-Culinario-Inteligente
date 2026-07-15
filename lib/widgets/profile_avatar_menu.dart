import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';

class ProfileAvatarMenu extends StatelessWidget {
  final UserProfile? userProfile;
  final double radius;
  final double paddingRight;

  const ProfileAvatarMenu({
    super.key,
    required this.userProfile,
    this.radius = 18.0,
    this.paddingRight = 16.0,
  });

  final Color primaryColor = const Color(0xFF016782);
  final Color primaryContainer = const Color(0xFF94DFFE);
  final Color surfaceContainerLow = const Color(0xFFF0F4F7);
  final Color errorColor = const Color(0xFFA83836);

  void _mostrarMenuOpciones(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      // CAMBIO AQUÍ: Renombramos el context del builder a 'sheetContext'
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                ListTile(
                  leading: Icon(Icons.logout_rounded, color: errorColor),
                  title: Text(
                    'Cerrar Sesión',
                    style: TextStyle(
                      color: errorColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: () async {
                    // 1. Cerramos el menú usando su propio contexto (sheetContext)
                    Navigator.pop(sheetContext);

                    try {
                      // 2. Cerramos sesión en Supabase
                      await Supabase.instance.client.auth.signOut();

                      // 3. Redirigimos usando el 'context' de la pantalla principal (el que está vivo)
                      // Añadimos rootNavigator: true para salirnos de cualquier BottomNavigationBar de forma segura
                      if (context.mounted) {
                        Navigator.of(context, rootNavigator: true)
                            .pushNamedAndRemoveUntil('/login', (route) => false);
                      }
                    } catch (e) {
                      debugPrint("Error cerrando sesión en menú: $e");
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool hasImage = userProfile?.fotoUrl != null && userProfile!.fotoUrl!.isNotEmpty;

    return Padding(
      padding: EdgeInsets.only(right: paddingRight),
      child: InkWell(
        onTap: () => _mostrarMenuOpciones(context),
        borderRadius: BorderRadius.circular(50),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: primaryContainer, width: 2),
          ),
          child: CircleAvatar(
            radius: radius,
            backgroundColor: surfaceContainerLow,
            backgroundImage: hasImage ? NetworkImage(userProfile!.fotoUrl!) : null,
            child: !hasImage
                ? Icon(Icons.person, color: primaryColor, size: radius * 1.2)
                : null,
          ),
        ),
      ),
    );
  }
}
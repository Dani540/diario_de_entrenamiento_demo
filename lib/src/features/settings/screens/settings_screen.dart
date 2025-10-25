// lib/src/features/settings/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io'; // Para Platform

// Importa GalleryScreen para acceder a la clave del FAB (o define las claves globalmente)
// import '../../gallery/screens/gallery_screen.dart'; // No ideal, mejor claves globales
// Claves globales (puedes ponerlas en un archivo constants.dart)
const String showFabPrefKey = 'show_gallery_fab';
const String keepArchivedTagsPrefKey = 'keep_archived_tags';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _showFab = true; // Valor por defecto
  bool _keepArchivedTags = false; // Valor por defecto
  bool _isLoading = true; // Para mostrar carga inicial

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // Carga las preferencias al iniciar
  Future<void> _loadSettings() async {
    setState(() { _isLoading = true; });
    // Solo carga si es plataforma soportada
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS || Platform.isAndroid || Platform.isIOS) {
      try {
        final prefs = await SharedPreferences.getInstance();
        setState(() {
          _showFab = prefs.getBool(showFabPrefKey) ?? true;
          _keepArchivedTags = prefs.getBool(keepArchivedTagsPrefKey) ?? false;
        });
      } catch (e) {
        // Manejar error si falla la carga
      }
    }
    setState(() { _isLoading = false; });
  }

  // Guarda la preferencia de visibilidad del FAB
  Future<void> _updateShowFab(bool value) async {
    setState(() { _showFab = value; }); // Actualiza UI
     if (Platform.isWindows || Platform.isLinux || Platform.isMacOS || Platform.isAndroid || Platform.isIOS) {
       try {
         final prefs = await SharedPreferences.getInstance();
         await prefs.setBool(showFabPrefKey, value);
       } catch (e) { /* Manejar error */ }
     }
  }

  // Guarda la preferencia de mantener tags archivados
  Future<void> _updateKeepArchivedTags(bool value) async {
    setState(() { _keepArchivedTags = value; }); // Actualiza UI
     if (Platform.isWindows || Platform.isLinux || Platform.isMacOS || Platform.isAndroid || Platform.isIOS) {
       try {
         final prefs = await SharedPreferences.getInstance();
         await prefs.setBool(keepArchivedTagsPrefKey, value);
       } catch (e) { /* Manejar error */ }
     }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustes'),
        automaticallyImplyLeading: false, // Ocultar botón 'atrás'
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // --- Sección Galería ---
                Text('Galería', style: Theme.of(context).textTheme.titleMedium),
                SwitchListTile(
                  title: const Text('Mostrar botón (+) flotante'),
                  subtitle: const Text('Muestra u oculta el botón rápido para añadir videos en la galería.'),
                  value: _showFab,
                  onChanged: _updateShowFab, // Llama a la función para guardar
                  secondary: const Icon(Icons.add_circle_outline),
                ),

                const Divider(height: 30),

                // --- Sección Instructor ---
                Text('Instructor', style: Theme.of(context).textTheme.titleMedium),
                 SwitchListTile(
                  title: const Text('Considerar tags de videos archivados'),
                  subtitle: const Text('Si está activado, el instructor usará los tags de videos archivados para generar sugerencias.'),
                  value: _keepArchivedTags,
                  onChanged: _updateKeepArchivedTags, // Llama a la función para guardar
                  secondary: const Icon(Icons.history_toggle_off_outlined),
                ),
                 ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: const Text("Nota sobre archivado"),
                    subtitle: const Text("Archivar un video lo oculta de la galería pero no borra el archivo ni sus datos de Hive, permitiendo que el instructor aún los use si esta opción está activa. Para borrar permanentemente, usa la opción desde el menú del video."), // Podríamos añadir opción de borrado permanente aquí
                    dense: true,
                 ),

                const Divider(height: 30),

                // --- Otras secciones (futuro) ---
                // ...
              ],
            ),
    );
  }
}
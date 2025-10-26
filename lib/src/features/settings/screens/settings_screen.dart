// lib/src/features/settings/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

import '../../../core/constants.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _showFab = true;
  bool _keepArchivedTags = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() { _isLoading = true; });

    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS || 
        Platform.isAndroid || Platform.isIOS) {
      try {
        final prefs = await SharedPreferences.getInstance();
        setState(() {
          _showFab = prefs.getBool(AppConstants.showFabPrefKey) ?? true;
          _keepArchivedTags = prefs.getBool(AppConstants.keepArchivedTagsPrefKey) ?? false;
        });
      } catch (e) {
        print('Error cargando configuración: $e');
      }
    }
    
    setState(() { _isLoading = false; });
  }

  Future<void> _updateShowFab(bool value) async {
    setState(() { _showFab = value; });
    
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS || 
        Platform.isAndroid || Platform.isIOS) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(AppConstants.showFabPrefKey, value);
      } catch (e) {
        print('Error guardando preferencia: $e');
      }
    }
  }

  Future<void> _updateKeepArchivedTags(bool value) async {
    setState(() { _keepArchivedTags = value; });
    
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS || 
        Platform.isAndroid || Platform.isIOS) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(AppConstants.keepArchivedTagsPrefKey, value);
      } catch (e) {
        print('Error guardando preferencia: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustes'),
        automaticallyImplyLeading: false,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                Text(
                  'Galería',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                SwitchListTile(
                  title: const Text('Mostrar botón (+) flotante'),
                  subtitle: const Text(
                    'Muestra u oculta el botón rápido para añadir videos en la galería.',
                  ),
                  value: _showFab,
                  onChanged: _updateShowFab,
                  secondary: const Icon(Icons.add_circle_outline),
                ),
                const Divider(height: 30),
                Text(
                  'Instructor',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                SwitchListTile(
                  title: const Text('Considerar tags de videos archivados'),
                  subtitle: const Text(
                    'Si está activado, el instructor usará los tags de videos '
                    'archivados para generar sugerencias.',
                  ),
                  value: _keepArchivedTags,
                  onChanged: _updateKeepArchivedTags,
                  secondary: const Icon(Icons.history_toggle_off_outlined),
                ),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text("Nota sobre archivado"),
                  subtitle: const Text(
                    "Archivar un video lo oculta de la galería pero no borra "
                    "el archivo ni sus datos de Hive, permitiendo que el instructor "
                    "aún los use si esta opción está activa. Para borrar "
                    "permanentemente, usa la opción desde el menú del video.",
                  ),
                  dense: true,
                ),
                const Divider(height: 30),
              ],
            ),
    );
  }
}
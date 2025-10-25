// lib/src/features/instructor/instructor_service.dart
import 'dart:io';
import 'dart:math';
import 'package:diario_de_entrenamiento_demo/src/features/video_data/models/trick_list.dart';
import 'package:hive/hive.dart'; // Necesario para acceder a la caja
import 'package:shared_preferences/shared_preferences.dart'; // Para leer la preferencia

import '../video_data/models/video_entry.dart'; // Importa VideoEntry
import 'trick_data.dart';

class RuleBasedInstructor {
  final Random _random = Random();
  final Box<VideoEntry> _videoBox = Hive.box<VideoEntry>('videoEntriesBox'); // Acceso a la caja

  // Clave para la preferencia de mantener tags archivados
  static const String _keepArchivedTagsPrefKey = 'keep_archived_tags'; // Nueva clave

  // Método principal usando el grafo y considerando archivados
  Future<List<String>> getSuggestions({int count = 3}) async { // Ahora es async
    final Set<String> potentialSuggestions = {};
    final Set<String> knownTricks = {}; // Tags a considerar

    // --- Leer Preferencia y Recolectar Tags ---
    bool keepArchived = false; // Valor por defecto
     if (Platform.isWindows || Platform.isLinux || Platform.isMacOS || Platform.isAndroid || Platform.isIOS) {
        try {
           final prefs = await SharedPreferences.getInstance();
           keepArchived = prefs.getBool(_keepArchivedTagsPrefKey) ?? false;
        } catch (e) { /* Error leyendo prefs, usa valor por defecto */ }
     }


    final allEntries = _videoBox.values;
    for (var entry in allEntries) {
      // Incluir tags si:
      // 1. El video NO está archivado
      // 2. O SI está archivado Y la opción keepArchived está activada
      if (!entry.isArchived || (entry.isArchived && keepArchived)) {
        knownTricks.addAll(entry.tags);
      }
    }
    // ------------------------------------------

    // --- 1. Encontrar la "Frontera" de Aprendizaje (igual que antes) ---
    trickGraph.forEach((trickName, trickNode) {
      if (!knownTricks.contains(trickName)) {
        bool prerequisitesMet = trickNode.prerequisites.isEmpty ||
                                trickNode.prerequisites.every((prereq) => knownTricks.contains(prereq));
        if (prerequisitesMet) {
          potentialSuggestions.add(trickName);
        }
      }
    });

    // --- 2. Sugerencias de Combos (igual que antes) ---
    for (String knownTrick in knownTricks) {
      if (comboSuggestions.containsKey(knownTrick)) {
        for (List<String> combo in comboSuggestions[knownTrick]!) {
          if (knownTricks.contains(combo.first) && !combo.every((move) => knownTricks.contains(move))) {
            potentialSuggestions.add(combo.join(' -> '));
          }
        }
      }
    }

    // --- 3. Filtrado por Dificultad (igual que antes) ---
    Difficulty maxUserDifficulty = Difficulty.fundamental;
    int maxUserDifficultyIndex = 0;
    if (knownTricks.isNotEmpty) {
        maxUserDifficultyIndex = knownTricks
            .map((t) => trickGraph[t]?.difficulty.index ?? 0)
            .where((index) => index != 0) // Evita que 0 sea siempre el max si solo hay fundamentals
            .fold(0, max); // Encuentra el índice máximo (o 0 si está vacío)
        maxUserDifficulty = Difficulty.values[maxUserDifficultyIndex];
    }
    potentialSuggestions.removeWhere((suggestion) {
        if (suggestion.contains('->')) return false;
        final suggestionDifficultyIndex = trickGraph[suggestion]?.difficulty.index ?? 0;
        // Permite sugerir hasta UN nivel por encima
        return suggestionDifficultyIndex > maxUserDifficultyIndex + 1;
    });

    // --- 4. Lógica de Fallback (igual que antes) ---
    if (potentialSuggestions.isEmpty) {
       if (knownTricks.isNotEmpty) {
         potentialSuggestions.add("¡Intenta enlazar ${knownTricks.first} y ${knownTricks.last}!");
         potentialSuggestions.add("Perfecciona tu ${knownTricks.last}");
       } else {
         potentialSuggestions.add(trickGraph.values
             .where((node) => node.difficulty == Difficulty.fundamental && node.prerequisites.isEmpty)
             .map((node) => node.name)
             .firstOrNull ?? "¡Graba tus primeros movimientos!");
         potentialSuggestions.add(TrickingMoves.tornado);
       }
    }

    // --- 5. Finalización: Mezclar y Limitar ---
    List<String> finalSuggestions = potentialSuggestions.toList();
    finalSuggestions.shuffle(_random);
    return finalSuggestions.take(count).toList();
  }
}
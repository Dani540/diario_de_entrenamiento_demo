// lib/src/features/instructor/instructor_service.dart
import 'dart:io';
import 'dart:math';
import 'package:dartz/dartz.dart';
import 'package:diario_de_entrenamiento_demo/src/core/errors/failures.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../tricks/data/models/trick_list.dart';
import '../video_management/data/repositories/video_repository_impl.dart';
import '../../core/constants.dart';
import 'data/models/trick_data.dart';

class RuleBasedInstructor {
  final Random _random = Random();
  final VideoRepositoryImpl _videoRepository;

  RuleBasedInstructor(this._videoRepository);

  /// Método principal usando el grafo y considerando archivados
  Future<List<String>> getSuggestions({int count = 3}) async {
    final Set<String> potentialSuggestions = {};
    final Set<String> knownTricks = {};

    // --- Leer Preferencia y Recolectar Tags ---
    bool keepArchived = false;
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS || 
        Platform.isAndroid || Platform.isIOS) {
      try {
        final prefs = await SharedPreferences.getInstance();
        keepArchived = prefs.getBool(AppConstants.keepArchivedTagsPrefKey) ?? false;
      } catch (e) {
        print('[INSTRUCTOR] Error al leer preferencias: $e');
      }
    }

    // Obtener tags según configuración
    var videoTags = await _videoRepository.getAllTags(includeArchived: keepArchived);
    // Aplanar la lista de listas en un conjunto único desde Either<Failure, List<String>> a List<String>
    videoTags.fold(
      (failure) {
        // En caso de fallo, continuar con conjunto vacío
        videoTags = Left(failure);
      },
      (tags) {
        knownTricks.addAll(tags);
      },
    );

    // --- 1. Encontrar la "Frontera" de Aprendizaje ---
    trickGraph.forEach((trickName, trickNode) {
      if (!knownTricks.contains(trickName)) {
        bool prerequisitesMet = trickNode.prerequisites.isEmpty ||
            trickNode.prerequisites.every((prereq) => knownTricks.contains(prereq));
        if (prerequisitesMet) {
          potentialSuggestions.add(trickName);
        }
      }
    });

    // --- 2. Sugerencias de Combos ---
    for (String knownTrick in knownTricks) {
      if (comboSuggestions.containsKey(knownTrick)) {
        for (List<String> combo in comboSuggestions[knownTrick]!) {
          if (knownTricks.contains(combo.first) && 
              !combo.every((move) => knownTricks.contains(move))) {
            potentialSuggestions.add(combo.join(' -> '));
          }
        }
      }
    }

    // --- 3. Filtrado por Dificultad ---
    Difficulty maxUserDifficulty = Difficulty.fundamental;
    int maxUserDifficultyIndex = 0;
    if (knownTricks.isNotEmpty) {
      maxUserDifficultyIndex = knownTricks
          .map((t) => trickGraph[t]?.difficulty.index ?? 0)
          .where((index) => index != 0)
          .fold(0, max);
      maxUserDifficulty = Difficulty.values[maxUserDifficultyIndex];
    }

    potentialSuggestions.removeWhere((suggestion) {
      if (suggestion.contains('->')) return false;
      final suggestionDifficultyIndex = trickGraph[suggestion]?.difficulty.index ?? 0;
      // Permite sugerir hasta UN nivel por encima
      return suggestionDifficultyIndex > maxUserDifficultyIndex + 1;
    });

    // --- 4. Lógica de Fallback ---
    if (potentialSuggestions.isEmpty) {
      if (knownTricks.isNotEmpty) {
        final tricksAsList = knownTricks.toList();
        potentialSuggestions.add(
          "¡Intenta enlazar ${tricksAsList.first} y ${tricksAsList.last}!"
        );
        potentialSuggestions.add("Perfecciona tu ${tricksAsList.last}");
      } else {
        potentialSuggestions.add(
          trickGraph.values
              .where((node) => 
                  node.difficulty == Difficulty.fundamental && 
                  node.prerequisites.isEmpty)
              .map((node) => node.name)
              .firstOrNull ?? "¡Graba tus primeros movimientos!"
        );
        potentialSuggestions.add(TrickingMoves.tornado);
      }
    }

    // --- 5. Finalización: Mezclar y Limitar ---
    List<String> finalSuggestions = potentialSuggestions.toList();
    finalSuggestions.shuffle(_random);
    return finalSuggestions.take(count).toList();
  }
}
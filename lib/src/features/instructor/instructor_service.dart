// lib/src/features/instructor/instructor_service.dart
import 'dart:math';
// No necesitamos importar TrickingMoves aquí si usamos trick_data
import 'trick_data.dart'; // Importa TrickNode y trickGraph
// Importa comboSuggestions si lo mantienes separado
// import 'rules.dart' show comboSuggestions; // O usa el de trick_data.dart

class RuleBasedInstructor {
  final Random _random = Random();

  // Método principal usando el grafo
  List<String> getSuggestions(List<String> userTricks, {int count = 3}) {
    final Set<String> potentialSuggestions = {};
    final Set<String> knownTricks = userTricks.toSet();

    // --- 1. Encontrar la "Frontera" de Aprendizaje (Movimientos Individuales) ---
    // Itera sobre todos los tricks definidos en el grafo
    trickGraph.forEach((trickName, trickNode) {
      // Considera este trick como posible sugerencia si el usuario NO lo conoce
      if (!knownTricks.contains(trickName)) {
        // Verifica si cumple TODOS los pre-requisitos
        bool prerequisitesMet = true;
        if (trickNode.prerequisites.isNotEmpty) {
          prerequisitesMet = trickNode.prerequisites.every((prereq) => knownTricks.contains(prereq));
        } else {
           // Si no hay prerequisitos listados, considera que se cumplen
           // (Podrías añadir una dificultad mínima aquí si quieres evitar sugerir
           //  movimientos avanzados sin ningún prerequisito listado)
           prerequisitesMet = true;
        }


        // Si cumple los pre-requisitos, es un candidato para la frontera
        if (prerequisitesMet) {
          potentialSuggestions.add(trickName);
        }
      }
    });

    // --- 2. Sugerencias de Combos (Lógica similar a antes) ---
    for (String knownTrick in knownTricks) {
      if (comboSuggestions.containsKey(knownTrick)) {
        for (List<String> combo in comboSuggestions[knownTrick]!) {
          // Verifica si sabe el primer movimiento y no todos
          if (knownTricks.contains(combo.first) && !combo.every((move) => knownTricks.contains(move))) {
            String comboString = combo.join(' -> ');
            // Evita añadir el combo si ya se sugirió un movimiento final del combo individualmente?
            // (Ej: Si ya se sugirió 'Cork', no sugerir 'Master Scoot -> Cork'?) - Decisión de diseño
             potentialSuggestions.add(comboString);
          }
        }
      }
    }

    // --- 3. Filtrado por Dificultad (Opcional pero recomendado) ---
    // Calcula la dificultad máxima o promedio del usuario
    Difficulty maxUserDifficulty = Difficulty.fundamental;
    int maxUserDifficultyIndex = 0;
    if (knownTricks.isNotEmpty) {
        maxUserDifficultyIndex = knownTricks
            .map((t) => trickGraph[t]?.difficulty.index ?? 0) // Obtiene índice de dificultad de cada trick conocido
            .reduce(max); // Encuentra el índice máximo
        maxUserDifficulty = Difficulty.values[maxUserDifficultyIndex];
    }

    // Filtra las sugerencias para que no sean demasiado difíciles
    potentialSuggestions.removeWhere((suggestion) {
        // Si es un combo, no lo filtramos por dificultad por ahora (podría calcularse)
        if (suggestion.contains('->')) return false;
        // Obtiene la dificultad del trick sugerido
        final suggestionDifficultyIndex = trickGraph[suggestion]?.difficulty.index ?? 0;
        // Elimina si la dificultad sugerida es >1 nivel por encima de la máxima del usuario
        // (Ej: Si lo máximo es Basic (índice 1), solo sugiere Intermediate (índice 2), no Advanced (índice 3))
        return suggestionDifficultyIndex > maxUserDifficultyIndex + 1;
    });


    // --- 4. Lógica de Fallback ---
    if (potentialSuggestions.isEmpty) {
       if (knownTricks.isNotEmpty) {
         potentialSuggestions.add("¡Perfecciona tus movimientos actuales!");
         // Podríamos buscar movimientos de dificultad similar que no estén en la frontera
       } else {
         // Sugerencias iniciales si no sabe nada
         potentialSuggestions.add(trickGraph.values
             .where((node) => node.difficulty == Difficulty.fundamental && node.prerequisites.isEmpty)
             .map((node) => node.name)
             .firstOrNull ?? "¡Explora los Fundamentos!"); // Sugiere un fundamental sin prerequisitos
       }
    }

    // --- 5. Finalización: Mezclar y Limitar ---
    List<String> finalSuggestions = potentialSuggestions.toList();
    finalSuggestions.shuffle(_random);
    return finalSuggestions.take(count).toList();
  }
}
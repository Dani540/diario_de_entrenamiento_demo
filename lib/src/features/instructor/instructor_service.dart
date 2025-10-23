// lib/src/features/instructor/instructor_service.dart
import 'dart:math';
import '../video_data/models/trick_list.dart';
import 'rules.dart';

class RuleBasedInstructor {
  final Random _random = Random();

  // Método principal para obtener N sugerencias (incluyendo combos)
  List<String> getSuggestions(List<String> userTricks, {int count = 3}) {
    final Set<String> potentialSuggestions = {}; // Usamos Set para evitar duplicados fácilmente
    final Set<String> uniqueUserTricks = userTricks.toSet();

    // --- 1. Sugerencias de Movimientos Individuales (Progresiones) ---
    for (String knownTrick in uniqueUserTricks) {
      if (trickProgressions.containsKey(knownTrick)) {
        for (String suggestion in trickProgressions[knownTrick]!) {
          // Añadir si no lo sabe ya
          if (!uniqueUserTricks.contains(suggestion)) {
            potentialSuggestions.add(suggestion);
          }
        }
      }
    }

    // --- 2. Sugerencias de Combos ---
    for (String knownTrick in uniqueUserTricks) {
      if (comboSuggestions.containsKey(knownTrick)) {
        for (List<String> combo in comboSuggestions[knownTrick]!) {
          // Algoritmo básico: Si sabe el PRIMER movimiento del combo sugerido,
          // y NO sabe TODOS los movimientos del combo, sugerir el combo completo.
          // (Podría mejorarse para verificar si sabe N-1 movimientos, etc.)

          // Verifica si sabe el primer movimiento (ya lo sabemos por la clave, pero por claridad)
          if (uniqueUserTricks.contains(combo.first)) {
              // Comprueba si ya sabe TODOS los movimientos del combo
              bool knowsAllMovesInCombo = combo.every((move) => uniqueUserTricks.contains(move));

              if (!knowsAllMovesInCombo) {
                 // Formatea el combo como un string "Move1 -> Move2 -> ..."
                 String comboString = combo.join(' -> ');
                 potentialSuggestions.add(comboString);
              }
          }
        }
      }
    }

    // --- 3. Lógica de Fallback (si no hay sugerencias específicas) ---
    if (potentialSuggestions.isEmpty) {
      if (uniqueUserTricks.isNotEmpty) {
        // Sugerencias genéricas si ya sabe algo pero no hay progresión clara
        potentialSuggestions.add("¡Intenta enlazar tus movimientos favoritos!");
        potentialSuggestions.add("¿Puedes hacer ${uniqueUserTricks.first} más limpio?");
         potentialSuggestions.add("Explora variaciones de ${uniqueUserTricks.last}"); // Sugiere variar el último aprendido?
      } else {
        // Sugerencias para principiantes absolutos
        potentialSuggestions.add("¡Bienvenido! Empieza grabando tus básicos.");
        potentialSuggestions.add(TrickingMoves.tornado);
        potentialSuggestions.add(TrickingMoves.cartwheel);
        potentialSuggestions.add(TrickingMoves.scoot);
      }
    }

    // --- 4. Finalización: Mezclar y Limitar ---
    List<String> finalSuggestions = potentialSuggestions.toList();
    finalSuggestions.shuffle(_random);
    return finalSuggestions.take(count).toList();
  }
}
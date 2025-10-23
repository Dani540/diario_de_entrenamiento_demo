// lib/src/features/instructor/rules.dart
import '../video_data/models/trick_list.dart';

// --- REGLAS DE PROGRESIÓN (Movimiento Individual) ---
// Clave: Movimiento conocido.
// Valor: Lista de movimientos individuales sugeridos como siguiente paso.
final Map<String, List<String>> trickProgressions = {
  // --- Kicks ---
  TrickingMoves.tornado: [TrickingMoves.c540, TrickingMoves.cheat720, TrickingMoves.palmKick],
  TrickingMoves.c540: [TrickingMoves.cheat720, TrickingMoves.cheat900, TrickingMoves.jackknife, TrickingMoves.c540Gyro],
  TrickingMoves.hook: [TrickingMoves.cheat720Hook, TrickingMoves.pop360Hook, TrickingMoves.hyperhook],
  TrickingMoves.palmKick: [TrickingMoves.cheat720, TrickingMoves.cheat900], // Similar progression to 540

  // --- Flips & Twists ---
  TrickingMoves.backflip: [TrickingMoves.layout, TrickingMoves.flashKick, TrickingMoves.gainer, TrickingMoves.xOut, TrickingMoves.fullTwist],
  TrickingMoves.aerial: [TrickingMoves.raiz, TrickingMoves.aerialTwist, TrickingMoves.touchdownRaiz], // TD Raiz needs hand touch
  TrickingMoves.raiz: [TrickingMoves.touchdownRaiz, TrickingMoves.sailorMoon, TrickingMoves.gumbi],
  TrickingMoves.scoot: [TrickingMoves.masterScoot, /* Scoot Hyper -> Gainer Switch? */],
  TrickingMoves.masterScoot: [TrickingMoves.cork, TrickingMoves.gainer, TrickingMoves.masterswipe],
  TrickingMoves.cork: [TrickingMoves.doubleCork, TrickingMoves.boxcutter, TrickingMoves.shurikenCork, /* Cork Round */], // Need combo handling for Cork Round
  TrickingMoves.bTwist: [TrickingMoves.doubleBTwist, TrickingMoves.shurikenTwist, /* B-Twist Round */], // Need combo handling
  TrickingMoves.fullTwist: [TrickingMoves.doubleFull],
  TrickingMoves.gainer: [TrickingMoves.gainerSwitch, /* Gainer Flash */], // Gainer Flash requires Flash Kick understanding?

  // --- Transiciones ---
  TrickingMoves.touchdownRaiz: [TrickingMoves.sailorMoon, TrickingMoves.wrapFull], // TD Raiz can lead to wrap setups

  // --- Add more rules based on Club540 and your logic ---
};

// --- REGLAS DE COMBOS SUGERIDOS ---
// Clave: Movimiento conocido que INICIA o HABILITA el combo.
// Valor: Lista de posibles combos (representados como List<String>).
final Map<String, List<List<String>>> comboSuggestions = {
  // Si sabes Tornado, sugiere combos básicos con él
  TrickingMoves.tornado: [
    [TrickingMoves.tornado, TrickingMoves.hook],
    [TrickingMoves.tornado, TrickingMoves.round],
    [TrickingMoves.vanish, TrickingMoves.tornado], // Combo con transición
  ],
  // Si sabes Scoot
  TrickingMoves.scoot: [
    [TrickingMoves.scoot, TrickingMoves.hook],
    [TrickingMoves.scoot, TrickingMoves.backflip],
  ],
  // Si sabes Master Scoot
  TrickingMoves.masterScoot: [
    [TrickingMoves.masterScoot, TrickingMoves.cork],
    [TrickingMoves.masterScoot, TrickingMoves.gainer],
    [TrickingMoves.masterScoot, TrickingMoves.c540],
  ],
  // Si sabes Raiz
  TrickingMoves.raiz: [
    [TrickingMoves.raiz, TrickingMoves.cork],
    [TrickingMoves.raiz, TrickingMoves.fullTwist],
    [TrickingMoves.raiz, TrickingMoves.gainer],
  ],
  // Si sabes Cork, sugiere combos que lo terminan
  TrickingMoves.cork: [
     // Combos que terminan EN Cork ya están cubiertos por Master Scoot, etc.
     // Sugiere combos DESPUÉS de Cork:
     [TrickingMoves.cork, TrickingMoves.round], // Cork Round
     [TrickingMoves.cork, TrickingMoves.hook],
  ],
   // Si sabes B-Twist
  TrickingMoves.bTwist: [
     [TrickingMoves.bTwist, TrickingMoves.round], // B-Twist Round
     [TrickingMoves.bTwist, TrickingMoves.hook],
  ],
  // --- Añade más combos ---
};
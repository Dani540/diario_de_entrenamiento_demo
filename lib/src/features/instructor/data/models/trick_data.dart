
// lib/src/features/instructor/trick_data.dart

import '../../../tricks/data/models/trick_list.dart'; // Importa las constantes

// Enum para categorías (puedes expandir esto)
enum TrickCategory {
  kick, flip, twist, transition, fundamental, basic, intermediate, advanced, invert, power, setup, variation // Añade más según necesites
}

// Enum para dificultad
enum Difficulty {
  fundamental, basic, intermediate, advanced, expert
}

// Clase para representar un nodo en el grafo de tricks
class TrickNode {
  final String name; // Nombre del trick (usar constantes de TrickingMoves)
  final Difficulty difficulty;
  final List<TrickCategory> categories;
  final List<String> prerequisites; // Lista de nombres (constantes) de tricks necesarios
  final List<String> unlocks; // Lista de nombres (constantes) de tricks que este ayuda a aprender (opcional, inverso a prerequisites)

  const TrickNode({
    required this.name,
    required this.difficulty,
    this.categories = const [],
    this.prerequisites = const [],
    this.unlocks = const [],
  });
}

// --- El Grafo de Tricks ---
// Mapa que asocia el nombre del trick (String) con su nodo (TrickNode)
final Map<String, TrickNode> trickGraph = {

  // --- FUNDAMENTALS & TRANSITIONS ---
  TrickingMoves.hook: const TrickNode(
    name: TrickingMoves.hook,
    difficulty: Difficulty.fundamental,
    categories: [TrickCategory.fundamental, TrickCategory.kick],
  ),
  TrickingMoves.round: const TrickNode(
    name: TrickingMoves.round,
    difficulty: Difficulty.fundamental,
    categories: [TrickCategory.fundamental, TrickCategory.kick],
  ),
  TrickingMoves.sideKick: const TrickNode(
    name: TrickingMoves.sideKick,
    difficulty: Difficulty.fundamental,
    categories: [TrickCategory.fundamental, TrickCategory.kick],
  ),
  TrickingMoves.frontKick: const TrickNode(
    name: TrickingMoves.frontKick,
    difficulty: Difficulty.fundamental,
    categories: [TrickCategory.fundamental, TrickCategory.kick],
  ),
  TrickingMoves.backKick: const TrickNode(
    name: TrickingMoves.backKick,
    difficulty: Difficulty.fundamental,
    categories: [TrickCategory.fundamental, TrickCategory.kick],
  ),
  TrickingMoves.crescentKick: const TrickNode(
    name: TrickingMoves.crescentKick,
    difficulty: Difficulty.fundamental,
    categories: [TrickCategory.fundamental, TrickCategory.kick],
  ),
  TrickingMoves.axeKick: const TrickNode(
    name: TrickingMoves.axeKick,
    difficulty: Difficulty.fundamental,
    categories: [TrickCategory.fundamental, TrickCategory.kick],
  ),
  TrickingMoves.tornado: const TrickNode(
    name: TrickingMoves.tornado,
    difficulty: Difficulty.fundamental,
    categories: [TrickCategory.fundamental, TrickCategory.kick, TrickCategory.setup],
    prerequisites: [TrickingMoves.round, TrickingMoves.cheat], // Cheat setup es común
  ),
  TrickingMoves.c360: const TrickNode( // Pop 360 / Cheat 360
    name: TrickingMoves.c360,
    difficulty: Difficulty.fundamental,
    categories: [TrickCategory.fundamental, TrickCategory.kick],
    prerequisites: [TrickingMoves.round, TrickingMoves.cheat], // Pop o Cheat setup
  ),
  TrickingMoves.backflip: const TrickNode(
    name: TrickingMoves.backflip,
    difficulty: Difficulty.fundamental, // Requiere superar miedo
    categories: [TrickCategory.fundamental, TrickCategory.flip, TrickCategory.invert],
  ),
  TrickingMoves.frontflip: const TrickNode(
    name: TrickingMoves.frontflip,
    difficulty: Difficulty.fundamental, // Requiere superar miedo
    categories: [TrickCategory.fundamental, TrickCategory.flip, TrickCategory.invert],
  ),
  TrickingMoves.sideflip: const TrickNode(
    name: TrickingMoves.sideflip,
    difficulty: Difficulty.basic, // A menudo más difícil que back/front
    categories: [TrickCategory.basic, TrickCategory.flip, TrickCategory.invert],
  ),
  TrickingMoves.aerial: const TrickNode(
    name: TrickingMoves.aerial,
    difficulty: Difficulty.basic,
    categories: [TrickCategory.basic, TrickCategory.flip, TrickCategory.invert], // O transition?
    prerequisites: [TrickingMoves.cartwheel],
  ),
  TrickingMoves.cartwheel: const TrickNode(
    name: TrickingMoves.cartwheel,
    difficulty: Difficulty.fundamental,
    categories: [TrickCategory.fundamental, TrickCategory.transition, TrickCategory.invert],
  ),
  TrickingMoves.handstand: const TrickNode(
    name: TrickingMoves.handstand,
    difficulty: Difficulty.fundamental,
    categories: [TrickCategory.fundamental, TrickCategory.invert],
  ),
  TrickingMoves.kipUp: const TrickNode(
    name: TrickingMoves.kipUp,
    difficulty: Difficulty.fundamental,
    categories: [TrickCategory.fundamental, TrickCategory.transition],
  ),
  TrickingMoves.butterflyKick: const TrickNode(
    name: TrickingMoves.butterflyKick,
    difficulty: Difficulty.fundamental,
    categories: [TrickCategory.fundamental, TrickCategory.kick, TrickCategory.transition],
  ),
  TrickingMoves.vanish: const TrickNode(
    name: TrickingMoves.vanish,
    difficulty: Difficulty.fundamental,
    categories: [TrickCategory.fundamental, TrickCategory.transition, TrickCategory.setup],
  ),
  TrickingMoves.scoot: const TrickNode(
    name: TrickingMoves.scoot,
    difficulty: Difficulty.fundamental,
    categories: [TrickCategory.fundamental, TrickCategory.transition, TrickCategory.setup],
  ),
  TrickingMoves.masterScoot: const TrickNode(
    name: TrickingMoves.masterScoot,
    difficulty: Difficulty.basic,
    categories: [TrickCategory.basic, TrickCategory.transition, TrickCategory.setup, TrickCategory.power],
    prerequisites: [TrickingMoves.scoot],
  ),
  TrickingMoves.skipHook: const TrickNode( // Cheat setup
    name: TrickingMoves.skipHook,
    difficulty: Difficulty.fundamental,
    categories: [TrickCategory.fundamental, TrickCategory.transition, TrickCategory.setup],
    prerequisites: [TrickingMoves.hook, TrickingMoves.cheat],
  ),
  TrickingMoves.skipRound: const TrickNode(
    name: TrickingMoves.skipRound,
    difficulty: Difficulty.fundamental,
    categories: [TrickCategory.fundamental, TrickCategory.transition, TrickCategory.setup],
     prerequisites: [TrickingMoves.round, TrickingMoves.cheat],
  ),
  TrickingMoves.touchdownRaiz: const TrickNode(
    name: TrickingMoves.touchdownRaiz,
    difficulty: Difficulty.intermediate, // Requiere buen Raiz y control
    categories: [TrickCategory.intermediate, TrickCategory.transition, TrickCategory.invert, TrickCategory.setup],
    prerequisites: [TrickingMoves.raiz, TrickingMoves.cartwheel], // O Gumbi
  ),
  TrickingMoves.raiz: const TrickNode(
    name: TrickingMoves.raiz,
    difficulty: Difficulty.basic,
    categories: [TrickCategory.basic, TrickCategory.transition, TrickCategory.invert],
    prerequisites: [TrickingMoves.aerial], // Es la progresión más directa
  ),
  TrickingMoves.gumbi: const TrickNode(
    name: TrickingMoves.gumbi,
    difficulty: Difficulty.basic, // Cartwheel a una mano
    categories: [TrickCategory.basic, TrickCategory.transition, TrickCategory.invert, TrickCategory.setup],
    prerequisites: [TrickingMoves.cartwheel],
  ),
  TrickingMoves.cartRaiz: const TrickNode(
    name: TrickingMoves.cartRaiz,
    difficulty: Difficulty.basic,
    categories: [TrickCategory.basic, TrickCategory.transition, TrickCategory.invert],
    prerequisites: [TrickingMoves.cartwheel, TrickingMoves.raiz], // Combina elementos de ambos
  ),
  TrickingMoves.frontSweep: const TrickNode(
    name: TrickingMoves.frontSweep,
    difficulty: Difficulty.fundamental,
    categories: [TrickCategory.fundamental, TrickCategory.transition],
  ),
  TrickingMoves.backSweep: const TrickNode(
    name: TrickingMoves.backSweep,
    difficulty: Difficulty.fundamental,
    categories: [TrickCategory.fundamental, TrickCategory.transition],
  ),
   TrickingMoves.pop: const TrickNode(
    name: TrickingMoves.pop,
    difficulty: Difficulty.fundamental,
    categories: [TrickCategory.fundamental, TrickCategory.setup], // Setup para saltos a dos pies
  ),
  TrickingMoves.cheat: const TrickNode(
    name: TrickingMoves.cheat,
    difficulty: Difficulty.fundamental,
    categories: [TrickCategory.fundamental, TrickCategory.setup], // Setup para Tornado, 540, 720...
  ),
  TrickingMoves.swing: const TrickNode(
    name: TrickingMoves.swing,
    difficulty: Difficulty.fundamental,
    categories: [TrickCategory.fundamental, TrickCategory.transition, TrickCategory.setup], // Setup para Gainers, Corks...
  ),

  // --- BASIC ---
  TrickingMoves.c540: const TrickNode(
    name: TrickingMoves.c540,
    difficulty: Difficulty.basic,
    categories: [TrickCategory.basic, TrickCategory.kick],
    prerequisites: [TrickingMoves.tornado],
  ),
  TrickingMoves.palmKick: const TrickNode(
    name: TrickingMoves.palmKick,
    difficulty: Difficulty.basic,
    categories: [TrickCategory.basic, TrickCategory.kick],
    prerequisites: [TrickingMoves.c360, TrickingMoves.pop], // Pop 360
  ),
  TrickingMoves.backflipLayout: const TrickNode(
    name: TrickingMoves.backflipLayout,
    difficulty: Difficulty.basic,
    categories: [TrickCategory.basic, TrickCategory.flip, TrickCategory.invert, TrickCategory.variation],
    prerequisites: [TrickingMoves.backflip],
  ),
  TrickingMoves.flashKick: const TrickNode(
    name: TrickingMoves.flashKick,
    difficulty: Difficulty.basic, // O Intermedio temprano?
    categories: [TrickCategory.basic, TrickCategory.flip, TrickCategory.invert, TrickCategory.kick],
    prerequisites: [TrickingMoves.backflipLayout], // Layout ayuda mucho
  ),
  TrickingMoves.xOut: const TrickNode(
    name: TrickingMoves.xOut,
    difficulty: Difficulty.basic,
    categories: [TrickCategory.basic, TrickCategory.flip, TrickCategory.invert, TrickCategory.variation],
    prerequisites: [TrickingMoves.backflip],
  ),
  TrickingMoves.webster: const TrickNode(
    name: TrickingMoves.webster,
    difficulty: Difficulty.basic,
    categories: [TrickCategory.basic, TrickCategory.flip, TrickCategory.invert],
    prerequisites: [TrickingMoves.frontflip], // Ayuda con la rotación
  ),
  TrickingMoves.loso: const TrickNode(
    name: TrickingMoves.loso,
    difficulty: Difficulty.basic, // Puede ser más fácil que front handspring
    categories: [TrickCategory.basic, TrickCategory.transition, TrickCategory.invert],
    prerequisites: [TrickingMoves.handstand], // Ayuda con el soporte
  ),
  TrickingMoves.arabian: const TrickNode(
    name: TrickingMoves.arabian,
    difficulty: Difficulty.basic, // A menudo aprendido antes que Full
    categories: [TrickCategory.basic, TrickCategory.flip, TrickCategory.invert, TrickCategory.twist], // Medio giro inicial
    prerequisites: [TrickingMoves.backflip],
  ),
  TrickingMoves.gainer: const TrickNode(
    name: TrickingMoves.gainer,
    difficulty: Difficulty.basic,
    categories: [TrickCategory.basic, TrickCategory.flip, TrickCategory.invert],
    prerequisites: [TrickingMoves.backflip, TrickingMoves.swing], // Backflip y setup de una pierna
  ),
   TrickingMoves.moonKick: const TrickNode(
    name: TrickingMoves.moonKick,
    difficulty: Difficulty.basic,
    categories: [TrickCategory.basic, TrickCategory.flip, TrickCategory.invert, TrickCategory.kick, TrickCategory.variation],
    prerequisites: [TrickingMoves.gainer],
  ),
  TrickingMoves.bTwist: const TrickNode(
    name: TrickingMoves.bTwist,
    difficulty: Difficulty.basic,
    categories: [TrickCategory.basic, TrickCategory.twist, TrickCategory.invert],
    prerequisites: [TrickingMoves.butterflyKick],
  ),
  TrickingMoves.fullTwist: const TrickNode(
    name: TrickingMoves.fullTwist,
    difficulty: Difficulty.intermediate, // Más difícil que Arabian
    categories: [TrickCategory.intermediate, TrickCategory.twist, TrickCategory.invert],
    prerequisites: [TrickingMoves.backflipLayout, TrickingMoves.arabian], // Arabian ayuda mucho
  ),
  TrickingMoves.hyperhook: const TrickNode(
    name: TrickingMoves.hyperhook,
    difficulty: Difficulty.basic,
    categories: [TrickCategory.basic, TrickCategory.kick, TrickCategory.variation],
    prerequisites: [TrickingMoves.hook], // Y a menudo un setup de giro
  ),

  // --- INTERMEDIATE ---
  TrickingMoves.cheat720: const TrickNode(
    name: TrickingMoves.cheat720,
    difficulty: Difficulty.intermediate,
    categories: [TrickCategory.intermediate, TrickCategory.kick],
    prerequisites: [TrickingMoves.c540],
  ),
  TrickingMoves.cheat720Hook: const TrickNode(
    name: TrickingMoves.cheat720Hook,
    difficulty: Difficulty.intermediate,
    categories: [TrickCategory.intermediate, TrickCategory.kick],
    prerequisites: [TrickingMoves.cheat720, TrickingMoves.hook], // O Swing 360 Hook directamente
  ),
  TrickingMoves.pop360Hook: const TrickNode(
    name: TrickingMoves.pop360Hook,
    difficulty: Difficulty.intermediate,
    categories: [TrickCategory.intermediate, TrickCategory.kick],
    prerequisites: [TrickingMoves.palmKick, TrickingMoves.hook],
  ),
  TrickingMoves.backside720: const TrickNode( // Backside 720 kick, no el giro
    name: TrickingMoves.backside720,
    difficulty: Difficulty.intermediate,
    categories: [TrickCategory.intermediate, TrickCategory.kick],
    prerequisites: [TrickingMoves.backKick, /* Giro */], // Requiere buen giro backside
  ),
  TrickingMoves.cork: const TrickNode(
    name: TrickingMoves.cork,
    difficulty: Difficulty.intermediate,
    categories: [TrickCategory.intermediate, TrickCategory.twist, TrickCategory.invert, TrickCategory.power],
    prerequisites: [TrickingMoves.masterScoot, TrickingMoves.gainer], // Raiz también es común
  ),
  TrickingMoves.gainerSwitch: const TrickNode(
    name: TrickingMoves.gainerSwitch,
    difficulty: Difficulty.intermediate,
    categories: [TrickCategory.intermediate, TrickCategory.flip, TrickCategory.invert, TrickCategory.transition],
    prerequisites: [TrickingMoves.gainer],
  ),
  TrickingMoves.aerialTwist: const TrickNode(
    name: TrickingMoves.aerialTwist,
    difficulty: Difficulty.intermediate,
    categories: [TrickCategory.intermediate, TrickCategory.twist, TrickCategory.invert],
    prerequisites: [TrickingMoves.aerial],
  ),
  TrickingMoves.wrapFull: const TrickNode( // Full desde TDRaiz o similar
    name: TrickingMoves.wrapFull,
    difficulty: Difficulty.intermediate,
    categories: [TrickCategory.intermediate, TrickCategory.twist, TrickCategory.invert, TrickCategory.transition],
    prerequisites: [TrickingMoves.touchdownRaiz, TrickingMoves.fullTwist], // Necesitas ambos conceptos
  ),
   TrickingMoves.fullTwistHyperhook: const TrickNode(
    name: TrickingMoves.fullTwistHyperhook,
    difficulty: Difficulty.intermediate, // O Advanced?
    categories: [TrickCategory.intermediate, TrickCategory.twist, TrickCategory.invert, TrickCategory.kick],
    prerequisites: [TrickingMoves.fullTwist, TrickingMoves.hyperhook],
  ),
  TrickingMoves.sailorMoon: const TrickNode(
    name: TrickingMoves.sailorMoon,
    difficulty: Difficulty.intermediate,
    categories: [TrickCategory.intermediate, TrickCategory.transition, TrickCategory.invert, TrickCategory.variation],
    prerequisites: [TrickingMoves.touchdownRaiz],
  ),
  TrickingMoves.touchdownHook: const TrickNode( // Td Raiz con hook al final
    name: TrickingMoves.touchdownHook,
    difficulty: Difficulty.intermediate,
    categories: [TrickCategory.intermediate, TrickCategory.transition, TrickCategory.invert, TrickCategory.kick],
    prerequisites: [TrickingMoves.touchdownRaiz, TrickingMoves.hook],
  ),
  TrickingMoves.masterswipe: const TrickNode(
    name: TrickingMoves.masterswipe,
    difficulty: Difficulty.intermediate,
    categories: [TrickCategory.intermediate, TrickCategory.twist, TrickCategory.invert, TrickCategory.power, TrickCategory.variation],
    prerequisites: [TrickingMoves.masterScoot, TrickingMoves.bTwist], // Combina la entrada y el giro
  ),


  // --- ADVANCED ---
  TrickingMoves.cheat900: const TrickNode(
    name: TrickingMoves.cheat900,
    difficulty: Difficulty.advanced,
    categories: [TrickCategory.advanced, TrickCategory.kick],
    prerequisites: [TrickingMoves.cheat720],
  ),
  TrickingMoves.cheat1080: const TrickNode(
    name: TrickingMoves.cheat1080,
    difficulty: Difficulty.advanced, // O Expert
    categories: [TrickCategory.advanced, TrickCategory.kick],
    prerequisites: [TrickingMoves.cheat900],
  ),
  TrickingMoves.backside900: const TrickNode( // Kick, no giro
    name: TrickingMoves.backside900,
    difficulty: Difficulty.advanced,
    categories: [TrickCategory.advanced, TrickCategory.kick],
    prerequisites: [TrickingMoves.backside720], // Asumiendo que existe
  ),
  TrickingMoves.crowdAwakener: const TrickNode(
    name: TrickingMoves.crowdAwakener,
    difficulty: Difficulty.advanced,
    categories: [TrickCategory.advanced, TrickCategory.kick],
    prerequisites: [TrickingMoves.c540, /* Doble patada? */], // Requiere 540 y habilidad de doble patada
  ),
  TrickingMoves.c540Gyro: const TrickNode(
    name: TrickingMoves.c540Gyro,
    difficulty: Difficulty.advanced,
    categories: [TrickCategory.advanced, TrickCategory.kick, TrickCategory.twist],
    prerequisites: [TrickingMoves.c540], // Y habilidad de giro extra
  ),
  TrickingMoves.jackknife: const TrickNode(
    name: TrickingMoves.jackknife,
    difficulty: Difficulty.advanced,
    categories: [TrickCategory.advanced, TrickCategory.kick, TrickCategory.variation],
    prerequisites: [TrickingMoves.c540], // Requiere flexibilidad y timing
  ),
  TrickingMoves.doubleCork: const TrickNode(
    name: TrickingMoves.doubleCork,
    difficulty: Difficulty.advanced,
    categories: [TrickCategory.advanced, TrickCategory.twist, TrickCategory.invert, TrickCategory.power],
    prerequisites: [TrickingMoves.cork],
  ),
  TrickingMoves.doubleBTwist: const TrickNode(
    name: TrickingMoves.doubleBTwist,
    difficulty: Difficulty.advanced,
    categories: [TrickCategory.advanced, TrickCategory.twist, TrickCategory.invert],
    prerequisites: [TrickingMoves.bTwist],
  ),
  TrickingMoves.doubleFull: const TrickNode(
    name: TrickingMoves.doubleFull,
    difficulty: Difficulty.advanced,
    categories: [TrickCategory.advanced, TrickCategory.twist, TrickCategory.invert],
    prerequisites: [TrickingMoves.fullTwist],
  ),
   TrickingMoves.tripleFull: const TrickNode(
    name: TrickingMoves.tripleFull,
    difficulty: Difficulty.expert,
    categories: [TrickCategory.twist, TrickCategory.invert],
    prerequisites: [TrickingMoves.doubleFull],
  ),
  TrickingMoves.boxcutter: const TrickNode(
    name: TrickingMoves.boxcutter,
    difficulty: Difficulty.advanced,
    categories: [TrickCategory.advanced, TrickCategory.twist, TrickCategory.invert, TrickCategory.power, TrickCategory.variation],
    prerequisites: [TrickingMoves.cork], // Es una variación del cork
  ),
  TrickingMoves.shurikenCork: const TrickNode(
    name: TrickingMoves.shurikenCork,
    difficulty: Difficulty.advanced,
    categories: [TrickCategory.advanced, TrickCategory.twist, TrickCategory.invert, TrickCategory.power, TrickCategory.variation],
    prerequisites: [TrickingMoves.cork], // Variación con patada shuriken
  ),
  TrickingMoves.shurikenTwist: const TrickNode(
    name: TrickingMoves.shurikenTwist,
    difficulty: Difficulty.advanced,
    categories: [TrickCategory.advanced, TrickCategory.twist, TrickCategory.invert, TrickCategory.variation],
    prerequisites: [TrickingMoves.bTwist], // Variación con patada shuriken
  ),
   TrickingMoves.snapuSwipe: const TrickNode(
    name: TrickingMoves.snapuSwipe,
    difficulty: Difficulty.advanced, // O Expert
    categories: [TrickCategory.advanced, TrickCategory.flip, TrickCategory.twist, TrickCategory.invert, TrickCategory.power],
    prerequisites: [/* Full Twist? B-Twist? Es complejo */], // Requiere buen control aéreo y giros
  ),
};

// --- Reglas de Combo (Opcional, si quieres mantenerlas separadas) ---
// Puedes mantener el Map<String, List<List<String>>> comboSuggestions aquí
// o integrarlo en la lógica del instructor directamente.

final Map<String, List<List<String>>> comboSuggestions = {
  TrickingMoves.tornado: [
    [TrickingMoves.tornado, TrickingMoves.hook],
    [TrickingMoves.tornado, TrickingMoves.round],
    [TrickingMoves.vanish, TrickingMoves.tornado],
  ],
  TrickingMoves.scoot: [
    [TrickingMoves.scoot, TrickingMoves.hook],
    [TrickingMoves.scoot, TrickingMoves.backflip],
  ],
  TrickingMoves.masterScoot: [
    [TrickingMoves.masterScoot, TrickingMoves.cork],
    [TrickingMoves.masterScoot, TrickingMoves.gainer],
    [TrickingMoves.masterScoot, TrickingMoves.c540],
  ],
   TrickingMoves.raiz: [
    [TrickingMoves.raiz, TrickingMoves.hook],
    [TrickingMoves.raiz, TrickingMoves.bTwist],
  ],
   TrickingMoves.cork: [
     [TrickingMoves.cork, TrickingMoves.round], // Cork Round
     [TrickingMoves.cork, TrickingMoves.hook],
  ],
   TrickingMoves.bTwist: [
     [TrickingMoves.bTwist, TrickingMoves.round], // B-Twist Round
     [TrickingMoves.bTwist, TrickingMoves.hook],
  ],
  // ... más combos ...
};
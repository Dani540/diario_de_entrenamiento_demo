// lib/src/features/video_data/models/trick_list.dart

// Clase contenedora para las constantes de los movimientos
class TrickingMoves {
  // --- FUNDAMENTALS & TRANSITIONS ---
  // (Kicks Fundamentales)
  static const String hook = 'Hook Kick';
  static const String round = 'Round Kick';
  static const String sideKick = 'Side Kick';
  static const String frontKick = 'Front Kick';
  static const String backKick = 'Back Kick'; // aka Donkey Kick
  static const String crescentKick = 'Crescent Kick';
  static const String axeKick = 'Axe Kick';
  static const String tornado = 'Tornado Kick';
  static const String c360 = '360 Kick'; // Pop, Cheat, Stepover variations exist

  // (Flips/Inverts Fundamentales)
  static const String backflip = 'Backflip';
  static const String frontflip = 'Frontflip';
  static const String sideflip = 'Sideflip';
  static const String aerial = 'Aerial';
  static const String cartwheel = 'Cartwheel';
  static const String handstand = 'Handstand';
  static const String kipUp = 'Kip Up';
  static const String butterflyKick = 'Butterfly Kick (B-Kick)';

  // (Transiciones Fundamentales)
  static const String vanish = 'Vanish';
  static const String scoot = 'Scoot';
  static const String masterScoot = 'Master Scoot';
  static const String skipHook = 'Skip Hook'; // aka Cheat Setup, Stepover Hook
  static const String skipRound = 'Skip Round';
  static const String touchdownRaiz = 'Touchdown Raiz (TD Raiz)';
  static const String raiz = 'Raiz';
  static const String gumbi = 'Gumbi'; // Cartwheel -> TD Raiz
  static const String cartRaiz = 'Cart Raiz'; // Cartwheel -> Raiz (sin manos)
  static const String frontSweep = 'Front Sweep';
  static const String backSweep = 'Back Sweep';
  static const String pop = 'Pop'; // Salto desde dos pies
  static const String cheat = 'Cheat'; // Salto desde una pierna, setup común
  static const String swing = 'Swing'; // Transición balanceando una pierna

  // --- BASIC --- (Movimientos que construyen sobre fundamentales)
  static const String c540 = '540 Kick';
  static const String palmKick = 'Palm Kick'; // aka Pop 360 Kick
  static const String backflipLayout = 'Backflip Layout';
  static const String flashKick = 'Flash Kick';
  static const String xOut = 'X-Out';
  static const String webster = 'Webster';
  static const String loso = 'Loso';
  static const String arabian = 'Arabian';
  static const String gainer = 'Gainer';
  static const String moonKick = 'Moon Kick'; // Gainer con pierna recta
  static const String bTwist = 'B-Twist (Butterfly Twist)';
  static const String fullTwist = 'Full Twist'; // Backflip 360
  static const String hyperhook = 'Hyperhook'; // Hook variation
  static const String layout = 'Layout'; // Backflip Layout

  // --- INTERMEDIATE ---
  static const String cheat720 = 'Cheat 720';
  static const String cheat720Hook = 'Cheat 720 Hook (Swing 360 Hook)';
  static const String pop360Hook = 'Pop 360 Hook';
  static const String backside720 = 'Backside 720 Kick';
  static const String cork = 'Corkscrew (Cork)';
  static const String gainerSwitch = 'Gainer Switch';
  static const String aerialTwist = 'Aerial Twist';
  static const String wrapFull = 'Wrap Full'; // Wrap setup -> Full Twist
  static const String fullTwistHyperhook = 'Full Twist Hyperhook';
  static const String sailorMoon = 'Sailor Moon';
  static const String touchdownHook = 'Touchdown Hook';
  static const String masterswipe = 'Masterswipe'; // Master Scoot + B-Twist like motion

  // --- ADVANCED ---
  static const String cheat900 = 'Cheat 900';
  static const String cheat1080 = 'Cheat 1080';
  static const String backside900 = 'Backside 900';
  static const String crowdAwakener = 'Crowd Awakener (540 Double)';
  static const String c540Gyro = '540 Gyro';
  static const String jackknife = 'Jackknife';
  static const String doubleCork = 'Double Cork';
  static const String doubleBTwist = 'Double B-Twist';
  static const String doubleFull = 'Double Full Twist';
  static const String tripleFull = 'Triple Full Twist';
  static const String boxcutter = 'Boxcutter';
  static const String shurikenCork = 'Shuriken Cork';
  static const String shurikenTwist = 'Shuriken Twist'; // B-Twist variation
  static const String snapuSwipe = 'Snapu Swipe'; // Advanced flip/twist

  // --- Helper Methods ---
  static List<String>? _allMovesCache; // Caché simple

  // Devuelve lista completa, ordenada alfabéticamente
  static List<String> getAllMoves() {
    // Si la caché no está inicializada, créala
    _allMovesCache ??= _generateAllMovesList()..sort();
    return List<String>.from(_allMovesCache!); // Devuelve una copia
  }

  // Método privado para generar la lista (se llama solo una vez)
  static List<String> _generateAllMovesList() {
    return [
      // FUNDAMENTALS & TRANSITIONS
      hook, round, sideKick, frontKick, backKick, crescentKick, axeKick,
      tornado, c360,
      backflip, frontflip, sideflip, aerial, cartwheel, handstand, kipUp,
      butterflyKick,
      vanish, scoot, masterScoot, skipHook, skipRound, touchdownRaiz, raiz,
      gumbi, cartRaiz, frontSweep, backSweep, pop, cheat, swing,

      // BASIC
      c540, palmKick, backflipLayout, flashKick, xOut, webster, loso, arabian,
      gainer, moonKick, bTwist, fullTwist, hyperhook,

      // INTERMEDIATE
      cheat720, cheat720Hook, pop360Hook, backside720, cork, gainerSwitch,
      aerialTwist, wrapFull, fullTwistHyperhook, sailorMoon, touchdownHook,
      masterswipe,

      // ADVANCED
      cheat900, cheat1080, backside900, crowdAwakener, c540Gyro, jackknife,
      doubleCork, doubleBTwist, doubleFull, tripleFull, boxcutter,
      shurikenCork, shurikenTwist, snapuSwipe,
    ];
  }

  static bool isValidMove(String move) {
    return getAllMoves().contains(move);
  }

  static List<String> getFundamentalMoves() {
    return [
      hook,
      round,
      sideKick,
      frontKick,
      backKick,
      crescentKick,
      axeKick,
      tornado,
      c360,
      backflip,
      frontflip,
      sideflip,
      aerial,
      cartwheel,
      handstand,
      kipUp,
      butterflyKick,
      vanish,
      scoot,
      masterScoot,
      skipHook,
      skipRound,
      touchdownRaiz,
      raiz,
      gumbi,
      cartRaiz,
      frontSweep,
      backSweep,
      pop,
      cheat,
      swing,
    ];
  }

  // Get basic moves, intermediate moves, advanced moves methods can be added similarly

  static List<String> getIntermediateMoves() {
    return [
      cheat720,
      cheat720Hook,
      pop360Hook,
      backside720,
      cork,
      gainerSwitch,
      aerialTwist,
      wrapFull,
      fullTwistHyperhook,
      sailorMoon,
      touchdownHook,
      masterswipe,
    ];
  }

  static List<String> getAdvancedMoves() {
    return [
      cheat900,
      cheat1080,
      backside900,
      crowdAwakener,
      c540Gyro,
      jackknife,
      doubleCork,
      doubleBTwist,
      doubleFull,
      tripleFull,
      boxcutter,
      shurikenCork,
      shurikenTwist,
      snapuSwipe,
    ];
  }

  
}
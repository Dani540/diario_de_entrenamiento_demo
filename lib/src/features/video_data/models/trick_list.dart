// lib/src/features/video_data/models/trick_list.dart

class TrickingMoves {
  // --- TRANSITIONS ---
  static const String vanish = 'Vanish';
  static const String skipHook = 'Skip Hook';
  static const String skipRound = 'Skip Round';
  static const String masterScoot = 'Master Scoot';
  // ... (Añade todas las transiciones que necesites de Club540)

  // --- KICKS ---
  static const String hook = 'Hook';
  static const String round = 'Round';
  static const String tornado = 'Tornado';
  static const String c540 = '540 Kick';
  static const String cheat720 = 'Cheat 720';
  // ... (Añade todas las patadas)

  // --- FLIPS & TWISTS ---
  static const String backflip = 'Backflip';
  static const String frontflip = 'Frontflip';
  static const String sideflip = 'Sideflip';
  static const String aerial = 'Aerial';
  static const String cork = 'Corkscrew (Cork)';
  static const String gainer = 'Gainer';
  static const String raiz = 'Raiz';
  static const String bTwist = 'B-Twist';
  // ... (Añade todos los flips y twists)

  // --- Helper para obtener toda la lista ---
  static List<String> getAllMoves() {
    return [
      // Transitions
      vanish, skipHook, skipRound, masterScoot,
      // Kicks
      hook, round, tornado, c540, cheat720,
      // Flips & Twists
      backflip, frontflip, sideflip, aerial, cork, gainer, raiz, bTwist,
      // ... (Añade aquí todas las constantes definidas arriba)
    ];
  }

  // Podrías añadir más listas por categoría si lo necesitas
  // static List<String> getKicks() => [hook, round, tornado, _540, cheat720];
}
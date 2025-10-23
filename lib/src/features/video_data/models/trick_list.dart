// lib/src/features/video_data/models/trick_list.dart

class TrickingMoves {
  // --- FUNDAMENTALS & TRANSITIONS ---
  // (Kicks)
  static const String hook = 'Hook Kick';
  static const String round = 'Round Kick';
  static const String sideKick = 'Side Kick';
  static const String frontKick = 'Front Kick';
  static const String backKick = 'Back Kick'; // aka Donkey Kick
  static const String crescentKick = 'Crescent Kick';
  static const String axeKick = 'Axe Kick';
  static const String tornado = 'Tornado Kick';
  static const String c540 = '540 Kick'; 
  static const String palmKick = 'Palm Kick'; // aka Pop 360
  static const String cheat720 = 'Cheat 720';
  static const String cheat900 = 'Cheat 900';
  static const String cheat1080 = 'Cheat 1080';
  static const String jackknife = 'Jackknife';
  static const String hurricaneKick = 'Hurricane Kick'; // Cheat 720 Double

  // (Flips/Inverts - Basics)
  static const String backflip = 'Backflip';
  static const String frontflip = 'Frontflip';
  static const String sideflip = 'Sideflip';
  static const String aerial = 'Aerial';
  static const String cartwheel = 'Cartwheel';
  static const String handstand = 'Handstand';

  // (Basic Transitions / Setups)
  static const String vanish = 'Vanish';
  static const String scoot = 'Scoot';
  static const String masterScoot = 'Master Scoot';
  static const String skipHook = 'Skip Hook'; // aka Cheat Setup, Stepover Hook
  static const String skipRound = 'Skip Round';
  static const String touchdownRaiz = 'Touchdown Raiz (TD Raiz)';
  static const String raiz = 'Raiz';
  static const String gumbi = 'Gumbi';
  static const String cartRaiz = 'Cart Raiz'; // Cartwheel into Raiz


  // --- INTERMEDIATE & ADVANCED ---
  // (Flips & Twists)
  static const String gainer = 'Gainer'; // Backflip off one leg
  static const String cork = 'Corkscrew (Cork)';
  static const String bTwist = 'B-Twist (Butterfly Twist)';
  static const String fullTwist = 'Full Twist'; // Backflip with 360 twist
  static const String arabian = 'Arabian'; // Flip with initial 180 entry
  static const String webster = 'Webster'; // Frontflip off one leg
  static const String loso = 'Loso'; // Front Handspring variation
  static const String flashKick = 'Flash Kick'; // Backflip Layout + Kick
  static const String xOut = 'X-Out'; // Backflip variation
  static const String layout = 'Layout'; // Backflip variation
  static const String aerialTwist = 'Aerial Twist';
  static const String butterflyKick = 'Butterfly Kick (B-Kick)';
  static const String gainerSwitch = 'Gainer Switch';
  static const String doubleCork = 'Double Cork';
  static const String doubleFull = 'Double Full Twist';
  static const String tripleFull = 'Triple Full Twist';
  static const String doubleBTwist = 'Double B-Twist';

  // (Advanced Kicks / Variations)
  static const String c540Gyro = '540 Gyro';
  static const String cheat720Hook = 'Cheat 720 Hook (Swing 360 Hook)';
  static const String pop360Hook = 'Pop 360 Hook'; // Similar to Palm Kick Hook
  static const String hyperhook = 'Hyperhook'; // Hook variation
  static const String backside900 = 'Backside 900';
  static const String crowdAwakener = 'Crowd Awakener (540 Double)';

  // (Advanced Transitions / Variations)
  static const String masterswipe = 'Masterswipe'; // Master Scoot + Twist
  static const String boxcutter = 'Boxcutter'; // Cork variation
  static const String shurikenCork = 'Shuriken Cork';
  static const String shurikenTwist = 'Shuriken Twist'; // B-Twist variation
  static const String sailorMoon = 'Sailor Moon'; // Raiz variation
  static const String touchdownHook = 'Touchdown Hook';
  static const String wrapFull = 'Wrap Full'; // Wrap -> Full Twist

  // --- Combos (Examples - can be added as needed or handled by rules) ---
  // static const String comboTornadoHook = 'Tornado -> Hook';
  // static const String comboScootCork = 'Scoot -> Cork';


  // --- Helper Methods ---

  // Get all defined moves as a list
  static List<String> getAllMoves() {
    // This is manual but ensures order and inclusion.
    // Consider using reflection if the list gets huge and updates often,
    // but manual is simpler for now.
    return [
      // Fundamentals & Transitions
      hook, round, sideKick, frontKick, backKick, crescentKick, axeKick,
      tornado, c540, palmKick, cheat720, cheat900, cheat1080, jackknife,
      hurricaneKick,
      backflip, frontflip, sideflip, aerial, cartwheel, handstand,
      vanish, scoot, masterScoot, skipHook, skipRound, touchdownRaiz, raiz,
      gumbi, cartRaiz,

      // Intermediate & Advanced
      gainer, cork, bTwist, fullTwist, arabian, webster, loso, flashKick,
      xOut, layout, aerialTwist, butterflyKick, gainerSwitch, doubleCork,
      doubleFull, tripleFull, doubleBTwist,
      c540Gyro, cheat720Hook, pop360Hook, hyperhook, backside900, crowdAwakener,
      masterswipe, boxcutter, shurikenCork, shurikenTwist, sailorMoon,
      touchdownHook, wrapFull,
    ]..sort(); // Ordenar alfabéticamente para consistencia
  }

  // Example: Get moves by category (optional)
  static List<String> getBasicKicks() {
    return [hook, round, sideKick, frontKick, backKick, crescentKick, axeKick, tornado];
  }

  static List<String> getBasicFlips() {
    return [backflip, frontflip, sideflip, aerial, cartwheel];
  }
  
  static List<String> getMediumFlips() {
    return [gainer, cork, bTwist, fullTwist, arabian, webster, loso];
  }

  static List<String> getHardFlips() {
    return [doubleCork, doubleFull, tripleFull, doubleBTwist];
  }

  

}
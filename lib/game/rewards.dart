import 'models.dart';
import 'solver.dart';

/// Gem prices and the win payout. Stars themselves live on [Stars].
abstract final class Rewards {
  static const hintCost = 40;
  static const bottleCost = 70;
  static const freeUndos = 3;

  /// 1 star / 2 stars / 3 stars.
  static int gemsForStars(int stars) {
    if (stars >= 3) return 20;
    if (stars == 2) return 15;
    return 10;
  }
}

/// Free undos for one attempt, plus any granted by a watched ad.
class UndoCredits {
  UndoCredits({this.free = Rewards.freeUndos});

  int free;
  int bonus = 0;

  bool get hasAny => free > 0 || bonus > 0;

  /// Uses one credit. False means the next undo needs an ad.
  bool spend() {
    if (free > 0) {
      free--;
      return true;
    }
    if (bonus > 0) {
      bonus--;
      return true;
    }
    return false;
  }

  /// The extra-undo dialog offers 3 more. The ad itself is still a stub.
  void grantWatchedAd() => bonus += 3;
}

/// One extra empty bottle, once per level.
class ExtraBottle {
  bool used = false;

  bool get available => !used;

  bool take() {
    if (used) return false;
    used = true;
    return true;
  }
}

/// The move a paid hint may show. Null means the fast search found no
/// solution, so the player should undo instead of spending gems.
Move? paidHint(Board board) {
  final line = Solver.solve(board);
  if (line == null || line.isEmpty) return null;
  return line.first;
}

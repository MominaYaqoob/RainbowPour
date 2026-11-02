import 'package:flutter_test/flutter_test.dart';
import 'package:rainbow_pour/game/models.dart';
import 'package:rainbow_pour/game/rewards.dart';
import 'package:rainbow_pour/game/solver.dart';

void main() {
  test('win gems follow the star count', () {
    expect(Rewards.gemsForStars(Stars.count(level: 2, par: 4, moves: 40)), 20);
    expect(Rewards.gemsForStars(Stars.count(level: 8, par: 10, moves: 13)), 20);
    expect(Rewards.gemsForStars(Stars.count(level: 8, par: 10, moves: 14)), 15);
    expect(Rewards.gemsForStars(Stars.count(level: 8, par: 10, moves: 18)), 10);
    expect(Rewards.hintCost, 40);
    expect(Rewards.bottleCost, 70);
  });

  test('three undos are free, then a watched ad grants three more', () {
    final credits = UndoCredits();
    expect(credits.spend(), isTrue);
    expect(credits.spend(), isTrue);
    expect(credits.spend(), isTrue);
    expect(credits.hasAny, isFalse);
    expect(credits.spend(), isFalse);

    credits.grantWatchedAd();
    expect(credits.spend(), isTrue);
    expect(credits.spend(), isTrue);
    expect(credits.bonus, 1);
  });

  test('an extra bottle can be taken once', () {
    final bottle = ExtraBottle();
    expect(bottle.take(), isTrue);
    expect(bottle.available, isFalse);
    expect(bottle.take(), isFalse);
  });

  test('a paid hint exists only when the solver finds a solution', () {
    final open = Board.layers(2, [
      [0, 1],
      [1],
      [0],
      [],
    ]);
    expect(paidHint(open), isNotNull);

    final stuck = Board.layers(4, [
      [0, 0],
      [1, 1, 1],
      [],
    ]);
    expect(paidHint(stuck), isNull);
  });
}

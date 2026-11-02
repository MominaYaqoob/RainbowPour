import 'package:flutter_test/flutter_test.dart';
import 'package:rainbow_pour/game/generator.dart';
import 'package:rainbow_pour/game/level_repository.dart';

void main() {
  test('a level built in an isolate matches the seeded board', () async {
    final direct = LevelGenerator.forLevel(7);
    final loaded = await LevelRepository.getLevel(7);
    expect(loaded.board, direct.board);
    expect(loaded.par, direct.par);
    expect(loaded.solution, direct.solution);

    LevelRepository.prefetch(7);
    final next = await LevelRepository.getLevel(8);
    expect(next.spec.level, 7 + 1);
    expect(await LevelRepository.getLevel(8), next);
  });
}

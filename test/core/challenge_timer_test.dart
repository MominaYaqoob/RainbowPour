import 'package:flutter_test/flutter_test.dart';
import 'package:rainbow_pour/core/challenge_timer.dart';

void main() {
  test('pause holds the countdown, then it expires and can reset', () {
    var ms = 0;
    final timer = ChallengeTimer(
      total: const Duration(seconds: 10),
      elapsed: () => Duration(milliseconds: ms),
    );
    expect(timer.isExpired, isFalse);
    expect(timer.remaining, const Duration(seconds: 10));

    timer.start();
    ms = 1000;
    expect(timer.remaining, const Duration(seconds: 9));
    expect(timer.isRunning, isTrue);

    timer.pause();
    ms = 5000;
    expect(timer.isRunning, isFalse);
    expect(timer.remaining, const Duration(seconds: 9));

    timer.resume();
    ms = 7000;
    expect(timer.remaining, const Duration(seconds: 7));

    ms = 16000;
    expect(timer.isExpired, isTrue);
    expect(timer.remaining, Duration.zero);
    timer.resume();
    expect(timer.isExpired, isTrue);
    expect(timer.remaining, Duration.zero);

    timer.reset();
    expect(timer.isExpired, isFalse);
    expect(timer.remaining, const Duration(seconds: 10));
    ms = 16500;
    expect(timer.remaining, const Duration(milliseconds: 9500));
  });
}

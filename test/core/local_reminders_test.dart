import 'package:flutter_test/flutter_test.dart';
import 'package:rainbow_pour/core/app_prefs.dart';
import 'package:rainbow_pour/core/daily_reward.dart';
import 'package:rainbow_pour/core/local_reminders.dart';
import 'package:rainbow_pour/core/save_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeBackend implements ReminderBackend {
  final List<List<Reminder>> calls = [];
  bool fail = false;

  @override
  Future<void> replaceAll(List<Reminder> reminders) async {
    if (fail) throw StateError('no scheduler');
    calls.add(reminders);
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AppPrefs.resetForTest();
  });

  group('planReminders', () {
    test('a fresh player gets today (before 10:00) and the next 6 days', () {
      final now = DateTime(2026, 3, 10, 8, 30);
      final plan = planReminders(DailyState(), now);
      expect(plan.length, 7);
      expect(plan.first.when, DateTime(2026, 3, 10, 10));
      expect(plan.last.when, DateTime(2026, 3, 16, 10));
      expect(plan.first.body, contains('reward and daily challenge'));
    });

    test('after 10:00 today is skipped', () {
      final now = DateTime(2026, 3, 10, 10, 0, 1);
      final plan = planReminders(DailyState(), now);
      expect(plan.length, 6);
      expect(plan.first.when, DateTime(2026, 3, 11, 10));
    });

    test('reward claimed and challenge done today: nothing for today', () {
      final now = DateTime(2026, 3, 10, 8);
      final s = DailyState()
        ..lastClaimDay = dayKey(now)
        ..challengeDone.add(dayKey(now));
      final plan = planReminders(s, now);
      expect(plan.length, 6);
      expect(plan.first.when, DateTime(2026, 3, 11, 10));
    });

    test('only what is still open is mentioned today', () {
      final now = DateTime(2026, 3, 10, 8);
      final claimed = DailyState()..lastClaimDay = dayKey(now);
      expect(planReminders(claimed, now).first.body, contains('challenge'));
      expect(
        planReminders(claimed, now).first.body,
        isNot(contains('daily reward')),
      );

      final challengeDone = DailyState()..challengeDone.add(dayKey(now));
      expect(planReminders(challengeDone, now).first.body, contains('reward'));
      expect(
        planReminders(challengeDone, now).first.body,
        isNot(contains('challenge')),
      );
    });

    test('ids are unique and bodies vary over the week', () {
      final plan = planReminders(DailyState(), DateTime(2026, 3, 10, 8));
      expect(plan.map((r) => r.id).toSet().length, plan.length);
      expect(plan.map((r) => r.body).toSet().length, greaterThan(1));
    });

    test('the month end rolls over to the next month', () {
      final plan = planReminders(DailyState(), DateTime(2026, 3, 30, 12));
      expect(plan.first.when, DateTime(2026, 3, 31, 10));
      expect(plan[1].when, DateTime(2026, 4, 1, 10));
    });
  });

  group('LocalReminders', () {
    test('schedules the plan from the saved state', () async {
      final fake = FakeBackend();
      final service = LocalReminders(backend: fake, supported: true);
      await service.refresh(now: DateTime(2026, 3, 10, 8));
      expect(fake.calls.length, 1);
      expect(fake.calls.single.length, 7);
    });

    test('the Notifications switch off cancels everything', () async {
      await AppPrefs.setFlag('notifications', false);
      AppPrefs.resetForTest();
      final fake = FakeBackend();
      final service = LocalReminders(backend: fake, supported: true);
      await service.refresh(now: DateTime(2026, 3, 10, 8));
      expect(fake.calls.single, isEmpty);
    });

    test('an error never reaches the caller', () async {
      final fake = FakeBackend()..fail = true;
      final service = LocalReminders(backend: fake, supported: true);
      await expectLater(service.refresh(), completes);
    });

    test('unsupported platforms (web) do nothing', () async {
      final fake = FakeBackend();
      final service = LocalReminders(backend: fake, supported: false);
      await service.refresh();
      expect(fake.calls, isEmpty);
    });
  });
}

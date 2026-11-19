import 'package:flutter_test/flutter_test.dart';
import 'package:rainbow_pour/core/app_prefs.dart';
import 'package:rainbow_pour/core/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeBackend implements NotificationBackend {
  final List<bool> active = [];
  int permissionAsks = 0;
  bool fail = false;

  @override
  Future<void> setActive(bool on) async {
    if (fail) throw StateError('fcm down');
    active.add(on);
  }

  @override
  Future<bool> requestPermission() async {
    permissionAsks++;
    return true;
  }
}

NotificationService make(FakeBackend fake, {bool supported = true}) =>
    NotificationService(backend: fake, supported: supported);

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AppPrefs.resetForTest();
  });

  test('nothing starts before consent', () async {
    final fake = FakeBackend();
    final service = make(fake);
    await service.load();
    expect(fake.active, isEmpty);
    expect(service.active, isFalse);
    expect(
      await service.maybeAskPermission(levelsDone: 10),
      isFalse,
      reason: 'no consent yet',
    );
  });

  test('consent turns it on, losing consent turns it off', () async {
    final fake = FakeBackend();
    final service = make(fake);
    await service.setConsent(true);
    expect(service.active, isTrue);
    await service.setConsent(true); // same state: no second call
    await service.setConsent(false);
    expect(fake.active, [true, false]);
  });

  test('the Settings switch off keeps it off even with consent', () async {
    final fake = FakeBackend();
    final service = make(fake);
    await service.setConsent(true);
    await service.setSwitch(false);
    expect(service.active, isFalse);
    expect(fake.active, [true, false]);
    await service.setSwitch(true);
    expect(service.active, isTrue);
    expect(fake.permissionAsks, 1, reason: 'switching on asks for permission');
  });

  test('the saved switch is read at launch', () async {
    await AppPrefs.setFlag('notifications', false);
    AppPrefs.resetForTest();
    final fake = FakeBackend();
    final service = make(fake);
    await service.load();
    await service.setConsent(true);
    expect(service.active, isFalse);
    expect(fake.active, isEmpty);
  });

  test('the permission dialog appears once, after enough levels', () async {
    final fake = FakeBackend();
    final service = make(fake);
    await service.setConsent(true);
    expect(await service.maybeAskPermission(levelsDone: 1), isFalse);
    expect(fake.permissionAsks, 0);
    expect(await service.maybeAskPermission(levelsDone: 2), isTrue);
    expect(await service.maybeAskPermission(levelsDone: 5), isFalse);
    expect(fake.permissionAsks, 1);
  });

  test('a Firebase error never reaches the caller', () async {
    final fake = FakeBackend()..fail = true;
    final service = make(fake);
    await expectLater(service.setConsent(true), completes);
  });

  test('unsupported platforms (web) do nothing', () async {
    final fake = FakeBackend();
    final service = make(fake, supported: false);
    await service.setConsent(true);
    await service.setSwitch(true);
    expect(await service.maybeAskPermission(levelsDone: 9), isFalse);
    expect(fake.active, isEmpty);
    expect(fake.permissionAsks, 0);
  });
}

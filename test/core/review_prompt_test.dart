import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rainbow_pour/core/app_links.dart';
import 'package:rainbow_pour/core/app_prefs.dart';
import 'package:rainbow_pour/core/review_prompt.dart';
import 'package:rainbow_pour/screens/settings/rate_us_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeReview implements ReviewGateway {
  bool available = true;
  bool fail = false;
  int requests = 0;
  int listings = 0;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<void> requestReview() async {
    if (fail) throw StateError('no play services');
    requests++;
  }

  @override
  Future<void> openStoreListing() async => listings++;
}

void main() {
  final now = DateTime(2026, 11, 17, 12);

  group('reviewAllowed', () {
    bool ok({int level = 8, String? asked, int seen = 0, DateTime? at}) =>
        reviewAllowed(
          levelWon: level,
          lastAskedDay: asked,
          lastSeenMs: seen,
          now: at ?? now,
        );

    test('not before level 5, allowed from level 5', () {
      expect(ok(level: 4), isFalse);
      expect(ok(level: 5), isTrue);
    });

    test('blocked for 29 days, allowed at 30', () {
      expect(ok(asked: '2026-10-19'), isFalse); // 29 days ago
      expect(ok(asked: '2026-10-18'), isTrue); // 30 days ago
      expect(ok(asked: '2026-11-17'), isFalse); // today
    });

    test('blocked when the clock went back, allowed with a small drift', () {
      final ahead = now.add(const Duration(days: 2)).millisecondsSinceEpoch;
      expect(ok(seen: ahead), isFalse);
      final slightly = now
          .add(const Duration(minutes: 1))
          .millisecondsSinceEpoch;
      expect(ok(seen: slightly), isTrue);
    });

    test('a damaged stored day counts as never asked', () {
      expect(ok(asked: 'not a day'), isTrue);
    });
  });

  group('ReviewPrompt', () {
    late FakeReview fake;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      AppPrefs.resetForTest();
      fake = FakeReview();
      ReviewPrompt.gateway = fake;
    });

    test('asks once, remembers the day, then waits 30 days', () async {
      expect(await ReviewPrompt.maybeAsk(levelWon: 6, now: now), isTrue);
      expect(fake.requests, 1);
      expect(await AppPrefs.reviewAskedDay(), '2026-11-17');
      expect(
        await ReviewPrompt.maybeAsk(
          levelWon: 7,
          now: now.add(const Duration(days: 10)),
        ),
        isFalse,
      );
      expect(fake.requests, 1);
      expect(
        await ReviewPrompt.maybeAsk(
          levelWon: 40,
          now: now.add(const Duration(days: 30)),
        ),
        isTrue,
      );
      expect(fake.requests, 2);
    });

    test('nothing before level 5 and nothing when it is unavailable', () async {
      expect(await ReviewPrompt.maybeAsk(levelWon: 3, now: now), isFalse);
      fake.available = false;
      expect(await ReviewPrompt.maybeAsk(levelWon: 9, now: now), isFalse);
      expect(fake.requests, 0);
      expect(await AppPrefs.reviewAskedDay(), isNull);
    });

    test('a plugin error never escapes', () async {
      fake.fail = true;
      expect(await ReviewPrompt.maybeAsk(levelWon: 9, now: now), isFalse);
    });

    test('unsupported platforms (web) do nothing', () async {
      expect(
        await ReviewPrompt.maybeAsk(levelWon: 9, now: now, supported: false),
        isFalse,
      );
      expect(fake.requests, 0);
    });

    test(
      'rateNow ignores the 30-day rule and falls back to the store',
      () async {
        await AppPrefs.markReviewAsked(now);
        expect(await ReviewPrompt.rateNow(now: now), isTrue);
        expect(fake.requests, 1);
        fake.available = false;
        expect(await ReviewPrompt.rateNow(now: now), isTrue);
        expect(fake.listings, 1);
      },
    );

    test('the review day is stored and read back from the save', () async {
      await AppPrefs.markReviewAsked(DateTime(2026, 1, 5));
      AppPrefs.resetForTest();
      expect(await AppPrefs.reviewAskedDay(), '2026-1-5');
    });
  });

  group('AppLinks.open', () {
    final opened = <Uri>[];

    setUp(() {
      opened.clear();
      AppLinks.launcher = (url) async {
        opened.add(url);
        return true;
      };
    });

    testWidgets('an empty address says coming soon and never launches', (
      tester,
    ) async {
      late BuildContext ctx;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (c) {
              ctx = c;
              return const SizedBox();
            },
          ),
        ),
      );
      AppLinks.open(ctx, '', title: 'Privacy Policy');
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('Privacy Policy'), findsWidgets);
      expect(find.text('This page is coming soon.'), findsOneWidget);
      expect(opened, isEmpty);
    });

    testWidgets('a real address is launched', (tester) async {
      late BuildContext ctx;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (c) {
              ctx = c;
              return const SizedBox();
            },
          ),
        ),
      );
      final ok = await AppLinks.open(
        ctx,
        'https://example.com/privacy',
        title: 'Privacy Policy',
      );
      expect(ok, isTrue);
      expect(opened.single.toString(), 'https://example.com/privacy');
    });

    testWidgets('a page that cannot open shows a message and never throws', (
      tester,
    ) async {
      AppLinks.launcher = (url) async => throw StateError('no browser');
      late BuildContext ctx;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (c) {
              ctx = c;
              return const SizedBox();
            },
          ),
        ),
      );
      AppLinks.open(ctx, 'https://example.com', title: 'Terms of Service');
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.textContaining('could not be opened'), findsOneWidget);
    });

    test(
      'the owner links are empty until supplied and the store link is set',
      () {
        expect(AppLinks.privacyPolicyUrl, isEmpty);
        expect(AppLinks.termsUrl, isEmpty);
        expect(AppLinks.playStoreUrl, contains('id=com.gamezium.rainbowpour'));
      },
    );
  });

  group('Rate dialog', () {
    late FakeReview fake;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      AppPrefs.resetForTest();
      fake = FakeReview();
      ReviewPrompt.gateway = fake;
    });

    Future<void> openDialog(WidgetTester tester) async {
      late BuildContext ctx;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (c) {
              ctx = c;
              return const SizedBox();
            },
          ),
        ),
      );
      RateUsDialog.show(ctx);
      await tester.pump(const Duration(milliseconds: 600));
    }

    testWidgets('five stars ask for a review in the store', (tester) async {
      await openDialog(tester);
      await tester.tap(find.byIcon(Icons.star_rounded).at(4));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Rate us'), findsOneWidget);
      await tester.tap(find.text('Rate us'));
      await tester.pump(const Duration(milliseconds: 600));
      expect(fake.requests, 1);
    });

    testWidgets('two stars only get a thank-you, never the store', (
      tester,
    ) async {
      await openDialog(tester);
      await tester.tap(find.byIcon(Icons.star_rounded).at(1));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Send'), findsOneWidget);
      await tester.tap(find.text('Send'));
      await tester.pump(const Duration(milliseconds: 800));
      expect(find.text('Thank you!'), findsWidgets);
      expect(fake.requests, 0);
      expect(fake.listings, 0);
    });

    testWidgets('no stars chosen: the button does nothing', (tester) async {
      await openDialog(tester);
      await tester.tap(find.text('Rate us'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Rate us'), findsOneWidget);
      expect(fake.requests, 0);
    });
  });
}

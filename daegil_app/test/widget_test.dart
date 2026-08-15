import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daegil_app/app/app.dart';
import 'package:daegil_app/app/router.dart';
import 'package:daegil_app/core/config/app_config.dart';
import 'package:daegil_app/core/errors/app_failure.dart';
import 'package:daegil_app/features/ads/domain/rewarded_ad_service.dart';
import 'package:daegil_app/features/ads/presentation/rewarded_ad_controller.dart';
import 'package:daegil_app/features/ads/domain/ssv_verification.dart';
import 'package:daegil_app/features/auth/presentation/auth_screen.dart';
import 'package:daegil_app/features/fortune/domain/fortune_generation.dart';
import 'package:daegil_app/features/fortune/presentation/fortune_result_screen.dart';
import 'package:daegil_app/features/profile/models/birth_profile.dart';
import 'package:daegil_app/features/passes/domain/fortune_pass_ledger.dart';
import 'package:daegil_app/features/notifications/domain/local_notification_service.dart';
import 'package:daegil_app/features/settings/data/account_service.dart';
import 'package:daegil_app/features/settings/presentation/settings_screens.dart';
import 'package:daegil_app/features/telemetry/domain/telemetry_service.dart';

void main() {
  testWidgets('auth route renders the legal gate', (tester) async {
    const config = AppConfig(
      environment: AppEnvironment.dev,
      supabaseUrl: '',
      supabasePublishableKey: '',
      admobRewardedUnitId: '',
    );
    final router = buildLunaRouter(config);
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        child: LunaApp(config: config, router: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('오늘의 흐름을 읽어볼까냥?'), findsOneWidget);
    expect(find.text('만 14세 이상입니다.'), findsOneWidget);
  });

  testWidgets('required checks enable social login', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: AuthScreen())),
    );
    await tester.pumpAndSettle();

    final button = find.ancestor(
      of: find.text('카카오로 계속하기'),
      matching: find.byType(ElevatedButton),
    );
    expect(tester.widget<ElevatedButton>(button).onPressed, isNull);

    await tester.tap(find.text('만 14세 이상입니다.'));
    await tester.tap(find.text('서비스 이용약관에 동의합니다.'));
    await tester.tap(find.text('AI 개인화 처리에 동의합니다.'));
    await tester.pump();

    expect(tester.widget<ElevatedButton>(button).onPressed, isNotNull);
  });

  test('birth validation rejects URL-like city input', () {
    const draft = BirthProfileDraft(
      birthDate: '2000-01-01',
      calendarType: CalendarType.solar,
      birthTimePrecision: BirthTimePrecision.unknown,
      birthCountryCode: 'KR',
      birthCity: 'https://example.com',
    );
    expect(validateBirthProfile(draft), isNotNull);
  });

  test('AppFailure preserves the safe error contract', () {
    const failure = AppFailure(
      code: AppFailureCode.validation,
      message: '입력을 확인해달라냥.',
    );
    expect(failure.toString(), contains('입력을 확인해달라냥.'));
  });

  test(
    'fake rewarded ad follows prepare, impression, reward, dismiss order',
    () async {
      final fake = FakeRewardedAdService(
        rewardedUnitId: 'ca-app-pub-3940256099942544/5224354917',
        securityMode: AdSecurityMode.fast,
      );
      await fake.preload();
      final attempt = await fake.prepareAdSession(fortuneDate: '2026-08-15');
      final result = await fake.show(attempt);
      if (result.impressionRecorded) await fake.reportAdImpression(attempt);
      if (result.rewardEarned) await fake.claimAdReward(attempt);
      if (result.dismissed) await fake.reportAdDismissed(attempt);

      expect(fake.events, [
        'preload',
        'prepare:dev-ad-attempt-1',
        'show:dev-ad-attempt-1',
        'impression:dev-ad-attempt-1',
        'claim:dev-ad-attempt-1',
        'dismissed:dev-ad-attempt-1',
      ]);
    },
  );

  test(
    'ssv strict waits for server verification before claiming reward',
    () async {
      final fake = FakeRewardedAdService(
        rewardedUnitId: 'test',
        securityMode: AdSecurityMode.ssvStrict,
      );
      final container = ProviderContainer(
        overrides: [rewardedAdServiceProvider.overrideWithValue(fake)],
      );
      addTearDown(container.dispose);

      final controller = container.read(rewardedAdControllerProvider.notifier);
      await controller.start(fortuneDate: '2026-08-15');

      expect(
        container.read(rewardedAdControllerProvider).status,
        RewardedAdFlowStatus.rewardVerifying,
      );
      expect(fake.events.where((event) => event.startsWith('claim:')), isEmpty);
    },
  );

  test('mock provider is deterministic and passes the strict schema', () async {
    const provider = MockFortuneProvider();
    const request = FortuneGenerationRequest(
      fortuneDate: '2026-08-15',
      birthProfileHash: 'test-hash',
    );

    final first = await provider.generate(request);
    final second = await provider.generate(request);
    expect(first, second);
    final payload = FortunePayload.fromJsonString(first);
    expect(payload.headline, contains('순서를'));
  });

  test('stale generation worker cannot commit after a newer claim', () {
    final fence = GenerationFence();
    fence.claim('worker-a');
    final second = fence.claim('worker-b');

    expect(fence.canCommit(epoch: 1, workerId: 'worker-a'), isFalse);
    expect(fence.canCommit(epoch: 2, workerId: 'worker-b'), isTrue);
    expect(second, '2:worker-b');
  });

  test('provider budget refuses requests after the configured cap', () {
    final budget = ProviderBudget(maxRequests: 2);
    expect(budget.reserve(), isTrue);
    expect(budget.reserve(), isTrue);
    expect(budget.reserve(), isFalse);
    expect(budget.usedRequests, 2);
  });

  test('fortune validator rejects executable markup and malformed JSON', () {
    expect(
      () => FortunePayload.fromJsonString(
        '{"headline":"<script>alert(1)</script>","overall":"ok",'
        '"lucky_color":"옥빛","lucky_number":3}',
      ),
      throwsA(isA<FortuneValidationException>()),
    );
    expect(
      () => FortunePayload.fromJsonString('{"headline":"missing"}'),
      throwsA(isA<FortuneValidationException>()),
    );
  });

  test('SSV grants once and makes duplicate transactions idempotent', () async {
    final now = DateTime.utc(2026, 8, 15, 12);
    final timestamp = now.millisecondsSinceEpoch;
    final store = InMemorySsvTokenStore(
      tokens: {'attempt-digest': 'attempt-1'},
    );
    final handler = SsvWebhookHandler(
      expectedAdUnit: 'test-unit',
      expectedRewardItem: 'fortune',
      expectedRewardAmount: 1,
      tokenStore: store,
      signatureVerifier: const FakeSsvSignatureVerifier(),
      digest: (value) => '$value-digest',
    );
    final uri = Uri.parse(
      'https://example.test/admob-ssv?ad_unit=test-unit&custom_data='
      'attempt&key_id=key-1&reward_amount=1&reward_item=fortune&'
      'signature=valid-signature&timestamp=$timestamp&transaction_id=tx-1',
    );

    expect(
      await handler.handle(
        method: 'GET',
        callbackUri: uri,
        serverNow: now,
        fortuneExpiresAt: now.add(const Duration(hours: 1)),
      ),
      SsvDisposition.granted,
    );
    expect(
      await handler.handle(
        method: 'GET',
        callbackUri: uri,
        serverNow: now,
        fortuneExpiresAt: now.add(const Duration(hours: 1)),
      ),
      SsvDisposition.duplicate,
    );
  });

  test('SSV late callback never resurrects an expired Fortune', () async {
    final now = DateTime.utc(2026, 8, 15, 12);
    final timestamp = now
        .subtract(const Duration(seconds: 30))
        .millisecondsSinceEpoch;
    final handler = SsvWebhookHandler(
      expectedAdUnit: 'test-unit',
      expectedRewardItem: 'fortune',
      expectedRewardAmount: 1,
      tokenStore: InMemorySsvTokenStore(
        tokens: {'attempt-digest': 'attempt-1'},
      ),
      signatureVerifier: const FakeSsvSignatureVerifier(),
      digest: (value) => '$value-digest',
    );
    final uri = Uri.parse(
      'https://example.test/admob-ssv?ad_unit=test-unit&custom_data=attempt&'
      'key_id=key-1&reward_amount=1&reward_item=fortune&'
      'signature=valid-signature&timestamp=$timestamp&transaction_id=tx-late',
    );

    expect(
      await handler.handle(
        method: 'GET',
        callbackUri: uri,
        serverNow: now,
        fortuneExpiresAt: now.subtract(const Duration(minutes: 1)),
      ),
      SsvDisposition.lateCompensationOnly,
    );
  });

  test('SSV rejects invalid method, reward values, and signature', () async {
    final now = DateTime.utc(2026, 8, 15, 12);
    final timestamp = now.millisecondsSinceEpoch;
    final handler = SsvWebhookHandler(
      expectedAdUnit: 'test-unit',
      expectedRewardItem: 'fortune',
      expectedRewardAmount: 1,
      tokenStore: InMemorySsvTokenStore(
        tokens: {'attempt-digest': 'attempt-1'},
      ),
      signatureVerifier: const FakeSsvSignatureVerifier(),
      digest: (value) => '$value-digest',
    );
    final invalidUri = Uri.parse(
      'https://example.test/admob-ssv?ad_unit=other&custom_data=attempt&'
      'key_id=key-1&reward_amount=9&reward_item=other&'
      'signature=invalid&timestamp=$timestamp&transaction_id=tx-invalid',
    );

    expect(
      await handler.handle(
        method: 'POST',
        callbackUri: invalidUri,
        serverNow: now,
        fortuneExpiresAt: now.add(const Duration(hours: 1)),
      ),
      SsvDisposition.rejected,
    );
    expect(
      await handler.handle(
        method: 'GET',
        callbackUri: invalidUri,
        serverNow: now,
        fortuneExpiresAt: now.add(const Duration(hours: 1)),
      ),
      SsvDisposition.rejected,
    );
  });

  test('pass reserve is capped at three active passes', () {
    final day = DateTime(2026, 8, 15);
    final ledger = FortunePassLedger(
      initialPasses: List.generate(
        3,
        (index) => FortunePass(
          id: 'pass-$index',
          status: FortunePassStatus.available,
          validFromFortuneDate: day,
          expiresAfterFortuneDate: day.add(const Duration(days: 30)),
        ),
      ),
    );

    expect(ledger.reserve(fortuneDate: day), isNotNull);
    expect(ledger.reserve(fortuneDate: day), isNotNull);
    expect(ledger.reserve(fortuneDate: day), isNotNull);
    expect(ledger.reserve(fortuneDate: day), isNull);
    expect(ledger.activeCount, 3);
  });

  test('reserved pass stays reserved until missed-day settlement', () {
    final day = DateTime(2026, 8, 15);
    final ledger = FortunePassLedger(
      initialPasses: [
        FortunePass(
          id: 'pass-1',
          status: FortunePassStatus.available,
          validFromFortuneDate: day,
          expiresAfterFortuneDate: day.add(const Duration(days: 30)),
        ),
      ],
    );
    final pass = ledger.reserve(fortuneDate: day)!;

    expect(ledger.passes.single.status, FortunePassStatus.reserved);
    expect(ledger.redeem(pass.id), isTrue);
    expect(ledger.passes.single.status, FortunePassStatus.redeemed);

    final recoveryLedger = FortunePassLedger(
      initialPasses: [
        FortunePass(
          id: 'pass-2',
          status: FortunePassStatus.reserved,
          validFromFortuneDate: day,
          expiresAfterFortuneDate: day.add(const Duration(days: 30)),
        ),
      ],
    );
    expect(recoveryLedger.restoreReservedAfterMissedFortuneDay(), 1);
    expect(recoveryLedger.passes.single.status, FortunePassStatus.available);
    expect(
      recoveryLedger.passes.single.expiresAfterFortuneDate,
      day.add(const Duration(days: 31)),
    );
  });

  test('goodwill pass never creates a fourth active pass', () {
    final day = DateTime(2026, 8, 15);
    final ledger = FortunePassLedger(
      initialPasses: List.generate(
        2,
        (index) => FortunePass(
          id: 'pass-$index',
          status: FortunePassStatus.available,
          validFromFortuneDate: day,
          expiresAfterFortuneDate: day.add(const Duration(days: 30)),
        ),
      ),
    );

    expect(ledger.issueGoodwillPass(fortuneDate: day), isTrue);
    expect(ledger.issueGoodwillPass(fortuneDate: day), isFalse);
    expect(ledger.activeCount, 3);
  });

  test('expired available passes are not reservable', () {
    final day = DateTime(2026, 8, 15);
    final ledger = FortunePassLedger(
      initialPasses: [
        FortunePass(
          id: 'old',
          status: FortunePassStatus.available,
          validFromFortuneDate: day.subtract(const Duration(days: 31)),
          expiresAfterFortuneDate: day.subtract(const Duration(days: 1)),
        ),
      ],
    );

    expect(ledger.expireBefore(day), 1);
    expect(ledger.reserve(fortuneDate: day), isNull);
    expect(ledger.passes.single.status, FortunePassStatus.expired);
  });

  testWidgets('fortune result shows required disclosure and sections', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: FortuneResultScreen()));
    await tester.pumpAndSettle();

    expect(find.text('오늘의 AI 운세'), findsOneWidget);
    expect(find.text('재물운'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.textContaining('AI 생성 콘텐츠'),
      500,
      scrollable: find.byType(Scrollable),
    );
    expect(find.textContaining('AI 생성 콘텐츠'), findsOneWidget);
    expect(find.text('행운 숫자/색상/시간/키워드'), findsNothing);
    expect(find.textContaining('숫자 7'), findsOneWidget);
  });

  test(
    'notification fake schedules, routes taps, and cancels on logout',
    () async {
      final service = FakeLocalNotificationService();
      final tomorrow = DateTime(2026, 8, 16, 9);

      expect(
        await service.scheduleFortuneReminder(
          fortuneDate: tomorrow,
          scheduledAt: tomorrow,
        ),
        isTrue,
      );
      expect(service.scheduledRequest?.route, notificationResultRoute);
      expect(
        service.routeForTap(payloadRoute: notificationResultRoute),
        notificationResultRoute,
      );
      expect(service.routeForTap(payloadRoute: '/unsafe'), '/today');
      await service.cancelAll();
      expect(service.scheduledRequest, isNull);
      expect(service.events, [
        'schedule:fortune-2026-8-16',
        'tap:/fortune/result',
        'tap:/unsafe',
        'cancel_all',
      ]);
    },
  );

  test('denied notification permission does not schedule', () async {
    final service = FakeLocalNotificationService(
      permissionStatus: NotificationPermissionStatus.denied,
    );
    expect(
      await service.scheduleFortuneReminder(
        fortuneDate: DateTime(2026, 8, 16),
        scheduledAt: DateTime(2026, 8, 16, 9),
      ),
      isFalse,
    );
    expect(service.scheduledRequest, isNull);
  });

  test(
    'consent withdrawal disables analytics and AI personalization',
    () async {
      final service = FakeAccountService();
      await service.setAnalyticsEnabled(true);
      await service.withdrawAiConsent();

      expect(service.privacyState.aiPersonalizationAllowed, isFalse);
      expect(service.privacyState.analyticsEnabled, isFalse);
      expect(service.events, ['analytics:enabled', 'ai_consent_withdrawn']);
    },
  );

  test('account deletion logs out and creates no provider payload', () async {
    final service = FakeAccountService();
    await service.deleteAccount();

    expect(service.isDeleted, isTrue);
    expect(service.isLoggedOut, isTrue);
    expect(service.events, ['delete_account']);
  });

  testWidgets('settings exposes privacy and account routes', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: SettingsScreen())),
    );
    expect(find.text('개인정보 및 동의'), findsOneWidget);
    expect(find.text('계정'), findsOneWidget);
  });

  test('telemetry is opt-in and stores only normalized safe events', () async {
    final analytics = FakeAnalyticsService();
    const event = NormalizedAnalyticsEvent(
      name: NormalizedEventName.resultViewed,
      parameters: {'surface': 'fortune_result'},
    );

    await analytics.log(event);
    expect(analytics.events, isEmpty);
    await analytics.setCollectionEnabled(true);
    await analytics.log(event);
    expect(analytics.events.single.name, NormalizedEventName.resultViewed);

    await expectLater(
      analytics.log(
        const NormalizedAnalyticsEvent(
          name: NormalizedEventName.resultViewed,
          parameters: {'fortune_payload': 'blocked'},
        ),
      ),
      throwsStateError,
    );
  });

  test('crash reporter records only safe codes after opt-in', () async {
    final crash = FakeCrashReporter();
    await crash.record(errorCode: 'AUTH_TIMEOUT', fatal: false);
    expect(crash.recordedCodes, isEmpty);
    await crash.setCollectionEnabled(true);
    await crash.record(errorCode: 'AUTH_TIMEOUT', fatal: false);
    expect(crash.recordedCodes, ['nonfatal:AUTH_TIMEOUT']);
    await expectLater(
      crash.record(errorCode: '', fatal: false),
      throwsStateError,
    );
  });

  test(
    'production config fails closed for placeholders and missing approvals',
    () {
      const config = AppConfig(
        environment: AppEnvironment.prod,
        supabaseUrl: 'https://example.supabase.co',
        supabasePublishableKey: '',
        admobRewardedUnitId: 'ca-app-pub-3940256099942544/5224354917',
      );

      expect(config.isProductionReady, isFalse);
      expect(
        config.productionConfigurationErrors,
        containsAll([
          'APP_DISPLAY_NAME_MISSING',
          'SUPABASE_URL_INVALID',
          'AUTH_REDIRECT_URL_INVALID',
          'ADMOB_PRODUCTION_UNIT_MISSING',
          'AI_PROVIDER_NOT_PROD_APPROVED',
        ]),
      );
    },
  );

  test('development config keeps Mock/Fake path available', () {
    const config = AppConfig(
      environment: AppEnvironment.dev,
      supabaseUrl: '',
      supabasePublishableKey: '',
      admobRewardedUnitId: '',
    );
    expect(config.isProductionReady, isTrue);
    expect(config.appDisplayName, '대길');
  });
}

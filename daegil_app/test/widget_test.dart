import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:daegil_app/app/app.dart';
import 'package:daegil_app/app/router.dart';
import 'package:daegil_app/app/theme/luna_theme.dart';
import 'package:daegil_app/core/config/app_config.dart';
import 'package:daegil_app/core/errors/app_failure.dart';
import 'package:daegil_app/features/ads/domain/rewarded_ad_service.dart';
import 'package:daegil_app/features/ads/data/rewarded_ad_gateway.dart';
import 'package:daegil_app/features/ads/presentation/rewarded_ad_controller.dart';
import 'package:daegil_app/features/ads/domain/ssv_verification.dart';
import 'package:daegil_app/features/auth/presentation/auth_screen.dart';
import 'package:daegil_app/features/auth/data/auth_repository.dart';
import 'package:daegil_app/features/auth/models/registration_requirement.dart';
import 'package:daegil_app/features/auth/presentation/auth_controller.dart';
import 'package:daegil_app/features/fortune/domain/fortune_generation.dart';
import 'package:daegil_app/features/fortune/domain/fortune_result.dart';
import 'package:daegil_app/features/fortune/data/fortune_repository.dart';
import 'package:daegil_app/features/fortune/presentation/fortune_result_screen.dart';
import 'package:daegil_app/features/profile/models/birth_profile.dart';
import 'package:daegil_app/features/profile/presentation/birth_profile_screen.dart';
import 'package:daegil_app/features/passes/domain/fortune_pass_ledger.dart';
import 'package:daegil_app/features/notifications/domain/local_notification_service.dart';
import 'package:daegil_app/features/settings/data/account_service.dart';
import 'package:daegil_app/features/settings/presentation/settings_screens.dart';
import 'package:daegil_app/features/telemetry/domain/telemetry_service.dart';

void main() {
  testWidgets('stalled registration exits loading and can retry', (
    tester,
  ) async {
    final repository = _ControllableAuthRepository();
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(() {
      container.dispose();
      repository.dispose();
    });
    container.listen(authControllerProvider, (_, _) {}, fireImmediately: true);
    await tester.pump();
    final controller = container.read(authControllerProvider.notifier);
    controller.setAgeAttestation(true);
    controller.setAiProcessingConsent(true);
    controller.setPrivacyUsageConsent(true);
    controller.toggleRequirement('terms-v1', true);
    repository.authenticationController.add(true);
    await tester.pump();
    expect(container.read(authControllerProvider).isLoading, isTrue);

    await tester.pump(const Duration(seconds: 16));
    expect(container.read(authControllerProvider).isLoading, isFalse);
    expect(container.read(authControllerProvider).isAuthenticated, isFalse);
    expect(
      container.read(authControllerProvider).errorMessage,
      'REGISTRATION_SYNC_FAILED',
    );

    // A late server response must not silently enter the app after timeout.
    repository.registrationCompleter.complete();
    await tester.pump();
    expect(container.read(authControllerProvider).isAuthenticated, isFalse);
    await controller.signIn(SocialProvider.google);
    expect(container.read(authControllerProvider).isAuthenticated, isTrue);
  });

  testWidgets('registration timeout after disposal does not update state', (
    tester,
  ) async {
    final repository = _ControllableAuthRepository();
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(repository.dispose);
    container.listen(authControllerProvider, (_, _) {}, fireImmediately: true);
    await tester.pump();
    final controller = container.read(authControllerProvider.notifier);
    controller.setAgeAttestation(true);
    controller.setAiProcessingConsent(true);
    controller.setPrivacyUsageConsent(true);
    controller.toggleRequirement('terms-v1', true);
    repository.authenticationController.add(true);
    await tester.pump();
    expect(container.read(authControllerProvider).isLoading, isTrue);
    container.dispose();
    await tester.pump(const Duration(seconds: 16));
    expect(tester.takeException(), isNull);
  });

  testWidgets('OAuth stream errors release the pending login gate', (
    tester,
  ) async {
    final repository = _ControllableAuthRepository();
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(() {
      container.dispose();
      repository.dispose();
    });
    container.listen(authControllerProvider, (_, _) {}, fireImmediately: true);
    await tester.pump();
    final controller = container.read(authControllerProvider.notifier);
    controller.setAgeAttestation(true);
    controller.setAiProcessingConsent(true);
    controller.setPrivacyUsageConsent(true);
    controller.toggleRequirement('terms-v1', true);
    await controller.signIn(SocialProvider.google);
    expect(container.read(authControllerProvider).isAuthPending, isTrue);
    repository.authenticationController.addError(
      const AuthException('Synthetic callback failure'),
    );
    await tester.pump();
    expect(container.read(authControllerProvider).isAuthPending, isFalse);
    expect(container.read(authControllerProvider).isLoading, isFalse);
    expect(
      container.read(authControllerProvider).errorMessage,
      'AUTH_PROVIDER_FAILED',
    );
  });

  test('repeated ad CTA cannot interrupt an in-flight preload', () async {
    final service = _ControlledPreloadAdService();
    final container = ProviderContainer(
      overrides: [rewardedAdServiceProvider.overrideWithValue(service)],
    );
    addTearDown(container.dispose);
    final controller = container.read(rewardedAdControllerProvider.notifier);
    final first = controller.start(fortuneDate: '2026-09-05');
    await controller.start(fortuneDate: '2026-09-05');
    final statusDuringLoad = container
        .read(rewardedAdControllerProvider)
        .status;
    service.preloadReady.complete();
    await first;
    expect(statusDuringLoad, RewardedAdFlowStatus.loading);
    expect(service.events.where((e) => e.startsWith('prepare:')), hasLength(1));
  });

  test('ad preload failure preserves load error without preparing', () async {
    final service = _ControlledPreloadAdService();
    final container = ProviderContainer(
      overrides: [rewardedAdServiceProvider.overrideWithValue(service)],
    );
    addTearDown(container.dispose);
    final run = container
        .read(rewardedAdControllerProvider.notifier)
        .start(fortuneDate: '2026-09-05');
    service.preloadReady.completeError(StateError('ad_load_failed'));
    await run;
    expect(service.events, isEmpty);
    expect(
      container.read(rewardedAdControllerProvider).errorCode,
      'ad_load_failed',
    );
  });
  test('server legal document payload maps to a registration requirement', () {
    final requirement = RegistrationRequirement.fromJson({
      'id': 'doc-1',
      'document_type': 'terms',
      'version': 'v1',
      'title': '서비스 이용약관',
      'public_url': 'https://example.test/terms',
      'interaction': 'acceptance_required',
      'required_for_registration': true,
      'required_for_ai': false,
      'withdrawable': false,
    });

    expect(requirement.id, 'doc-1');
    expect(requirement.interaction, LegalInteraction.acceptanceRequired);
    expect(requirement.required, isTrue);
    expect(requirement.publicUrl, 'https://example.test/terms');
  });

  test('privacy consent checks its server-driven legal document', () async {
    final repository = _ControllableAuthRepository(
      requirements: const [
        RegistrationRequirement(
          id: 'privacy-v2',
          title: '표현이 바뀐 필수 동의',
          documentType: 'privacy',
          interaction: LegalInteraction.consentRequired,
          required: true,
        ),
      ],
    );
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(() {
      container.dispose();
      repository.dispose();
    });
    container.listen(authControllerProvider, (_, _) {}, fireImmediately: true);
    await _drainMicrotasks();

    container
        .read(authControllerProvider.notifier)
        .setPrivacyUsageConsent(true);

    expect(
      container.read(authControllerProvider).acceptedDocumentIds,
      contains('privacy-v2'),
    );
  });

  test(
    'legal requirement load failure leaves a retryable auth screen',
    () async {
      final repository = _ControllableAuthRepository(
        requirementsError: const PostgrestException(message: 'offline'),
      );
      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(() {
        container.dispose();
        repository.dispose();
      });
      container.listen(
        authControllerProvider,
        (_, _) {},
        fireImmediately: true,
      );
      await _drainMicrotasks();

      final state = container.read(authControllerProvider);
      expect(state.isLoading, isFalse);
      expect(state.isAuthenticated, isFalse);
      expect(state.errorMessage, 'REGISTRATION_REQUIREMENTS_LOAD_FAILED');

      repository.requirementsError = null;
      await container.read(authControllerProvider.notifier).retryRequirements();

      final recovered = container.read(authControllerProvider);
      expect(recovered.errorMessage, isNull);
      expect(recovered.requirements, isNotEmpty);
    },
  );

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
    await tester.scrollUntilVisible(
      find.text('만 14세 이상입니다.'),
      180,
      scrollable: find.byType(Scrollable),
    );
    expect(find.text('만 14세 이상입니다.'), findsOneWidget);
  });

  testWidgets('required checks enable social login', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: AuthScreen())),
    );
    await tester.pump(const Duration(milliseconds: 100));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();
    await tester.pumpAndSettle();

    final button = find.byType(ElevatedButton, skipOffstage: false).first;
    expect(tester.widget<ElevatedButton>(button).onPressed, isNull);

    await tester.scrollUntilVisible(
      find.text('만 14세 이상입니다.'),
      180,
      scrollable: find.byType(Scrollable),
    );
    await tester.ensureVisible(find.text('만 14세 이상입니다.'));
    await tester.pump();
    await tester.tap(find.text('만 14세 이상입니다.'));
    await tester.scrollUntilVisible(
      find.text('AI 개인화 처리에 동의합니다.'),
      180,
      scrollable: find.byType(Scrollable),
    );
    await tester.ensureVisible(find.text('AI 개인화 처리에 동의합니다.'));
    await tester.pump();
    await tester.tap(find.text('AI 개인화 처리에 동의합니다.'));
    await tester.scrollUntilVisible(
      find.text('개인정보 활용에 동의합니다.'),
      180,
      scrollable: find.byType(Scrollable),
    );
    await tester.ensureVisible(find.text('개인정보 활용에 동의합니다.'));
    await tester.pump();
    await tester.tap(find.text('개인정보 활용에 동의합니다.'));
    await tester.scrollUntilVisible(
      find.text('서비스 이용약관에 동의합니다.'),
      180,
      scrollable: find.byType(Scrollable),
    );
    await tester.ensureVisible(find.text('서비스 이용약관에 동의합니다.'));
    await tester.pump();
    await tester.tap(find.text('서비스 이용약관에 동의합니다.'));
    await tester.pump();

    expect(
      tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
      isNotNull,
    );
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
    'rewarded ad gateway uses server attempt and reports every callback',
    () async {
      final backend = _RecordingRewardedAdBackend();
      final gateway = SupabaseRewardedAdGateway(
        backend: backend,
        platform: 'android',
      );

      final attempt = await gateway.prepare(fortuneDate: '2026-08-27');
      await gateway.reportImpression(attempt);
      await gateway.claimReward(attempt);
      await gateway.reportDismissed(attempt, terminalReason: 'dismissed');

      expect(attempt.id, 'server-attempt-1');
      expect(attempt.customData, 'server-opaque-token');
      expect(backend.functions, [
        'prepare-ad-session',
        'report-ad-impression',
        'claim-ad-reward',
        'report-ad-dismissed',
      ]);
      expect(backend.bodies.first['platform'], 'android');
      expect(backend.bodies.first['prepare_request_id'], isNotEmpty);
    },
  );

  test(
    'ssv strict records the client claim and waits for server unlock',
    () async {
      final fake = FakeRewardedAdService(
        rewardedUnitId: 'test',
        securityMode: AdSecurityMode.ssvStrict,
      );
      final container = ProviderContainer(
        overrides: [
          rewardedAdServiceProvider.overrideWithValue(fake),
          fortuneRepositoryProvider.overrideWithValue(
            _SequencedFortuneRepository(),
          ),
          rewardVerificationPollIntervalProvider.overrideWithValue(
            Duration.zero,
          ),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(rewardedAdControllerProvider.notifier);
      await controller.start(fortuneDate: '2026-08-15');

      expect(
        container.read(rewardedAdControllerProvider).status,
        RewardedAdFlowStatus.completed,
      );
      expect(
        fake.events.where((event) => event.startsWith('claim:')).length,
        1,
      );
    },
  );

  test('ssv strict retries a transient Supabase poll failure', () async {
    final fake = FakeRewardedAdService(
      rewardedUnitId: 'test',
      securityMode: AdSecurityMode.ssvStrict,
    );
    final container = ProviderContainer(
      overrides: [
        rewardedAdServiceProvider.overrideWithValue(fake),
        fortuneRepositoryProvider.overrideWithValue(
          _TransientFortuneRepository(),
        ),
        rewardVerificationPollIntervalProvider.overrideWithValue(Duration.zero),
      ],
    );
    addTearDown(container.dispose);

    await container
        .read(rewardedAdControllerProvider.notifier)
        .start(fortuneDate: '2026-08-15');

    expect(
      container.read(rewardedAdControllerProvider).status,
      RewardedAdFlowStatus.completed,
    );
  });

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

  test('mock fortune user-facing sentences all end in natural cat voice', () {
    final result = MockFortuneResult();
    final lines = <String>[
      result.headline,
      result.overall,
      ...result.sections.expand((section) => section.lines),
      ...result.goodToDo,
      ...result.avoid,
    ];
    expect(lines, everyElement(matches(RegExp(r'냥[.!?]?$'))));
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
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: FortuneResultScreen())),
    );
    await tester.pumpAndSettle();

    expect(find.text('오늘의 AI 운세'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('재물운'),
      300,
      scrollable: find.byType(Scrollable),
    );
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

  testWidgets('major cat-themed pages do not overflow on a 320px phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final pages = <Widget>[
      const AuthScreen(),
      const BirthProfileScreen(),
      const FortuneResultScreen(),
      const SettingsScreen(),
      const NotificationSettingsScreen(),
      const PrivacySettingsScreen(),
      const AccountSettingsScreen(),
      const AccountDeletionScreen(),
    ];
    for (final page in pages) {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(theme: buildLunaTheme(), home: page),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.takeException(),
        isNull,
        reason: page.runtimeType.toString(),
      );
    }
  });

  testWidgets('birth time controls reflow on a 320px phone', (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: buildLunaTheme(),
          home: const BirthProfileScreen(),
        ),
      ),
    );

    await tester.tap(find.text('모름'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('정확히').last);
    await tester.pumpAndSettle();

    expect(find.text('오전/오후'), findsOneWidget);
    expect(tester.takeException(), isNull);
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
    'notification preference stays non-sensitive and can be persisted',
    () async {
      final service = FakeLocalNotificationService();
      await service.persistPreference(
        enabled: true,
        notificationTime: DateTime(2026, 8, 16, 8),
      );
      expect(service.preferenceEnabled, isTrue);
      expect(service.preferenceTime?.hour, 8);
    },
  );

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
    await crash.deleteUnsentReports();
    expect(crash.deletedUnsentReports, 1);
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
        authRedirectUrl: 'http://localhost:3000',
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

  test('production config rejects an underscored OAuth URI scheme', () {
    const config = AppConfig(
      environment: AppEnvironment.prod,
      supabaseUrl: 'https://project.supabase.co',
      supabasePublishableKey: 'sb_publishable_test',
      admobRewardedUnitId: 'ca-app-pub-1234567890123456/1234567890',
      adSecurityMode: AdSecurityMode.ssvStrict,
      adSecurityModeExplicit: true,
      appDisplayNameOverride: '대길',
      androidApplicationId: 'com.daegil.app',
      iosBundleId: 'com.daegil.app',
      privacyUrl: 'https://daegil.example/privacy',
      termsUrl: 'https://daegil.example/terms',
      accountDeletionUrl: 'https://daegil.example/delete-account',
      aiProviderRegistryStatus: 'PROD_APPROVED',
      firebaseProjectId: 'daegil',
      firebaseAndroidAppId: 'android-app-id',
      firebaseIosAppId: 'ios-app-id',
      authRedirectUrl: 'com.example.daegil_app://login-callback/',
    );

    expect(
      config.productionConfigurationErrors,
      contains('AUTH_REDIRECT_URL_INVALID'),
    );
  });

  test('mobile OAuth defaults to the valid app deep-link scheme', () {
    const config = AppConfig(
      environment: AppEnvironment.dev,
      supabaseUrl: '',
      supabasePublishableKey: '',
      admobRewardedUnitId: '',
    );

    expect(config.authRedirectUrl, 'com.example.daegilapp://login-callback/');
  });

  test('development config keeps Mock/Fake path available', () {
    const config = AppConfig(
      environment: AppEnvironment.dev,
      supabaseUrl: '',
      supabasePublishableKey: '',
      admobRewardedUnitId: '',
    );
    expect(config.isProductionReady, isTrue);
    expect(config.appDisplayName, '대길');
    expect(config.shouldInitializeSupabase, isFalse);
  });

  test('development config enables staging Supabase only by explicit flag', () {
    const config = AppConfig(
      environment: AppEnvironment.dev,
      supabaseUrl: 'https://nbdgwssdikmzitebqwkq.supabase.co',
      supabasePublishableKey: 'sb_publishable_test',
      admobRewardedUnitId: '',
      enableSupabaseAuth: true,
    );
    expect(config.shouldInitializeSupabase, isTrue);
  });

  test('birth profile serializes Korean 12-hour time for the database', () {
    const profile = BirthProfileDraft(
      birthDate: '1995-08-16',
      calendarType: CalendarType.solar,
      birthTimePrecision: BirthTimePrecision.exact,
      birthTime: '오후 12:35',
      birthCountryCode: 'KR',
      birthCity: '서울',
    );

    expect(profile.toBackendPayload(), {
      'birth_date': '1995-08-16',
      'calendar_type': 'solar',
      'is_leap_month': false,
      'birth_time': '12:35:00',
      'birth_time_precision': 'exact',
      'birth_country_code': 'KR',
      'birth_city': '서울',
    });
  });

  test('unknown birth time is sent to the database as null', () {
    const profile = BirthProfileDraft(
      birthDate: '1995-08-16',
      calendarType: CalendarType.lunar,
      birthTimePrecision: BirthTimePrecision.unknown,
      birthCountryCode: 'KR',
      birthCity: '부산',
    );

    expect(profile.toBackendPayload()['birth_time'], isNull);
  });

  test('server app state restores whether a birth profile exists', () {
    final state = FortuneAppState.fromJson({
      'fortune_state': 'LOCKED',
      'birth_profile_exists': true,
    });

    expect(state.birthProfileExists, isTrue);
  });

  test(
    'authenticated OAuth session waits for registration sync before app entry',
    () async {
      final repository = _ControllableAuthRepository();
      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(() {
        container.dispose();
        repository.dispose();
      });
      container.listen(
        authControllerProvider,
        (_, _) {},
        fireImmediately: true,
      );
      await _drainMicrotasks();

      final controller = container.read(authControllerProvider.notifier);
      controller.setAgeAttestation(true);
      controller.setAiProcessingConsent(true);
      controller.setPrivacyUsageConsent(true);
      controller.toggleRequirement('terms-v1', true);

      repository.authenticationController.add(true);
      await _drainMicrotasks();

      expect(repository.completeRegistrationCalls, 1);
      expect(container.read(authControllerProvider).isAuthenticated, isFalse);

      repository.registrationCompleter.complete();
      await _drainMicrotasks();

      expect(container.read(authControllerProvider).isAuthenticated, isTrue);
    },
  );

  test(
    'completed registration restores an existing session without re-consent',
    () async {
      final repository = _ControllableAuthRepository(
        completedRegistration: true,
      );
      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(() {
        container.dispose();
        repository.dispose();
      });
      container.listen(
        authControllerProvider,
        (_, _) {},
        fireImmediately: true,
      );
      await _drainMicrotasks();

      repository.authenticationController.add(true);
      await _drainMicrotasks();

      expect(container.read(authControllerProvider).isAuthenticated, isTrue);
      expect(repository.completeRegistrationCalls, 0);
    },
  );

  test('registration sync failure keeps the user on the auth gate', () async {
    final repository = _ControllableAuthRepository(
      registrationError: StateError('REGISTRATION_SYNC_FAILED'),
    );
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(() {
      container.dispose();
      repository.dispose();
    });
    container.listen(authControllerProvider, (_, _) {}, fireImmediately: true);
    await _drainMicrotasks();

    final controller = container.read(authControllerProvider.notifier);
    controller.setAgeAttestation(true);
    controller.setAiProcessingConsent(true);
    controller.setPrivacyUsageConsent(true);
    controller.toggleRequirement('terms-v1', true);

    repository.authenticationController.add(true);
    await _drainMicrotasks();

    expect(container.read(authControllerProvider).isAuthenticated, isFalse);
    expect(
      container.read(authControllerProvider).errorMessage,
      'REGISTRATION_SYNC_FAILED',
    );
  });
}

Future<void> _drainMicrotasks() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

class _ControllableAuthRepository implements AuthRepository {
  _ControllableAuthRepository({
    this.registrationError,
    this.requirementsError,
    this.requirements = FakeAuthRepository.requirements,
    this.completedRegistration = false,
  });

  final Object? registrationError;
  Object? requirementsError;
  final List<RegistrationRequirement> requirements;
  final bool completedRegistration;
  final authenticationController = StreamController<bool>.broadcast();
  final registrationCompleter = Completer<void>();
  int completeRegistrationCalls = 0;

  @override
  Stream<bool> get authenticationChanges => authenticationController.stream;

  @override
  Future<List<RegistrationRequirement>> getRegistrationRequirements() async {
    if (requirementsError case final error?) throw error;
    return requirements;
  }

  @override
  Future<bool> hasCompletedRegistration() async => completedRegistration;

  @override
  Future<AuthSignInResult> signIn({
    required SocialProvider provider,
    required bool age14PlusAttested,
    required Set<String> acceptedDocumentIds,
  }) async {
    return const AuthSignInResult.pending();
  }

  @override
  Future<void> completeRegistration({
    required bool age14PlusAttested,
    required Set<String> displayedDocumentIds,
    required Set<String> acceptedDocumentIds,
    required bool analyticsEnabled,
  }) async {
    completeRegistrationCalls += 1;
    if (registrationError case final error?) throw error;
    await registrationCompleter.future;
  }

  void dispose() {
    authenticationController.close();
  }
}

class _ControlledPreloadAdService extends FakeRewardedAdService {
  _ControlledPreloadAdService()
    : super(rewardedUnitId: 'test', securityMode: AdSecurityMode.fast);

  final preloadReady = Completer<void>();

  @override
  Future<void> preload() async {
    await preloadReady.future;
    await super.preload();
  }

  @override
  Future<RewardedAdShowResult> show(AdAttempt attempt) async =>
      const RewardedAdShowResult(
        impressionRecorded: false,
        rewardEarned: false,
        dismissed: true,
      );
}

class _RecordingRewardedAdBackend implements RewardedAdBackend {
  final List<String> functions = [];
  final List<Map<String, dynamic>> bodies = [];

  @override
  Future<Map<String, dynamic>> invoke(
    String functionName,
    Map<String, dynamic> body,
  ) async {
    functions.add(functionName);
    bodies.add(body);
    if (functionName == 'prepare-ad-session') {
      return {
        'ad_attempt_id': 'server-attempt-1',
        'fortune_date': '2026-08-27',
        'custom_data': 'server-opaque-token',
      };
    }
    return {'status': 'recorded'};
  }
}

class _SequencedFortuneRepository implements FortuneRepository {
  int loadCount = 0;

  @override
  Future<FortuneAppState> loadAppState() async {
    loadCount += 1;
    return FortuneAppState(
      access: loadCount < 2
          ? FortuneAccessState.generating
          : FortuneAccessState.unlocked,
      result: loadCount < 2 ? null : MockFortuneResult(),
    );
  }

  @override
  Future<FortuneAppState> useFortunePass() => loadAppState();
}

class _TransientFortuneRepository implements FortuneRepository {
  int loadCount = 0;

  @override
  Future<FortuneAppState> loadAppState() async {
    loadCount += 1;
    if (loadCount == 1) {
      throw const PostgrestException(message: 'temporary');
    }
    return FortuneAppState(
      access: FortuneAccessState.unlocked,
      result: MockFortuneResult(),
    );
  }

  @override
  Future<FortuneAppState> useFortunePass() => loadAppState();
}

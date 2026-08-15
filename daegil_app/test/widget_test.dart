import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daegil_app/app/app.dart';
import 'package:daegil_app/app/router.dart';
import 'package:daegil_app/core/config/app_config.dart';
import 'package:daegil_app/core/errors/app_failure.dart';
import 'package:daegil_app/features/auth/presentation/auth_screen.dart';
import 'package:daegil_app/features/profile/models/birth_profile.dart';

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
}

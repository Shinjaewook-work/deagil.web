import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

import 'package:fortune_cat_app/app/app.dart';
import 'package:fortune_cat_app/app/router.dart';
import 'package:fortune_cat_app/core/config/app_config.dart';
import 'package:fortune_cat_app/core/errors/app_failure.dart';
import 'package:fortune_cat_app/features/auth/presentation/auth_screen.dart';

void main() {
  testWidgets('development bootstrap renders the Luna placeholder', (
    tester,
  ) async {
    const config = AppConfig(
      environment: AppEnvironment.dev,
      supabaseUrl: '',
      supabasePublishableKey: '',
      admobRewardedUnitId: '',
    );

    await tester.pumpWidget(const LunaApp(config: config));

    expect(find.text('오늘도 알려주겠다냥!'), findsOneWidget);
    expect(config.isDevelopment, isTrue);
    expect(config.hasClientConfiguration, isFalse);
  });

  testWidgets('router starts at the auth route', (tester) async {
    const config = AppConfig(
      environment: AppEnvironment.dev,
      supabaseUrl: '',
      supabasePublishableKey: '',
      admobRewardedUnitId: '',
    );
    final router = buildLunaRouter(config);
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(child: LunaApp(config: config, router: router)),
    );
    await tester.pumpAndSettle();

    expect(find.text('오늘의 흐름을 읽어볼까냥?'), findsOneWidget);
  });

  test('AppFailure keeps a user-safe error contract', () {
    const failure = AppFailure(
      code: AppFailureCode.validation,
      message: '출생정보를 확인해달라냥.',
    );

    expect(failure.code, AppFailureCode.validation);
    expect(failure.toString(), contains('출생정보를 확인해달라냥.'));
  });

  testWidgets('required age and legal checks unlock social login',
      (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: AuthScreen())),
    );
    await tester.pumpAndSettle();

    final kakaoButton = find.ancestor(
      of: find.text('카카오로 계속하기'),
      matching: find.byType(ElevatedButton),
    );
    expect(tester.widget<ElevatedButton>(kakaoButton).onPressed, isNull);

    await tester.tap(find.text('만 14세 이상입니다.'));
    await tester.tap(find.text('서비스 이용약관에 동의합니다.'));
    await tester.tap(find.text('AI 개인화 처리에 동의합니다.'));
    await tester.pump();

    expect(tester.widget<ElevatedButton>(kakaoButton).onPressed, isNotNull);
  });
}

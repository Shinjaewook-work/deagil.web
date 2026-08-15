import 'package:flutter_test/flutter_test.dart';

import 'package:fortune_cat_app/app/app.dart';
import 'package:fortune_cat_app/app/router.dart';
import 'package:fortune_cat_app/core/config/app_config.dart';
import 'package:fortune_cat_app/core/errors/app_failure.dart';

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

    await tester.pumpWidget(LunaApp(config: config, router: router));

    expect(find.text('Luna에 오신 걸 환영한다냥!'), findsOneWidget);
  });

  test('AppFailure keeps a user-safe error contract', () {
    const failure = AppFailure(
      code: AppFailureCode.validation,
      message: '출생정보를 확인해달라냥.',
    );

    expect(failure.code, AppFailureCode.validation);
    expect(failure.toString(), contains('출생정보를 확인해달라냥.'));
  });
}

import 'package:flutter_test/flutter_test.dart';

import 'package:fortune_cat_app/app/app.dart';
import 'package:fortune_cat_app/core/config/app_config.dart';

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
}

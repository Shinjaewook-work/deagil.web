import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daegil_app/app/theme/luna_theme.dart';
import 'package:daegil_app/features/auth/presentation/auth_screen.dart';
import 'package:daegil_app/features/fortune/presentation/fortune_result_screen.dart';
import 'package:daegil_app/features/profile/presentation/birth_profile_screen.dart';
import 'package:daegil_app/features/settings/presentation/settings_screens.dart';
import 'package:daegil_app/features/today/presentation/cat_home_screen.dart';
import 'package:daegil_app/features/fortune/data/fortune_repository.dart';

const outputDirectory = String.fromEnvironment('VISUAL_OUTPUT_DIR');

void main() {
  testWidgets('capture current cat-themed mobile screens', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.runAsync(() async {
      final fontBytes = await File(
        r'C:\Windows\Fonts\malgun.ttf',
      ).readAsBytes();
      await (FontLoader('Malgun')..addFont(
            Future.value(ByteData.sublistView(Uint8List.fromList(fontBytes))),
          ))
          .load();
      final iconBytes = await File(
        r'C:\tools\flutter\bin\cache\artifacts\material_fonts\MaterialIcons-Regular.otf',
      ).readAsBytes();
      await (FontLoader('MaterialIcons')..addFont(
            Future.value(ByteData.sublistView(Uint8List.fromList(iconBytes))),
          ))
          .load();
    });
    final output = Directory(outputDirectory)..createSync(recursive: true);
    final pages = <(String, Widget)>[
      ('01-auth', const AuthScreen()),
      (
        '02-cat-home',
        const _PreviewShell(selectedIndex: 0, child: CatHomeScreen()),
      ),
      ('03-birth-profile', const _PreviewShell(child: BirthProfileScreen())),
      ('04-fortune-result', const _PreviewShell(child: FortuneResultScreen())),
      ('05-settings', const _PreviewShell(child: SettingsScreen())),
      (
        '06-notification',
        const _PreviewShell(child: NotificationSettingsScreen()),
      ),
      ('07-privacy', const _PreviewShell(child: PrivacySettingsScreen())),
      ('08-account', const _PreviewShell(child: AccountSettingsScreen())),
      (
        '09-account-delete',
        const _PreviewShell(child: AccountDeletionScreen()),
      ),
    ];

    for (final (name, page) in pages) {
      final boundaryKey = GlobalKey();
      await tester.pumpWidget(
        ProviderScope(
          key: ValueKey(name),
          overrides: name == '02-cat-home'
              ? [
                  fortuneRepositoryProvider.overrideWithValue(
                    _PreviewFortuneRepository(),
                  ),
                ]
              : [],
          child: RepaintBoundary(
            key: boundaryKey,
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: _captureTheme(),
              home: page,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final context = boundaryKey.currentContext!;
      await tester.runAsync(() async {
        for (final asset in const [
          'assets/images/daegil_cat_mascot.png',
          'assets/images/daegil_cat_wave.png',
          'assets/images/daegil_cat_stretch.png',
          'assets/images/daegil_cat_yawn.png',
          'assets/images/daegil_cat_butterfly.png',
        ]) {
          await precacheImage(AssetImage(asset), context);
        }
      });
      await tester.pump();
      final boundary =
          boundaryKey.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 1);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        File(
          '${output.path}${Platform.pathSeparator}$name.png',
        ).writeAsBytesSync(bytes!.buffer.asUint8List());
      });
      if (name == '02-cat-home') {
        await tester.ensureVisible(find.text('오늘의 운세 알려달라냥!'));
        await tester.tap(find.text('오늘의 운세 알려달라냥!'));
        await tester.pumpAndSettle();
        await tester.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: 1);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          File(
            '${output.path}${Platform.pathSeparator}02b-fortune-choice.png',
          ).writeAsBytesSync(bytes!.buffer.asUint8List());
        });
        await tester.tap(find.text('다음에 볼래냥'));
        await tester.pumpAndSettle();
      }
    }
  }, skip: outputDirectory.isEmpty);
}

class _PreviewFortuneRepository extends FakeFortuneRepository {
  @override
  Future<FortuneAppState> loadAppState() async => const FortuneAppState(
    access: FortuneAccessState.locked,
    activePassCount: 3,
    availablePassCount: 3,
    canUsePass: true,
    canPrepareRewardedAd: true,
    birthProfileExists: true,
  );
}

ThemeData _captureTheme() {
  final base = buildLunaTheme();
  return base.copyWith(
    textTheme: base.textTheme.apply(fontFamily: 'Malgun'),
    primaryTextTheme: base.primaryTextTheme.apply(fontFamily: 'Malgun'),
    appBarTheme: base.appBarTheme.copyWith(
      titleTextStyle: base.appBarTheme.titleTextStyle?.copyWith(
        fontFamily: 'Malgun',
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: base.elevatedButtonTheme.style?.copyWith(
        textStyle: const WidgetStatePropertyAll(
          TextStyle(
            fontFamily: 'Malgun',
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    ),
  );
}

class _PreviewShell extends StatelessWidget {
  const _PreviewShell({required this.child, this.selectedIndex = 3});

  final Widget child;
  final int selectedIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: '운세 잡기',
          ),
          NavigationDestination(
            icon: Icon(Icons.pets_outlined),
            selectedIcon: Icon(Icons.pets_rounded),
            label: '운세',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_none_rounded),
            selectedIcon: Icon(Icons.notifications_rounded),
            label: '알림',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: '프로필',
          ),
        ],
      ),
    );
  }
}

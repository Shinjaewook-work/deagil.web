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
    });
    final output = Directory(outputDirectory)..createSync(recursive: true);
    final pages = <(String, Widget)>[
      ('01-auth', const AuthScreen()),
      ('02-birth-profile', const _PreviewShell(child: BirthProfileScreen())),
      ('03-fortune-result', const _PreviewShell(child: FortuneResultScreen())),
      ('04-settings', const _PreviewShell(child: SettingsScreen())),
      (
        '05-notification',
        const _PreviewShell(child: NotificationSettingsScreen()),
      ),
      ('06-privacy', const _PreviewShell(child: PrivacySettingsScreen())),
      ('07-account', const _PreviewShell(child: AccountSettingsScreen())),
      (
        '08-account-delete',
        const _PreviewShell(child: AccountDeletionScreen()),
      ),
    ];

    for (final (name, page) in pages) {
      final boundaryKey = GlobalKey();
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: _captureTheme(),
            home: RepaintBoundary(key: boundaryKey, child: page),
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
    }
  }, skip: outputDirectory.isEmpty);
}

ThemeData _captureTheme() {
  final base = buildLunaTheme();
  return base.copyWith(
    textTheme: base.textTheme.apply(fontFamily: 'Malgun'),
    primaryTextTheme: base.primaryTextTheme.apply(fontFamily: 'Malgun'),
  );
}

class _PreviewShell extends StatelessWidget {
  const _PreviewShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: 3,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            label: '운세 잡기',
          ),
          NavigationDestination(icon: Icon(Icons.pets_outlined), label: '운세'),
          NavigationDestination(
            icon: Icon(Icons.notifications_none),
            label: '알림',
          ),
          NavigationDestination(icon: Icon(Icons.person_outline), label: '프로필'),
        ],
      ),
    );
  }
}

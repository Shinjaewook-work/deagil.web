import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'theme/luna_theme.dart';

class DaegilAppShell extends StatelessWidget {
  const DaegilAppShell({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    return Scaffold(
      body: child,
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: LunaColors.cream,
          border: const Border(
            top: BorderSide(color: LunaColors.subtleBorder, width: 1.1),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _selectedIndex(location),
          onDestinationSelected: (index) {
            switch (index) {
              case 0:
                context.go('/today');
              case 1:
                context.go('/fortune/result');
              case 2:
                context.go('/settings/notification');
              case 3:
                context.go('/settings');
            }
          },
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
      ),
    );
  }

  int _selectedIndex(String location) {
    if (location.startsWith('/settings/notification')) return 2;
    if (location.startsWith('/settings')) return 3;
    if (location.startsWith('/fortune')) return 1;
    return 0;
  }
}

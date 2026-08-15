import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/local_notification_service.dart';

final localNotificationServiceProvider = Provider<LocalNotificationService>(
  (ref) => FakeLocalNotificationService(),
);

final notificationControllerProvider =
    NotifierProvider<NotificationController, NotificationState>(
      NotificationController.new,
    );

class NotificationState {
  const NotificationState({
    this.permission = NotificationPermissionStatus.unknown,
    this.isScheduled = false,
  });

  final NotificationPermissionStatus permission;
  final bool isScheduled;
}

class NotificationController extends Notifier<NotificationState> {
  @override
  NotificationState build() => const NotificationState();

  Future<bool> enableTomorrowReminder({required DateTime scheduledAt}) async {
    final service = ref.read(localNotificationServiceProvider);
    final permission = await service.requestPermission();
    state = NotificationState(permission: permission);
    if (permission != NotificationPermissionStatus.granted) return false;
    final fortuneDate = DateTime(
      scheduledAt.year,
      scheduledAt.month,
      scheduledAt.day,
    );
    final scheduled = await service.scheduleFortuneReminder(
      fortuneDate: fortuneDate,
      scheduledAt: scheduledAt,
    );
    state = NotificationState(permission: permission, isScheduled: scheduled);
    return scheduled;
  }

  Future<void> logout() async {
    await ref.read(localNotificationServiceProvider).cancelAll();
    state = const NotificationState();
  }

  String onNotificationTap(String? payloadRoute) => ref
      .read(localNotificationServiceProvider)
      .routeForTap(payloadRoute: payloadRoute);
}

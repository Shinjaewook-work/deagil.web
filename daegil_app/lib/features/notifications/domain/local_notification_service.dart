enum NotificationPermissionStatus { unknown, denied, granted }

class LocalNotificationRequest {
  const LocalNotificationRequest({
    required this.id,
    required this.fortuneDate,
    required this.scheduledAt,
    required this.route,
  });

  final String id;
  final DateTime fortuneDate;
  final DateTime scheduledAt;
  final String route;
}

abstract interface class LocalNotificationService {
  Future<NotificationPermissionStatus> requestPermission();

  Future<bool> scheduleFortuneReminder({
    required DateTime fortuneDate,
    required DateTime scheduledAt,
  });

  Future<void> cancelAll();

  String routeForTap({required String? payloadRoute});
}

class FakeLocalNotificationService implements LocalNotificationService {
  FakeLocalNotificationService({
    this.permissionStatus = NotificationPermissionStatus.granted,
  });

  NotificationPermissionStatus permissionStatus;
  final List<String> events = [];
  LocalNotificationRequest? scheduledRequest;

  @override
  Future<NotificationPermissionStatus> requestPermission() async {
    events.add('request_permission');
    return permissionStatus;
  }

  @override
  Future<bool> scheduleFortuneReminder({
    required DateTime fortuneDate,
    required DateTime scheduledAt,
  }) async {
    if (permissionStatus != NotificationPermissionStatus.granted) {
      events.add('schedule_denied');
      return false;
    }
    scheduledRequest = LocalNotificationRequest(
      id: 'fortune-${fortuneDate.year}-${fortuneDate.month}-${fortuneDate.day}',
      fortuneDate: fortuneDate,
      scheduledAt: scheduledAt,
      route: notificationResultRoute,
    );
    events.add('schedule:${scheduledRequest!.id}');
    return true;
  }

  @override
  Future<void> cancelAll() async {
    scheduledRequest = null;
    events.add('cancel_all');
  }

  @override
  String routeForTap({required String? payloadRoute}) {
    events.add('tap:${payloadRoute ?? 'empty'}');
    return payloadRoute == notificationResultRoute
        ? notificationResultRoute
        : '/today';
  }
}

const notificationResultRoute = '/fortune/result';

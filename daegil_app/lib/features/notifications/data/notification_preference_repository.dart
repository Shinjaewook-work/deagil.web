import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class NotificationPreferenceRepository {
  Future<void> save({required bool enabled, required DateTime time});
}

class SupabaseNotificationPreferenceRepository
    implements NotificationPreferenceRepository {
  SupabaseNotificationPreferenceRepository({required SupabaseClient client})
    : _client = client;

  final SupabaseClient _client;

  @override
  Future<void> save({required bool enabled, required DateTime time}) async {
    final value =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00';
    await _client.rpc(
      'set_my_notification_preferences',
      params: {
        'enabled_value': enabled,
        'notification_time_value': value,
        'prompt_status_value': enabled ? 'enabled' : 'declined',
      },
    );
  }
}

class FakeNotificationPreferenceRepository
    implements NotificationPreferenceRepository {
  bool enabled = false;
  DateTime time = DateTime(2026, 1, 1, 8);

  @override
  Future<void> save({required bool enabled, required DateTime time}) async {
    this.enabled = enabled;
    this.time = time;
  }
}

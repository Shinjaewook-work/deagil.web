import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/telemetry_service.dart';

final analyticsServiceProvider = Provider<AnalyticsService>(
  (ref) => FakeAnalyticsService(),
);

final crashReporterProvider = Provider<CrashReporter>(
  (ref) => FakeCrashReporter(),
);

final telemetryControllerProvider =
    NotifierProvider<TelemetryController, TelemetryState>(
      TelemetryController.new,
    );

class TelemetryState {
  const TelemetryState({
    this.analyticsEnabled = false,
    this.crashEnabled = false,
  });

  final bool analyticsEnabled;
  final bool crashEnabled;
}

class TelemetryController extends Notifier<TelemetryState> {
  @override
  TelemetryState build() => const TelemetryState();

  Future<void> setCollectionEnabled(bool enabled) async {
    await ref.read(analyticsServiceProvider).setCollectionEnabled(enabled);
    await ref.read(crashReporterProvider).setCollectionEnabled(enabled);
    state = TelemetryState(analyticsEnabled: enabled, crashEnabled: enabled);
  }

  Future<void> log(NormalizedAnalyticsEvent event) =>
      ref.read(analyticsServiceProvider).log(event);

  Future<void> recordCrash({required String errorCode, required bool fatal}) =>
      ref
          .read(crashReporterProvider)
          .record(errorCode: errorCode, fatal: fatal);
}

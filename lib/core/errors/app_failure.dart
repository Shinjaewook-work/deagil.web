enum AppFailureCode {
  unknown,
  network,
  unauthorized,
  validation,
  unavailable,
}

class AppFailure implements Exception {
  const AppFailure({
    required this.code,
    required this.message,
    this.cause,
  });

  final AppFailureCode code;
  final String message;
  final Object? cause;

  @override
  String toString() => 'AppFailure(${code.name}): $message';
}

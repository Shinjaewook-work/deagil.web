import 'dart:convert';

class FortuneGenerationRequest {
  const FortuneGenerationRequest({
    required this.fortuneDate,
    required this.birthProfileHash,
  });

  final String fortuneDate;
  final String birthProfileHash;
}

class FortunePayload {
  const FortunePayload({
    required this.headline,
    required this.overall,
    required this.luckyColor,
    required this.luckyNumber,
  });

  factory FortunePayload.fromJsonString(String raw) {
    if (raw.length > 32 * 1024) {
      throw const FortuneValidationException('response_too_large');
    }
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw const FortuneValidationException('schema_invalid');
    }
    final headline = _requiredText(decoded, 'headline');
    final overall = _requiredText(decoded, 'overall');
    final luckyColor = _requiredText(decoded, 'lucky_color');
    final luckyNumber = decoded['lucky_number'];
    if (luckyNumber is! int || luckyNumber < 0 || luckyNumber > 99) {
      throw const FortuneValidationException('schema_invalid');
    }
    final combined = '$headline $overall $luckyColor';
    if (RegExp(
      r'<\s*(script|iframe|object)\b',
      caseSensitive: false,
    ).hasMatch(combined)) {
      throw const FortuneValidationException('content_invalid');
    }
    return FortunePayload(
      headline: headline,
      overall: overall,
      luckyColor: luckyColor,
      luckyNumber: luckyNumber,
    );
  }

  final String headline;
  final String overall;
  final String luckyColor;
  final int luckyNumber;

  static String _requiredText(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! String || value.trim().isEmpty || value.length > 500) {
      throw const FortuneValidationException('schema_invalid');
    }
    return value.trim();
  }
}

class FortuneValidationException implements Exception {
  const FortuneValidationException(this.code);

  final String code;
}

abstract interface class FortuneProvider {
  String get id;

  Future<String> generate(FortuneGenerationRequest request);
}

class MockFortuneProvider implements FortuneProvider {
  const MockFortuneProvider();

  @override
  String get id => 'mock';

  @override
  Future<String> generate(FortuneGenerationRequest request) async {
    final seed = request.fortuneDate.codeUnits.fold<int>(
      request.birthProfileHash.length,
      (sum, code) => sum + code,
    );
    return jsonEncode({
      'headline': '순서를 정하면 흐름이 열린다냥.',
      'overall': '오늘은 작은 정리가 다음 행동의 힘이 되어준다냥.',
      'lucky_color': seed.isEven ? '옥빛' : '주홍빛',
      'lucky_number': seed % 10,
    });
  }
}

class ProviderRouter {
  ProviderRouter({required List<FortuneProvider> providers})
    : _providers = List.unmodifiable(providers);

  final List<FortuneProvider> _providers;

  Future<FortunePayload> generate(FortuneGenerationRequest request) async {
    if (_providers.isEmpty) {
      throw const FortuneValidationException('provider_unavailable');
    }
    Object? lastError;
    for (final provider in _providers) {
      try {
        final raw = await provider.generate(request);
        return FortunePayload.fromJsonString(raw);
      } on Object catch (error) {
        lastError = error;
      }
    }
    if (lastError is FortuneValidationException) throw lastError;
    throw const FortuneValidationException('provider_chain_exhausted');
  }
}

class GenerationFence {
  int _epoch = 0;
  String? _leaseOwner;

  int get epoch => _epoch;

  String claim(String workerId) {
    _epoch += 1;
    _leaseOwner = workerId;
    return '$_epoch:$workerId';
  }

  bool canCommit({required int epoch, required String workerId}) =>
      _epoch == epoch && _leaseOwner == workerId;
}

class ProviderBudget {
  ProviderBudget({required this.maxRequests})
    : assert(maxRequests > 0, 'maxRequests must be positive');

  final int maxRequests;
  int _usedRequests = 0;

  int get usedRequests => _usedRequests;

  bool reserve() {
    if (_usedRequests >= maxRequests) return false;
    _usedRequests += 1;
    return true;
  }
}

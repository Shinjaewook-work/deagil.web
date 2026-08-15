enum SsvDisposition { granted, duplicate, lateCompensationOnly, rejected }

class SsvCallback {
  const SsvCallback({
    required this.adUnit,
    required this.customData,
    required this.keyId,
    required this.rewardAmount,
    required this.rewardItem,
    required this.signature,
    required this.timestamp,
    required this.transactionId,
    required this.signedContent,
  });

  final String adUnit;
  final String? customData;
  final String keyId;
  final int rewardAmount;
  final String rewardItem;
  final String signature;
  final int timestamp;
  final String transactionId;
  final String signedContent;

  DateTime get rewardedAt =>
      DateTime.fromMillisecondsSinceEpoch(timestamp, isUtc: true);
}

abstract interface class SsvSignatureVerifier {
  Future<bool> verify({
    required String signedContent,
    required String signature,
    required String keyId,
  });
}

abstract interface class SsvTokenStore {
  Future<String?> findAttemptIdByDigest(String digest);

  Future<void> markTransactionSeen(String transactionId);

  Future<bool> hasSeenTransaction(String transactionId);
}

class InMemorySsvTokenStore implements SsvTokenStore {
  InMemorySsvTokenStore({Map<String, String>? tokens}) : _tokens = {...?tokens};

  final Map<String, String> _tokens;
  final Set<String> _transactions = {};

  @override
  Future<String?> findAttemptIdByDigest(String digest) async => _tokens[digest];

  @override
  Future<void> markTransactionSeen(String transactionId) async {
    _transactions.add(transactionId);
  }

  @override
  Future<bool> hasSeenTransaction(String transactionId) async =>
      _transactions.contains(transactionId);
}

class FakeSsvSignatureVerifier implements SsvSignatureVerifier {
  const FakeSsvSignatureVerifier({this.acceptedSignature = 'valid-signature'});

  final String acceptedSignature;

  @override
  Future<bool> verify({
    required String signedContent,
    required String signature,
    required String keyId,
  }) async => signature == acceptedSignature && keyId.isNotEmpty;
}

class SsvWebhookHandler {
  SsvWebhookHandler({
    required this.expectedAdUnit,
    required this.expectedRewardItem,
    required this.expectedRewardAmount,
    required this.tokenStore,
    required this.signatureVerifier,
    required this.digest,
    this.maxUriLength = 8192,
    this.maxTimestampSkew = const Duration(minutes: 10),
  });

  final String expectedAdUnit;
  final String expectedRewardItem;
  final int expectedRewardAmount;
  final SsvTokenStore tokenStore;
  final SsvSignatureVerifier signatureVerifier;
  final String Function(String decodedCustomData) digest;
  final int maxUriLength;
  final Duration maxTimestampSkew;

  Future<SsvDisposition> handle({
    required String method,
    required Uri callbackUri,
    required DateTime serverNow,
    required DateTime fortuneExpiresAt,
  }) async {
    if (method.toUpperCase() != 'GET' ||
        callbackUri.toString().length > maxUriLength) {
      return SsvDisposition.rejected;
    }
    final callback = _parse(callbackUri);
    if (callback == null || !_timestampIsSane(callback, serverNow)) {
      return SsvDisposition.rejected;
    }
    final validSignature = await signatureVerifier.verify(
      signedContent: callback.signedContent,
      signature: callback.signature,
      keyId: callback.keyId,
    );
    if (!validSignature || callback.adUnit != expectedAdUnit) {
      return SsvDisposition.rejected;
    }
    if (callback.rewardItem != expectedRewardItem ||
        callback.rewardAmount != expectedRewardAmount ||
        callback.customData == null) {
      return SsvDisposition.rejected;
    }
    final decodedCustomData = _decodeExactlyOnce(callback.customData!);
    if (decodedCustomData == null ||
        await tokenStore.findAttemptIdByDigest(digest(decodedCustomData)) ==
            null) {
      return SsvDisposition.rejected;
    }
    if (await tokenStore.hasSeenTransaction(callback.transactionId)) {
      return SsvDisposition.duplicate;
    }
    await tokenStore.markTransactionSeen(callback.transactionId);
    if (!callback.rewardedAt.isBefore(fortuneExpiresAt)) {
      return SsvDisposition.lateCompensationOnly;
    }
    return SsvDisposition.granted;
  }

  SsvCallback? _parse(Uri uri) {
    final rawQuery = uri.query;
    final values = <String, String>{};
    for (final pair in rawQuery.split('&')) {
      final separator = pair.indexOf('=');
      if (separator <= 0) continue;
      final key = Uri.decodeQueryComponent(pair.substring(0, separator));
      final value = pair.substring(separator + 1);
      values[key] = Uri.decodeQueryComponent(value);
    }
    final required = [
      'ad_unit',
      'key_id',
      'reward_amount',
      'reward_item',
      'signature',
      'timestamp',
      'transaction_id',
    ];
    if (required.any((key) => values[key] == null || values[key]!.isEmpty)) {
      return null;
    }
    final amount = int.tryParse(values['reward_amount']!);
    final timestamp = int.tryParse(values['timestamp']!);
    if (amount == null || timestamp == null || timestamp <= 0) return null;
    final signatureIndex = rawQuery.indexOf('&signature=');
    final keyIndex = rawQuery.indexOf('&key_id=');
    final signedEnd = [signatureIndex, keyIndex]
        .where((index) => index >= 0)
        .fold<int>(rawQuery.length, (end, index) => end < index ? end : index);
    return SsvCallback(
      adUnit: values['ad_unit']!,
      customData: values['custom_data'],
      keyId: values['key_id']!,
      rewardAmount: amount,
      rewardItem: values['reward_item']!,
      signature: values['signature']!,
      timestamp: timestamp,
      transactionId: values['transaction_id']!,
      signedContent: rawQuery.substring(0, signedEnd),
    );
  }

  bool _timestampIsSane(SsvCallback callback, DateTime serverNow) {
    final delta = callback.rewardedAt.difference(serverNow.toUtc()).abs();
    return delta <= maxTimestampSkew;
  }

  String? _decodeExactlyOnce(String value) {
    try {
      return Uri.decodeQueryComponent(value);
    } on FormatException {
      return null;
    }
  }
}

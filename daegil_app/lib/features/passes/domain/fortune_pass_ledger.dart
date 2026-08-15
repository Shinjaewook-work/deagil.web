enum FortunePassStatus { available, reserved, redeemed, expired }

class FortunePass {
  const FortunePass({
    required this.id,
    required this.status,
    required this.validFromFortuneDate,
    required this.expiresAfterFortuneDate,
  });

  final String id;
  final FortunePassStatus status;
  final DateTime validFromFortuneDate;
  final DateTime expiresAfterFortuneDate;

  FortunePass copyWith({
    FortunePassStatus? status,
    DateTime? expiresAfterFortuneDate,
  }) {
    return FortunePass(
      id: id,
      status: status ?? this.status,
      validFromFortuneDate: validFromFortuneDate,
      expiresAfterFortuneDate:
          expiresAfterFortuneDate ?? this.expiresAfterFortuneDate,
    );
  }
}

class FortunePassLedger {
  FortunePassLedger({List<FortunePass> initialPasses = const []})
    : _passes = [...initialPasses] {
    if (activeCount > maxActivePasses) {
      throw ArgumentError.value(
        initialPasses,
        'initialPasses',
        'available + reserved must be <= $maxActivePasses',
      );
    }
  }

  static const maxActivePasses = 3;
  final List<FortunePass> _passes;
  int _nextId = 1;

  List<FortunePass> get passes => List.unmodifiable(_passes);

  int get activeCount =>
      _passes.where((pass) => _isActiveStatus(pass.status)).length;

  int get availableCount => _count(FortunePassStatus.available);

  int get reservedCount => _count(FortunePassStatus.reserved);

  FortunePass? reserve({required DateTime fortuneDate}) {
    final index = _passes.indexWhere(
      (pass) =>
          pass.status == FortunePassStatus.available &&
          !_isAfter(fortuneDate, pass.expiresAfterFortuneDate),
    );
    if (index < 0) return null;
    final reserved = _passes[index].copyWith(
      status: FortunePassStatus.reserved,
    );
    _passes[index] = reserved;
    return reserved;
  }

  bool redeem(String passId) {
    final index = _passes.indexWhere(
      (pass) => pass.id == passId && pass.status == FortunePassStatus.reserved,
    );
    if (index < 0) return false;
    _passes[index] = _passes[index].copyWith(
      status: FortunePassStatus.redeemed,
    );
    return true;
  }

  int restoreReservedAfterMissedFortuneDay() {
    var restored = 0;
    for (var index = 0; index < _passes.length; index++) {
      final pass = _passes[index];
      if (pass.status != FortunePassStatus.reserved) continue;
      _passes[index] = pass.copyWith(
        status: FortunePassStatus.available,
        expiresAfterFortuneDate: _addFortuneDay(pass.expiresAfterFortuneDate),
      );
      restored += 1;
    }
    return restored;
  }

  bool issueGoodwillPass({required DateTime fortuneDate}) {
    if (activeCount >= maxActivePasses) return false;
    _passes.add(
      FortunePass(
        id: 'goodwill-${_nextId++}',
        status: FortunePassStatus.available,
        validFromFortuneDate: fortuneDate,
        expiresAfterFortuneDate: _addFortuneDays(fortuneDate, 30),
      ),
    );
    return true;
  }

  int expireBefore(DateTime fortuneDate) {
    var expired = 0;
    for (var index = 0; index < _passes.length; index++) {
      final pass = _passes[index];
      if (pass.status == FortunePassStatus.available &&
          _isAfter(fortuneDate, pass.expiresAfterFortuneDate)) {
        _passes[index] = pass.copyWith(status: FortunePassStatus.expired);
        expired += 1;
      }
    }
    return expired;
  }

  int _count(FortunePassStatus status) =>
      _passes.where((pass) => pass.status == status).length;

  static bool _isActiveStatus(FortunePassStatus status) =>
      status == FortunePassStatus.available ||
      status == FortunePassStatus.reserved;

  static bool _isAfter(DateTime left, DateTime right) => DateTime.utc(
    left.year,
    left.month,
    left.day,
  ).isAfter(DateTime.utc(right.year, right.month, right.day));

  static DateTime _addFortuneDay(DateTime date) => _addFortuneDays(date, 1);

  static DateTime _addFortuneDays(DateTime date, int days) =>
      DateTime(date.year, date.month, date.day).add(Duration(days: days));
}

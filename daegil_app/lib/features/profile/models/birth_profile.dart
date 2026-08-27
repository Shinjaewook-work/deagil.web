enum CalendarType { solar, lunar }

enum BirthTimePrecision { exact, approximate, unknown }

class BirthProfileDraft {
  const BirthProfileDraft({
    required this.birthDate,
    required this.calendarType,
    required this.birthTimePrecision,
    required this.birthCountryCode,
    required this.birthCity,
    this.nickname,
    this.birthTime,
    this.isLeapMonth = false,
  });

  final String? nickname;
  final String birthDate;
  final CalendarType calendarType;
  final bool isLeapMonth;
  final String? birthTime;
  final BirthTimePrecision birthTimePrecision;
  final String birthCountryCode;
  final String birthCity;

  Map<String, dynamic> toBackendPayload() => {
    'birth_date': birthDate.trim(),
    'calendar_type': calendarType.name,
    'is_leap_month': isLeapMonth,
    'birth_time': _databaseBirthTime(),
    'birth_time_precision': birthTimePrecision.name,
    'birth_country_code': birthCountryCode.trim().toUpperCase(),
    'birth_city': birthCity.trim(),
  };

  String? _databaseBirthTime() {
    if (birthTimePrecision == BirthTimePrecision.unknown) return null;
    final value = birthTime?.trim();
    final match = RegExp(
      r'^(오전|오후)\s+(\d{1,2}):(\d{2})$',
    ).firstMatch(value ?? '');
    if (match == null) throw StateError('INVALID_BIRTH_TIME');
    final period = match.group(1)!;
    var hour = int.parse(match.group(2)!);
    final minute = int.parse(match.group(3)!);
    if (hour < 1 || hour > 12 || minute < 0 || minute > 59) {
      throw StateError('INVALID_BIRTH_TIME');
    }
    if (period == '오전') {
      if (hour == 12) hour = 0;
    } else if (hour != 12) {
      hour += 12;
    }
    return '${hour.toString().padLeft(2, '0')}:'
        '${minute.toString().padLeft(2, '0')}:00';
  }
}

String? validateBirthProfile(BirthProfileDraft draft) {
  final city = draft.birthCity.trim();
  if (draft.birthDate.trim().isEmpty) return '생년월일을 입력해달라냥.';
  if (draft.calendarType == CalendarType.solar && draft.isLeapMonth) {
    return '양력에서는 윤달을 선택할 수 없다냥.';
  }
  if (draft.birthTimePrecision != BirthTimePrecision.unknown &&
      (draft.birthTime == null || draft.birthTime!.trim().isEmpty)) {
    return '출생시간을 입력해달라냥.';
  }
  if (city.isEmpty ||
      city.length > 80 ||
      city.contains(RegExp(r'[\r\n]')) ||
      city.contains(RegExp(r'https?://|www\.', caseSensitive: false))) {
    return '출생도시는 시·군 정도로 입력해달라냥.';
  }
  return null;
}

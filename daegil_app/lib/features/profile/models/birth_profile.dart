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

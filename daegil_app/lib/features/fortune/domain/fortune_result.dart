class FortuneResultSection {
  const FortuneResultSection({required this.title, required this.lines});

  final String title;
  final List<String> lines;
}

class FortuneResult {
  const FortuneResult({
    required this.fortuneDate,
    required this.headline,
    required this.overallRating,
    required this.overall,
    required this.sections,
    required this.goodToDo,
    required this.avoid,
    required this.luckyNumber,
    required this.luckyColor,
    required this.luckyTime,
    required this.luckyKeyword,
  });

  final DateTime fortuneDate;
  final String headline;
  final int overallRating;
  final String overall;
  final List<FortuneResultSection> sections;
  final List<String> goodToDo;
  final List<String> avoid;
  final int luckyNumber;
  final String luckyColor;
  final String luckyTime;
  final String luckyKeyword;

  factory FortuneResult.fromBackendJson(Map<String, dynamic> json) {
    List<String> lines(String key) => (json[key] as List? ?? const [])
        .whereType<String>()
        .toList(growable: false);
    final ratings = Map<String, dynamic>.from(
      json['ratings'] as Map? ?? const {},
    );
    final lucky = Map<String, dynamic>.from(json['lucky'] as Map? ?? const {});
    final date =
        DateTime.tryParse(json['fortune_date'] as String? ?? '') ??
        DateTime.now();
    return FortuneResult(
      fortuneDate: date,
      headline: json['headline'] as String? ?? '오늘의 흐름을 준비했어요.',
      overallRating: (ratings['overall'] as num?)?.toInt() ?? 3,
      overall: lines('overall').join(' '),
      sections: [
        FortuneResultSection(title: '재물운', lines: lines('money')),
        FortuneResultSection(title: '연애운', lines: lines('love')),
        FortuneResultSection(title: '직장·학업운', lines: lines('career')),
        FortuneResultSection(title: '인간관계운', lines: lines('relationship')),
        FortuneResultSection(title: '컨디션운', lines: lines('condition')),
      ],
      goodToDo: lines('recommended_actions'),
      avoid: lines('avoid_actions'),
      luckyNumber: (lucky['number'] as num?)?.toInt() ?? 1,
      luckyColor: lucky['color'] as String? ?? '',
      luckyTime: lucky['time'] as String? ?? '',
      luckyKeyword: lucky['keyword'] as String? ?? '',
    );
  }

  String get formattedDate =>
      '${fortuneDate.year}.${fortuneDate.month.toString().padLeft(2, '0')}.${fortuneDate.day.toString().padLeft(2, '0')}';
}

class MockFortuneResult extends FortuneResult {
  MockFortuneResult()
    : super(
        fortuneDate: DateTime(2026, 8, 15),
        headline: '천천히 정리하면 흐름이 열린다냥.',
        overallRating: 4,
        overall: '오늘은 속도보다 순서를 정하는 일이 마음의 여백을 만들어준다냥.',
        sections: const [
          FortuneResultSection(
            title: '재물운',
            lines: [
              '작은 지출을 한 번 더 살펴보면 좋은 흐름을 지킬 수 있다냥.',
              '미뤄둔 정리가 실속으로 이어진다냥.',
              '충동적인 결정은 오후로 미뤄보라냥.',
            ],
          ),
          FortuneResultSection(
            title: '연애운',
            lines: [
              '상대의 말을 끝까지 들으면 따뜻한 대화가 시작된다냥.',
              '짧은 안부가 좋은 인상을 남긴다냥.',
              '서운함은 결론보다 맥락부터 나눠보라냥.',
            ],
          ),
          FortuneResultSection(
            title: '직장·학업운',
            lines: [
              '가장 작은 할 일부터 시작하면 집중이 살아난다냥.',
              '오전에 정리한 순서가 오후를 가볍게 해준다냥.',
              '완벽함보다 제출 가능한 초안을 먼저 만들라냥.',
            ],
          ),
          FortuneResultSection(
            title: '인간관계운',
            lines: [
              '오늘은 조언보다 공감이 먼저 닿는다냥.',
              '고마운 마음을 짧게 표현해보라냥.',
              '대답을 서두르지 않으면 오해를 줄일 수 있다냥.',
            ],
          ),
          FortuneResultSection(
            title: '컨디션운',
            lines: [
              '물을 챙겨 마시고 한 번쯤 어깨를 풀어보라냥.',
              '짧은 산책이 생각을 환기해준다냥.',
              '늦은 밤에는 화면 밝기를 낮춰보라냥.',
            ],
          ),
        ],
        goodToDo: const [
          '할 일을 세 가지로 줄여보라냥.',
          '고마운 사람에게 안부를 보내보라냥.',
          '책상 위 한 곳을 정리해보라냥.',
        ],
        avoid: const [
          '급한 결론은 내리지 말라냥.',
          '준비 없이 큰 약속을 잡지 말라냥.',
          '피곤함을 참은 채 계속 밀어붙이지 말라냥.',
        ],
        luckyNumber: 7,
        luckyColor: '옥빛',
        luckyTime: '오후 3시',
        luckyKeyword: '정돈',
      );
}

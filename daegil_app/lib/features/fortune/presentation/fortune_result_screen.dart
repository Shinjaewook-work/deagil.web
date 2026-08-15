import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/fortune_repository.dart';
import '../domain/fortune_result.dart';

class FortuneResultScreen extends ConsumerWidget {
  const FortuneResultScreen({this.result, super.key});

  final FortuneResult? result;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (result != null) return _ResultBody(result: result!);
    final state = ref.watch(fortuneAppStateProvider);
    return state.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) =>
          Scaffold(body: Center(child: Text('운세를 불러오지 못했어요.'))),
      data: (appState) {
        if (appState.result == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('오늘의 AI 운세')),
            body: Center(child: Text(_lockedMessage(appState.access))),
          );
        }
        return _ResultBody(result: appState.result!);
      },
    );
  }

  String _lockedMessage(FortuneAccessState access) => switch (access) {
    FortuneAccessState.generating => '운세를 만들고 있어요냥.',
    FortuneAccessState.recoveryPending => '잠시 후 운세 생성을 다시 시도해요냥.',
    FortuneAccessState.failed => '운세 생성에 실패했어요. 다시 시도해 주세요.',
    _ => '광고 또는 패스로 오늘의 운세를 열어보세요냥.',
  };
}

class _ResultBody extends StatelessWidget {
  const _ResultBody({required this.result});
  final FortuneResult result;

  @override
  Widget build(BuildContext context) {
    final displayedResult = result;
    return Scaffold(
      appBar: AppBar(title: const Text('오늘의 AI 운세')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(
            displayedResult.formattedDate,
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(height: 8),
          Text(
            displayedResult.headline,
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: 20),
          _RatingCard(result: displayedResult),
          const SizedBox(height: 12),
          _ResultSection(title: '오늘의 흐름', lines: [displayedResult.overall]),
          for (final section in displayedResult.sections)
            _ResultSection(title: section.title, lines: section.lines),
          _ResultSection(title: '오늘 하면 좋다냥', lines: displayedResult.goodToDo),
          _ResultSection(title: '오늘은 피하라냥', lines: displayedResult.avoid),
          _LuckyCard(result: displayedResult),
          const SizedBox(height: 16),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'AI 생성 콘텐츠\n\n'
                '이 운세는 생성형 AI가 출생정보와 오늘 날짜를 바탕으로 생성했습니다.\n\n'
                '오락·문화 목적으로 제공되며 의료·법률·재무 등 전문적인 판단을 대신하지 않습니다.',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RatingCard extends StatelessWidget {
  const _RatingCard({required this.result});

  final FortuneResult result;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const Icon(Icons.wb_sunny_outlined, size: 36),
            const SizedBox(width: 16),
            Text(
              '${result.overallRating} / 5',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(width: 8),
            const Text('오늘의 흐름'),
          ],
        ),
      ),
    );
  }
}

class _ResultSection extends StatelessWidget {
  const _ResultSection({required this.title, required this.lines});

  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final line in lines)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('• $line'),
              ),
          ],
        ),
      ),
    );
  }
}

class _LuckyCard extends StatelessWidget {
  const _LuckyCard({required this.result});

  final FortuneResult result;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            Chip(label: Text('숫자 ${result.luckyNumber}')),
            Chip(label: Text('색상 ${result.luckyColor}')),
            Chip(label: Text('시간 ${result.luckyTime}')),
            Chip(label: Text('키워드 ${result.luckyKeyword}')),
          ],
        ),
      ),
    );
  }
}

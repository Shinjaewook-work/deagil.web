import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/fortune_repository.dart';
import '../domain/fortune_result.dart';
import '../../../app/theme/luna_theme.dart';
import '../../../shared/widgets/luna_page_frame.dart';
import '../../../shared/widgets/cat_page_banner.dart';

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
      body: LunaPageFrame(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            CatPageBanner(
              assetName: 'assets/images/daegil_cat_yawn.png',
              title: displayedResult.headline,
              message: '${displayedResult.formattedDate}\n오늘의 운세를 잡아왔다냥.',
              imageHeight: 170,
            ),
            const SizedBox(height: 20),
            _RatingCard(result: displayedResult),
            const SizedBox(height: 12),
            _ResultSection(
              title: '오늘의 흐름',
              lines: [displayedResult.overall],
              icon: Icons.wb_sunny_rounded,
              color: LunaColors.butter,
            ),
            for (final section in displayedResult.sections)
              _ResultSection(
                title: section.title,
                lines: section.lines,
                icon: _sectionIcon(section.title),
                color: _sectionColor(section.title),
              ),
            _ResultSection(
              title: '오늘 하면 좋다냥',
              lines: displayedResult.goodToDo,
              icon: Icons.favorite_rounded,
              color: LunaColors.jadeSoft,
            ),
            _ResultSection(
              title: '오늘은 피하라냥',
              lines: displayedResult.avoid,
              icon: Icons.shield_moon_rounded,
              color: LunaColors.blush,
            ),
            _LuckyCard(result: displayedResult),
            const SizedBox(height: 16),
            const Card(
              color: LunaColors.cream,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline_rounded, color: LunaColors.seal),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'AI 생성 콘텐츠\n\n'
                        '이 운세는 생성형 AI가 출생정보와 오늘 날짜를 바탕으로 생성했습니다.\n\n'
                        '오락·문화 목적으로 제공되며 의료·법률·재무 등 전문적인 판단을 대신하지 않습니다.',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static IconData _sectionIcon(String title) => switch (title) {
    '재물운' => Icons.savings_rounded,
    '연애운' => Icons.favorite_rounded,
    '직장·학업운' => Icons.auto_stories_rounded,
    '인간관계운' => Icons.people_alt_rounded,
    '컨디션운' => Icons.spa_rounded,
    _ => Icons.pets_rounded,
  };

  static Color _sectionColor(String title) => switch (title) {
    '재물운' => LunaColors.butter,
    '연애운' => LunaColors.blush,
    '직장·학업운' => LunaColors.peachSoft,
    '인간관계운' => LunaColors.jadeSoft,
    '컨디션운' => LunaColors.peach,
    _ => LunaColors.peachSoft,
  };
}

class _RatingCard extends StatelessWidget {
  const _RatingCard({required this.result});

  final FortuneResult result;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: LunaColors.cream,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: LunaColors.blush,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: LunaColors.subtleBorder),
              ),
              child: const Icon(
                Icons.pets_rounded,
                color: LunaColors.seal,
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '오늘의 기분 온도',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${result.overallRating} / 5',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 4,
                    children: [
                      for (var index = 1; index <= 5; index++)
                        Icon(
                          Icons.pets_rounded,
                          size: 18,
                          color: index <= result.overallRating
                              ? LunaColors.seal
                              : LunaColors.disabled,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultSection extends StatelessWidget {
  const _ResultSection({
    required this.title,
    required this.lines,
    required this.icon,
    required this.color,
  });

  final String title;
  final List<String> lines;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: LunaColors.cream,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: LunaColors.subtleBorder),
                  ),
                  child: Icon(icon, size: 20, color: LunaColors.seal),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    softWrap: true,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (final line in lines)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: LunaColors.seal,
                          shape: BoxShape.circle,
                        ),
                        child: SizedBox(width: 5, height: 5),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(line, softWrap: true)),
                  ],
                ),
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
      color: LunaColors.cream,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.auto_awesome_rounded, color: LunaColors.seal),
                SizedBox(width: 8),
                Text(
                  '행운 주머니',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(label: Text('숫자 ${result.luckyNumber}')),
                Chip(label: Text('색상 ${result.luckyColor}')),
                Chip(label: Text('시간 ${result.luckyTime}')),
                Chip(label: Text('키워드 ${result.luckyKeyword}')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/birth_profile.dart';
import 'birth_profile_controller.dart';
import '../../../app/theme/luna_theme.dart';
import '../../../shared/widgets/cat_page_banner.dart';
import '../../../shared/widgets/luna_card.dart';
import '../../../shared/widgets/luna_page_frame.dart';
import '../../../shared/widgets/luna_primary_button.dart';

class BirthProfileScreen extends ConsumerStatefulWidget {
  const BirthProfileScreen({super.key});

  @override
  ConsumerState<BirthProfileScreen> createState() => _BirthProfileScreenState();
}

class _BirthProfileScreenState extends ConsumerState<BirthProfileScreen> {
  final _dateController = TextEditingController();
  final _cityController = TextEditingController();
  CalendarType _calendarType = CalendarType.solar;
  BirthTimePrecision _precision = BirthTimePrecision.unknown;
  String _period = '오전';
  int _hour = 12;
  int _minute = 0;
  String? _error;
  bool _isSaving = false;

  @override
  void dispose() {
    _dateController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_isSaving) return;
    setState(() {
      _isSaving = true;
      _error = null;
    });
    final draft = BirthProfileDraft(
      birthDate: _dateController.text,
      calendarType: _calendarType,
      birthTimePrecision: _precision,
      birthTime: _precision == BirthTimePrecision.unknown
          ? null
          : '$_period ${_hour.toString().padLeft(2, '0')}:${_minute.toString().padLeft(2, '0')}',
      birthCountryCode: 'KR',
      birthCity: _cityController.text,
    );
    try {
      await ref.read(birthProfileProvider.notifier).save(draft);
      if (mounted) context.go('/today');
    } on StateError catch (error) {
      if (mounted) setState(() => _error = error.message);
    } on Object {
      if (mounted) {
        setState(() => _error = '출생정보를 저장하지 못했다냥. 잠시 후 다시 시도해달라냥.');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('출생정보')),
      body: LunaPageFrame(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          children: [
            const CatPageBanner(
              assetName: 'assets/images/daegil_cat_butterfly.png',
              title: '운세를 읽을 준비를 하자냥.',
              message: '기억나는 만큼만 차근차근 알려달라냥.',
              imageHeight: 138,
            ),
            const SizedBox(height: 18),
            LunaCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: LunaColors.butter,
                        child: Icon(
                          Icons.cake_rounded,
                          size: 19,
                          color: LunaColors.seal,
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '나의 출생정보',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _dateController,
                    decoration: const InputDecoration(
                      labelText: '생년월일 (YYYY-MM-DD)',
                      prefixIcon: Icon(Icons.calendar_month_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<CalendarType>(
                    initialValue: _calendarType,
                    decoration: const InputDecoration(
                      labelText: '달력',
                      prefixIcon: Icon(Icons.event_note_rounded),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: CalendarType.solar,
                        child: Text('양력'),
                      ),
                      DropdownMenuItem(
                        value: CalendarType.lunar,
                        child: Text('음력'),
                      ),
                    ],
                    onChanged: (value) => setState(
                      () => _calendarType = value ?? CalendarType.solar,
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<BirthTimePrecision>(
                    initialValue: _precision,
                    decoration: const InputDecoration(
                      labelText: '출생시간',
                      prefixIcon: Icon(Icons.schedule_rounded),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: BirthTimePrecision.unknown,
                        child: Text('모름'),
                      ),
                      DropdownMenuItem(
                        value: BirthTimePrecision.exact,
                        child: Text('정확히'),
                      ),
                      DropdownMenuItem(
                        value: BirthTimePrecision.approximate,
                        child: Text('대략'),
                      ),
                    ],
                    onChanged: (value) => setState(
                      () => _precision = value ?? BirthTimePrecision.unknown,
                    ),
                  ),
                  if (_precision != BirthTimePrecision.unknown) ...[
                    const SizedBox(height: 12),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final periodField = DropdownButtonFormField<String>(
                          initialValue: _period,
                          decoration: const InputDecoration(labelText: '오전/오후'),
                          items: const [
                            DropdownMenuItem(value: '오전', child: Text('오전')),
                            DropdownMenuItem(value: '오후', child: Text('오후')),
                          ],
                          onChanged: (value) =>
                              setState(() => _period = value ?? '오전'),
                        );
                        final hourField = DropdownButtonFormField<int>(
                          initialValue: _hour,
                          decoration: const InputDecoration(labelText: '시'),
                          items: [
                            for (var hour = 1; hour <= 12; hour++)
                              DropdownMenuItem(
                                value: hour,
                                child: Text('$hour시'),
                              ),
                          ],
                          onChanged: (value) =>
                              setState(() => _hour = value ?? 12),
                        );
                        final minuteField = DropdownButtonFormField<int>(
                          initialValue: _minute,
                          decoration: const InputDecoration(labelText: '분'),
                          items: [
                            for (var minute = 0; minute < 60; minute += 5)
                              DropdownMenuItem(
                                value: minute,
                                child: Text(
                                  '${minute.toString().padLeft(2, '0')}분',
                                ),
                              ),
                          ],
                          onChanged: (value) =>
                              setState(() => _minute = value ?? 0),
                        );
                        if (constraints.maxWidth >= 330) {
                          return Row(
                            children: [
                              Expanded(child: periodField),
                              const SizedBox(width: 8),
                              Expanded(child: hourField),
                              const SizedBox(width: 8),
                              Expanded(child: minuteField),
                            ],
                          );
                        }
                        if (constraints.maxWidth < 280) {
                          return Column(
                            children: [
                              periodField,
                              const SizedBox(height: 8),
                              hourField,
                              const SizedBox(height: 8),
                              minuteField,
                            ],
                          );
                        }
                        return Column(
                          children: [
                            periodField,
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(child: hourField),
                                const SizedBox(width: 8),
                                Expanded(child: minuteField),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextField(
                    controller: _cityController,
                    decoration: const InputDecoration(
                      labelText: '출생도시',
                      prefixIcon: Icon(Icons.location_city_rounded),
                    ),
                  ),
                ],
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            const SizedBox(height: 24),
            LunaPrimaryButton(
              onPressed: _isSaving ? null : _save,
              label: _isSaving ? '저장하는 중이다냥…' : '저장하고 알려달라냥!',
              icon: Icons.favorite_rounded,
            ),
          ],
        ),
      ),
    );
  }
}

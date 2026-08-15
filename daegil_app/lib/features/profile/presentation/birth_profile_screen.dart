import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/birth_profile.dart';
import 'birth_profile_controller.dart';

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
  String? _error;

  @override
  void dispose() {
    _dateController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final draft = BirthProfileDraft(
      birthDate: _dateController.text,
      calendarType: _calendarType,
      birthTimePrecision: _precision,
      birthCountryCode: 'KR',
      birthCity: _cityController.text,
    );
    try {
      await ref.read(birthProfileProvider.notifier).save(draft);
      if (mounted) context.go('/today');
    } on StateError catch (error) {
      setState(() => _error = error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('출생정보')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            '운세를 읽을 준비를 하자냥.',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _dateController,
            decoration: const InputDecoration(labelText: '생년월일 (YYYY-MM-DD)'),
          ),
          DropdownButtonFormField<CalendarType>(
            initialValue: _calendarType,
            decoration: const InputDecoration(labelText: '달력'),
            items: const [
              DropdownMenuItem(value: CalendarType.solar, child: Text('양력')),
              DropdownMenuItem(value: CalendarType.lunar, child: Text('음력')),
            ],
            onChanged: (value) =>
                setState(() => _calendarType = value ?? CalendarType.solar),
          ),
          DropdownButtonFormField<BirthTimePrecision>(
            initialValue: _precision,
            decoration: const InputDecoration(labelText: '출생시간'),
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
          TextField(
            controller: _cityController,
            decoration: const InputDecoration(labelText: '출생도시'),
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
          ElevatedButton(onPressed: _save, child: const Text('저장하고 알려달라냥!')),
        ],
      ),
    );
  }
}

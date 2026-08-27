import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/birth_profile_repository.dart';
import '../models/birth_profile.dart';

final birthProfileRepositoryProvider = Provider<BirthProfileRepository>((ref) {
  return const FakeBirthProfileRepository();
});

final birthProfileProvider =
    NotifierProvider<BirthProfileController, BirthProfileDraft?>(
      BirthProfileController.new,
    );

class BirthProfileController extends Notifier<BirthProfileDraft?> {
  @override
  BirthProfileDraft? build() => null;

  Future<void> save(BirthProfileDraft draft) async {
    final error = validateBirthProfile(draft);
    if (error != null) throw StateError(error);
    await ref.read(birthProfileRepositoryProvider).save(draft);
    state = draft;
  }
}

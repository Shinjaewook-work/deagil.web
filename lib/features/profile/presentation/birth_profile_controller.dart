import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/birth_profile.dart';

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
    // Phase 2 RPC boundary: production implementation calls upsert_my_birth_profile.
    state = draft;
  }
}

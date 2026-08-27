import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/birth_profile.dart';

abstract interface class BirthProfileRepository {
  Future<void> save(BirthProfileDraft draft);
}

class FakeBirthProfileRepository implements BirthProfileRepository {
  const FakeBirthProfileRepository();

  @override
  Future<void> save(BirthProfileDraft draft) async {}
}

class SupabaseBirthProfileRepository implements BirthProfileRepository {
  SupabaseBirthProfileRepository({required SupabaseClient client})
    : _client = client;

  final SupabaseClient _client;

  @override
  Future<void> save(BirthProfileDraft draft) async {
    await _client.rpc(
      'upsert_my_birth_profile',
      params: {'payload': draft.toBackendPayload()},
    );
  }
}

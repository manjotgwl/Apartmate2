import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/profile.dart';

// Reads and updates profiles in Supabase.
class ProfileRepository {
  final SupabaseClient _client;

  ProfileRepository(this._client);

  // Loads the profile for this ID. Supabase throws if the query does not
  // return exactly one row.
  Future<Profile> getProfile(String id) async {
    final data = await _client.from('profiles').select().eq('id', id).single();

    return Profile.fromJson(data);
  }

  // Saves the display name and bio for the matching profile ID.
  Future<void> updateProfile(Profile profile) async {
    await _client
        .from('profiles')
        .update({
          'display_name': profile.displayName,
          'bio': profile.bio,
          'phone_number': profile.phoneNumber,
        })
        .eq('id', profile.id);
  }
}

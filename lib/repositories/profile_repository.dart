import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/profile.dart';

// Reads and updates the profiles table in Supabase
class ProfileRepository {
  final SupabaseClient _client;

  ProfileRepository(this._client);

  // Loads the profile for passed in id, makes sure only one row is returned
  Future<Profile> getProfile(String id) async {
    final data = await _client.from('profiles').select().eq('id', id).single();

    // since returned info is in json, we must parse that into an actual
    // profile object
    return Profile.fromJson(data);
  }

  // Saves the display name, bio, and phone number for the matching profile
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

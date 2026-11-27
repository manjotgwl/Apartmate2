import 'package:supabase_flutter/supabase_flutter.dart';

// Provides access to supabase's session management
class AuthRepository {
  final SupabaseClient _client;

  AuthRepository(this._client);

  // The user in the current session, null when signed out
  User? get currentUser => _client.auth.currentUser;

  // returns events such as sign in, and sign out
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  // Registers a user
  Future<AuthResponse> signUp(
    String email,
    String password,
    String phoneNumber,
  ) {
    return _client.auth.signUp(
      email: email,
      password: password,
      data: {'phone_number': phoneNumber},  // NOTE: here we don't use the phone field because that'll
                                            // also require the user to verify their phone number.
                                            // For now, the phone number is strictly only for item lending
                                            // and facilitation of communication, so we wont verify it,
                                            // at least for now.
    );
  }

  // Starts a session using the users email and password
  Future<AuthResponse> signIn(String email, String password) {
    return _client.auth.signInWithPassword(email: email, password: password);
  }

  // Ends the current session
  Future<void> signOut() {
    return _client.auth.signOut();
  }
}

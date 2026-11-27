import 'package:supabase_flutter/supabase_flutter.dart';

// Provides access to Supabase account and session operations.
class AuthRepository {
  final SupabaseClient _client;

  AuthRepository(this._client);

  // The user in the current session, or `null` when signed out.
  User? get currentUser => _client.auth.currentUser;

  // Emits session events such as sign-in, token refresh, and sign-out.
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  // Registers a user. If confirmation is required, the response can have no
  // session until the user confirms their account.
  Future<AuthResponse> signUp(
    String email,
    String password,
    String phoneNumber,
  ) {
    return _client.auth.signUp(
      email: email,
      password: password,
      phone: phoneNumber,
    );
  }

  // Starts a session using the user's email and password.
  Future<AuthResponse> signIn(String email, String password) {
    return _client.auth.signInWithPassword(email: email, password: password);
  }

  // Ends the current session.
  Future<void> signOut() {
    return _client.auth.signOut();
  }
}

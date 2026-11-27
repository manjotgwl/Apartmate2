import 'package:flutter/material.dart';
import 'package:opendoor/repositories/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'login_view.dart';

class AuthGate extends StatelessWidget {
  final AuthRepository authRepository;

  const AuthGate({super.key, required this.authRepository});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: authRepository.authStateChanges,
      builder: (context, snapshot) {
        final user = authRepository.currentUser;

        if (user == null) {
          return LoginView(authRepository: authRepository);
        }

        return const Scaffold(body: Center(child: Text('Home Screen')));
      },
    );
  }
}

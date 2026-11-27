import 'package:flutter/material.dart';
import 'package:opendoor/repositories/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'login_view.dart';

import 'package:provider/provider.dart';

import '../providers/profile_provider.dart';
import '../repositories/profile_repository.dart';
import 'profile_view.dart';

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

        // key makes sure different users get different providers
        return ChangeNotifierProvider(
          key: ValueKey(user.id),
          create: (_) =>

              // create provider and instantly call loadProfile on it
              ProfileProvider(ProfileRepository(Supabase.instance.client))
                ..loadProfile(user.id),
          child: ProfileView(authRepository: authRepository),
        );
      },
    );
  }
}

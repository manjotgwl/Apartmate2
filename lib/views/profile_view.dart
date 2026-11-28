import 'package:flutter/material.dart';
import 'package:opendoor/models/profile.dart';
import 'package:opendoor/providers/profile_provider.dart';
import 'package:provider/provider.dart';

import '../repositories/auth_repository.dart';

class ProfileView extends StatefulWidget {
  final AuthRepository authRepository;

  const ProfileView({super.key, required this.authRepository});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final _formKey =
      GlobalKey<FormState>(); // so we can set up validators for each text field

  final _displayNameController = TextEditingController();
  final _bioController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _fieldsInitialized = false;

  @override
  void dispose() {
    super.dispose();
    _displayNameController.dispose();
    _bioController.dispose();
    _phoneController.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final provider = context
        .read<
          ProfileProvider
        >(); // access provider w/o subscribing to notifications
    // because we are just reading some info rq
    final Profile? currentProfile = provider.profile;

    // return early is profile is still loading or no profile was fetched
    if (provider.isLoading || currentProfile == null) {
      return;
    }

    final Profile updatedProfile = Profile(
      id: currentProfile.id,
      displayName: _displayNameController.text.trim(),
      bio: _bioController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
    );

    await provider.updateProfile(updatedProfile);

    if (!mounted) {
      return;
    }

    // If no error message, then show success
    if (provider.errorMessage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile udpated successfully!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProfileProvider>(); // access provider and subscribe to notifications (rebuild view if profile changes)
    final profile = provider.profile;

    // If profile not fetched, show blank profile page and a button to retry loading the profile
    if (profile == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Profile')),
        body: Center(
          child: provider.isLoading
              ? const CircularProgressIndicator()
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(provider.errorMessage ?? 'Profile not available'),
                    TextButton(
                      onPressed: () {
                        final user = widget.authRepository.currentUser;

                        if (user != null) {
                          provider.loadProfile(user.id);
                        }
                      },
                      child: const Text('Retry'),
                    ),
                    TextButton(
                      onPressed: () async {
                        await widget.authRepository.signOut();
                      },
                      child: const Text('Sign out'),
                    ),
                  ],
                ),
        ),
      );
    }

    // Fill out the text controllers with the signed in profile's data once
    // when this view is accessed
    if (!_fieldsInitialized) {
      _displayNameController.text = profile.displayName;
      _bioController.text = profile.bio;
      _phoneController.text = profile.phoneNumber ?? '';

      _fieldsInitialized = true;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            tooltip: 'Sign Out',
            icon: const Icon(Icons.logout),
            onPressed: provider.isLoading
                ? null
                : () async {
                    await widget.authRepository.signOut();
                  },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 48,
                  child: Icon(Icons.person, size: 48),
                ),

                const SizedBox(height: 24),

                TextFormField(
                  controller: _displayNameController,
                  enabled: !provider.isLoading,
                  decoration: const InputDecoration(
                    labelText: 'Display Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter your display name';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _bioController,
                  enabled: !provider.isLoading,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Bio',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _phoneController,
                  enabled: !provider.isLoading,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter your phone number';
                    }

                    if (!RegExp(r'^\+[1-9]\d{1,14}$').hasMatch(value.trim())) {
                      return 'Enter a phone number with country code';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 16),

                if (provider.errorMessage != null)
                  Text(
                    provider.errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),

                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: provider.isLoading ? null : _saveProfile,
                    child: provider.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save Profile'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

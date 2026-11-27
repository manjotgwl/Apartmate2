import 'package:flutter/material.dart';
import 'package:opendoor/models/profile.dart';
import 'package:opendoor/repositories/profile_repository.dart';

// Profile Provider that basically proxies the Methods found in 
// profile repository. This is necessary to keep the app functioning 
// locally as well.
class ProfileProvider extends ChangeNotifier {
  final ProfileRepository _repository;  // the profile table in remote db

  Profile? _profile;  // current profile, local
  bool _isLoading = false;  // flag used to show that profile is info is loading or not
  String? _errorMessage;

  ProfileProvider(this._repository);

  // getters
  Profile? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // tries to update the local profile to a profile with matching id from the remote db
  Future<void> loadProfile(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners(); // must notify listeners here because we updated isLoading

    try {
      _profile = await _repository.getProfile(id);
    } catch (e) {
      _errorMessage = 'Failed to load profile ($id)';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update the profile stored both locally and in the db.
  Future<void> updateProfile(Profile profile) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.updateProfile(profile);
      _profile = profile;
    } catch (e) {
      _errorMessage = 'Failed to update profile';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

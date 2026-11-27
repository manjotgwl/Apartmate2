import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:opendoor/repositories/location_repository.dart';

/// Where the app is in getting the phone's position. Views use this to
/// pick which banner to show and turn it into translated text.
enum LocationStatus {
  /// Checking permission or waiting for a position.
  checking,

  /// A position is known, so distances can be shown.
  available,

  /// Location services are turned off on the phone.
  serviceOff,

  /// The user said no to location access but can be asked again.
  denied,

  /// The user said no permanently, so only Settings can change it.
  deniedForever,

  /// Getting a position failed or took too long.
  failed,
}

/// Holds the phone's GPS position so screens can show distances. The
/// position stays on the phone: nothing here uploads it. Phone access
/// goes through [LocationRepository] so tests can pass in a fake one.
class LocationProvider extends ChangeNotifier {
  final LocationRepository _repository;
  double? _latitude;
  double? _longitude;
  LocationStatus _status = LocationStatus.checking;
  StreamSubscription<Coordinates>? _updates;
  bool _disposed = false;

  /// Creates the provider and starts getting the phone's position.
  ///
  /// params:
  /// - repository: talks to the phone's GPS and place lookup
  LocationProvider(this._repository) {
    refresh();
  }

  /// The phone's latitude, or null when location isn't available.
  double? get latitude => _latitude;

  /// The phone's longitude, or null when location isn't available.
  double? get longitude => _longitude;

  /// Where the app is in getting the phone's position.
  LocationStatus get status => _status;

  /// Whether a position is known.
  bool get hasLocation => _latitude != null && _longitude != null;

  /// Latitude rounded to about 0.7 miles, for any feature that shares a
  /// position with other users, such as people near you on Home.
  double? get approximateLatitude => _approximate(_latitude);

  /// Longitude rounded to about 0.7 miles, for any feature that shares a
  /// position with other users, such as people near you on Home.
  double? get approximateLongitude => _approximate(_longitude);

  /// Checks that location is on and allowed, asks for permission if it
  /// hasn't been asked yet, then gets the position and keeps it updated
  /// as the phone moves. Call it again after the user returns from
  /// Settings.
  Future<void> refresh() async {
    _status = LocationStatus.checking;
    _notify();
    try {
      if (!await _repository.isServiceEnabled()) {
        _clear(LocationStatus.serviceOff);
        return;
      }
      var access = await _repository.checkAccess();
      if (access == LocationAccess.denied) {
        access = await _repository.requestAccess();
      }
      if (access == LocationAccess.deniedForever) {
        _clear(LocationStatus.deniedForever);
        return;
      }
      if (access == LocationAccess.denied) {
        _clear(LocationStatus.denied);
        return;
      }
      _setPosition(await _repository.currentPosition());
      _status = LocationStatus.available;
      _listenForUpdates();
    } catch (_) {
      _status = LocationStatus.failed;
    } finally {
      _notify();
    }
  }

  /// Opens the phone's location settings when location is off, or this
  /// app's settings when access was denied.
  Future<void> openSettings() async {
    if (_status == LocationStatus.serviceOff) {
      await _repository.openLocationSettings();
    } else {
      await _repository.openAppSettings();
    }
  }

  /// Finds coordinates for a place the host typed. If the lookup finds
  /// nothing or fails, it falls back to the phone's own position.
  ///
  /// params:
  /// - placeName: what the host typed in the Where field
  /// returns: the coordinates, or null if neither the lookup nor the
  /// phone's position is available
  Future<Coordinates?> coordinatesFor(String placeName) async {
    Coordinates? found;
    try {
      found = await _repository.lookUpPlace(placeName.trim());
    } catch (_) {
      found = null;
    }
    if (found != null) {
      return found;
    }
    final latitude = _latitude;
    final longitude = _longitude;
    if (latitude == null || longitude == null) {
      return null;
    }
    return (latitude: latitude, longitude: longitude);
  }

  @override
  void dispose() {
    _disposed = true;
    _updates?.cancel();
    super.dispose();
  }

  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  void _listenForUpdates() {
    _updates?.cancel();
    _updates = _repository.positionUpdates().listen(
      (position) {
        _setPosition(position);
        _status = LocationStatus.available;
        _notify();
      },
      onError: (Object _) {
        _clear(LocationStatus.failed);
        _notify();
      },
    );
  }

  void _setPosition(Coordinates position) {
    _latitude = position.latitude;
    _longitude = position.longitude;
  }

  void _clear(LocationStatus status) {
    _updates?.cancel();
    _updates = null;
    _latitude = null;
    _longitude = null;
    _status = status;
  }

  double? _approximate(double? value) {
    if (value == null) {
      return null;
    }
    return (value * 100).round() / 100;
  }
}
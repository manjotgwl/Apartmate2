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

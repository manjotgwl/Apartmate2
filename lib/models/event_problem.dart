/// Things that can go wrong with an event action. Views turn these into
/// translated messages, so the provider never holds user-facing text.
enum EventProblem {
  /// Events couldn't be loaded, usually because the phone is offline.
  loadFailed,

  /// The event already has as many people going as its cap allows.
  full,

  /// The event has already ended.
  ended,

  /// The host tried to leave or change their RSVP to their own event.
  hostCannotLeave,

  /// Someone other than the host tried to edit or cancel the event.
  notHost,

  /// The form has at least one issue from [EventProvider.validate].
  invalidForm,

  /// The event was saved, but adding it to Google Calendar failed.
  calendarFailed,

  /// A change couldn't be saved, usually because the phone is offline.
  saveFailed,
}

/// Problems with the create or edit event form, shown next to each field.
enum EventFormIssue {
  /// The title is empty.
  titleMissing,

  /// The title is longer than [EventProvider.titleMaxLength].
  titleTooLong,

  /// The place is empty.
  placeMissing,

  /// The details are longer than [EventProvider.detailsMaxLength].
  detailsTooLong,

  /// The start time isn't in the future.
  startInPast,

  /// The start time is past the last day in the week strip.
  startTooFar,

  /// The end time isn't after the start time.
  endNotAfterStart,

  /// The cap is outside [EventProvider.minPeople] to
  /// [EventProvider.maxPeopleLimit].
  maxPeopleOutOfRange,

  /// The cap is lower than the number of people already going.
  maxPeopleBelowGoing,
}

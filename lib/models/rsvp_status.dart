/// How a user answered an event. Not having an answer means they
/// haven't joined, so there's no "none" value.
enum RsvpStatus {
  /// Takes one of the event's spots.
  going,

  /// Interested but not committed, so it never takes a spot.
  maybe;

  /// Reads a status saved in Supabase.
  ///
  /// params:
  /// - name: the saved text, such as 'going'
  /// returns: the matching status, or null if the text doesn't match one
  static RsvpStatus? fromName(String? name) => RsvpStatus.values.asNameMap()[name];
}
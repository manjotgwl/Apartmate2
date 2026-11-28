/// The kind of casual event a host can create.
enum EventType {
  /// Grabbing coffee.
  coffee,

  /// Studying together.
  study,

  /// Getting food.
  food,

  /// A quick errand, like a store run.
  errand,

  /// Anything else.
  other;

  /// Reads a type saved in Supabase.
  ///
  /// params:
  /// - name: the saved text, such as 'coffee'
  /// returns: the matching type, or [EventType.other] if it doesn't match
  static EventType fromName(String? name) =>
      EventType.values.asNameMap()[name] ?? EventType.other;
}

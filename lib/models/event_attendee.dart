import 'package:opendoor/models/rsvp_status.dart';

/// One person who said going or maybe to an event, shown in the
/// details page's Going and Maybe lists.
class EventAttendee {
  /// The attendee's user id.
  final String userId;

  /// The attendee's display name from their profile, or empty if it
  /// couldn't be loaded.
  final String displayName;

  /// Whether they're going or maybe.
  final RsvpStatus status;

  /// Creates an attendee from all of its fields.
  const EventAttendee({
    required this.userId,
    required this.displayName,
    required this.status,
  });

  /// Creates an attendee from an event_attendees row that also fetched
  /// the person's profile, using select('user_id, status,
  /// profiles(display_name)').
  ///
  /// params:
  /// - json: the row Supabase returned
  /// returns: the attendee
  factory EventAttendee.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;
    return EventAttendee(
      userId: json['user_id'] as String,
      displayName: profile?['display_name'] as String? ?? '',
      status: RsvpStatus.fromName(json['status'] as String?) ?? RsvpStatus.maybe,
    );
  }

  /// Turns the attendee into the fields saved in event_attendees.
  ///
  /// returns: the user id and status
  Map<String, dynamic> toJson() {
    return {'user_id': userId, 'status': status.name};
  }
}
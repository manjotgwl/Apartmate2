import 'package:opendoor/models/event_type.dart';

/// One casual event that people nearby can join. Events can't be
/// changed in place: an edit makes a new copy with [copyWith] that keeps
/// the same [id] and [hostId].
class Event {
  /// The event's id from Supabase, or empty before it's saved.
  final String id;

  /// The id of the user who created the event.
  final String hostId;

  /// The event title, at most 60 characters.
  final String title;

  /// What kind of event it is.
  final EventType type;

  /// When the event starts, in the phone's time zone.
  final DateTime startsAt;

  /// When the event ends, in the phone's time zone. Always after
  /// [startsAt].
  final DateTime endsAt;

  /// Where the event is, as the host typed it.
  final String placeName;

  /// The place's latitude, used for distances.
  final double latitude;

  /// The place's longitude, used for distances.
  final double longitude;

  /// Optional extra information, at most 300 characters.
  final String details;

  /// The most people who can say going, counting the host.
  final int maxPeople;

  /// How many people are going, counting the host. Supabase keeps this
  /// up to date.
  final int goingCount;

  /// Creates an event from all of its fields.
  const Event({
    required this.id,
    required this.hostId,
    required this.title,
    required this.type,
    required this.startsAt,
    required this.endsAt,
    required this.placeName,
    required this.latitude,
    required this.longitude,
    required this.details,
    required this.maxPeople,
    required this.goingCount,
  });

  /// Creates an event from a row in the events table.
  ///
  /// params:
  /// - json: the row Supabase returned
  /// returns: the event, with times converted to the phone's time zone
  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'] as String,
      hostId: json['host_id'] as String,
      title: json['title'] as String,
      type: EventType.fromName(json['type'] as String?),
      startsAt: DateTime.parse(json['starts_at'] as String).toLocal(),
      endsAt: DateTime.parse(json['ends_at'] as String).toLocal(),
      placeName: json['place_name'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      details: json['details'] as String? ?? '',
      maxPeople: (json['max_people'] as num).toInt(),
      goingCount: (json['going_count'] as num?)?.toInt() ?? 0,
    );
  }

  /// Turns the event into the fields the app saves. Leaves out [id] and
  /// [goingCount] because Supabase manages those.
  ///
  /// returns: the fields to insert or update, with times in UTC
  Map<String, dynamic> toJson() {
    return {
      'host_id': hostId,
      'title': title,
      'type': type.name,
      'starts_at': startsAt.toUtc().toIso8601String(),
      'ends_at': endsAt.toUtc().toIso8601String(),
      'place_name': placeName,
      'latitude': latitude,
      'longitude': longitude,
      'details': details,
      'max_people': maxPeople,
    };
  }

  /// Makes an edited copy that keeps the same [id] and [hostId].
  ///
  /// params: any field to change; fields left out keep their value
  /// returns: the edited copy
  Event copyWith({
    String? title,
    EventType? type,
    DateTime? startsAt,
    DateTime? endsAt,
    String? placeName,
    double? latitude,
    double? longitude,
    String? details,
    int? maxPeople,
    int? goingCount,
  }) {
    return Event(
      id: id,
      hostId: hostId,
      title: title ?? this.title,
      type: type ?? this.type,
      startsAt: startsAt ?? this.startsAt,
      endsAt: endsAt ?? this.endsAt,
      placeName: placeName ?? this.placeName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      details: details ?? this.details,
      maxPeople: maxPeople ?? this.maxPeople,
      goingCount: goingCount ?? this.goingCount,
    );
  }
}
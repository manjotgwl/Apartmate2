import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:opendoor/models/event.dart';
import 'package:opendoor/models/event_attendee.dart';
import 'package:opendoor/models/event_form_issue.dart';
import 'package:opendoor/models/event_problem.dart';
import 'package:opendoor/models/event_type.dart';
import 'package:opendoor/models/rsvp_status.dart';
import 'package:opendoor/providers/location_provider.dart';
import 'package:opendoor/repositories/calendar_repository.dart';
import 'package:opendoor/repositories/event_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds events near the user and applies every rule for showing,
/// sorting, joining, creating, and editing them. Supabase access goes
/// through [EventRepository] so tests can pass in a fake one.
class EventProvider extends ChangeNotifier {
  /// Number of days the week strip covers, starting today.
  static const int daysShown = 14;

  /// Most events shown in the upcoming row on Home.
  static const int upcomingLimit = 10;

  /// Longest allowed event title.
  static const int titleMaxLength = 60;

  /// Longest allowed event details.
  static const int detailsMaxLength = 300;

  /// Smallest allowed cap, counting the host.
  static const int minPeople = 2;

  /// Largest allowed cap.
  static const int maxPeopleLimit = 20;

  /// Cap used when the host doesn't pick one.
  static const int defaultMaxPeople = 6;

  /// How long an event lasts when the host doesn't pick an end time.
  static const Duration defaultLength = Duration(hours: 1);

  /// Distance filter choices in miles. Null means anywhere.
  static const List<double?> radiusOptions = [0.5, 1.0, 2.0, 5.0, null];

  /// Distance filter used until the user picks one.
  static const double defaultRadiusMiles = 1.0;

  static const String _radiusKey = 'event_radius_miles';
  static const double _anywhere = -1.0;
  static const double _earthRadiusMiles = 3958.8;

  final EventRepository _repository;
  final CalendarRepository _calendar;
  final LocationProvider _location;
  final SharedPreferences _preferences;
  final DateTime Function() _now;

  /// The signed-in user's id.
  final String currentUserId;

  List<Event> _events = [];
  Map<String, RsvpStatus> _myRsvps = {};
  final Map<String, List<EventAttendee>> _attendees = {};
  double? _radiusMiles;
  bool _isLoading = false;
  EventProblem? _loadProblem;
  StreamSubscription<void>? _changes;
  bool _disposed = false;

  /// Creates the provider, reads the saved distance filter, loads events,
  /// and listens for changes other people make.
  ///
  /// params:
  /// - repository: reads and writes events in Supabase
  /// - calendar: adds events to Google Calendar
  /// - location: supplies the phone's position for distances
  /// - preferences: stores the distance filter on the phone
  /// - currentUserId: the signed-in user's id
  /// - now: the clock, replaceable in tests
  EventProvider({
    required EventRepository repository,
    required CalendarRepository calendar,
    required LocationProvider location,
    required SharedPreferences preferences,
    required this.currentUserId,
    DateTime Function()? now,
  }) : _repository = repository,
       _calendar = calendar,
       _location = location,
       _preferences = preferences,
       _now = now ?? DateTime.now {
    _radiusMiles = _readRadius();
    _location.addListener(_onLocationChanged);
    _changes = _repository.watchChanges().listen((_) => load());
    load();
  }

  /// Whether events are loading.
  bool get isLoading => _isLoading;

  /// Why the last load failed, or null if it worked.
  EventProblem? get loadProblem => _loadProblem;

  /// The distance filter in miles, or null for anywhere.
  double? get radiusMiles => _radiusMiles;

  /// Whether the phone's position is known, so distances can be shown.
  bool get hasLocation =>
      _location.latitude != null && _location.longitude != null;

  /// The days in the week strip, starting today.
  List<DateTime> get days {
    final today = _startOfToday();
    return List.generate(
      daysShown,
      (i) => DateTime(today.year, today.month, today.day + i),
    );
  }

  /// Visible events for the Home row across every day, soonest first.
  List<Event> get upcomingEvents =>
      _sorted(_events.where(_isVisible)).take(upcomingLimit).toList();

  /// Visible events that start on a given day, soonest first.
  ///
  /// params:
  /// - day: the day picked in the week strip
  /// returns: the events to list for that day
  List<Event> eventsOn(DateTime day) {
    return _sorted(
      _events.where(
        (event) => _isVisible(event) && _isSameDay(event.startsAt, day),
      ),
    );
  }

  /// The user's RSVP to an event.
  ///
  /// params:
  /// - event: the event to check
  /// returns: going or maybe, or null if the user hasn't joined
  RsvpStatus? myRsvp(Event event) => _myRsvps[event.id];

  /// Whether the user is hosting an event.
  bool isHost(Event event) => event.hostId == currentUserId;

  /// Whether an event has no spots left for "going".
  bool isFull(Event event) => event.goingCount >= event.maxPeople;

  /// Whether an event's end time has passed.
  bool hasEnded(Event event) => !_now().isBefore(event.endsAt);

  /// Whether an event has started and not yet ended.
  bool isHappeningNow(Event event) {
    final now = _now();
    return !now.isBefore(event.startsAt) && now.isBefore(event.endsAt);
  }

  /// Distance from the phone to an event, worked out on the phone.
  ///
  /// params:
  /// - event: the event to measure to
  /// returns: miles rounded to 0.1, or null when location is off
  double? distanceMilesTo(Event event) {
    final latitude = _location.latitude;
    final longitude = _location.longitude;
    if (latitude == null || longitude == null) {
      return null;
    }
    final miles = _milesBetween(
      latitude,
      longitude,
      event.latitude,
      event.longitude,
    );
    return (miles * 10).round() / 10;
  }

  /// Everyone who said going or maybe to an event, once
  /// [loadAttendees] has run for it.
  ///
  /// params:
  /// - eventId: the event's id
  /// returns: the attendees, or an empty list if not loaded yet
  List<EventAttendee> attendeesFor(String eventId) =>
      List.unmodifiable(_attendees[eventId] ?? const <EventAttendee>[]);

  /// Loads events in the week strip's window and the user's RSVPs.
  Future<void> load() async {
    _isLoading = true;
    _loadProblem = null;
    _notify();
    try {
      final from = _startOfToday();
      final to = DateTime(from.year, from.month, from.day + daysShown);
      _events = await _repository.fetchEvents(from: from, to: to);
      _myRsvps = Map.of(await _repository.fetchMyRsvps(currentUserId));
    } catch (_) {
      _loadProblem = EventProblem.loadFailed;
    } finally {
      _isLoading = false;
      _notify();
    }
  }

  /// Loads who's going and who's maybe for an event's details page.
  ///
  /// params:
  /// - eventId: the event's id
  /// returns: null if it worked, or [EventProblem.loadFailed]
  Future<EventProblem?> loadAttendees(String eventId) async {
    try {
      _attendees[eventId] = await _repository.fetchAttendees(eventId);
      _notify();
      return null;
    } catch (_) {
      return EventProblem.loadFailed;
    }
  }

  /// Changes the distance filter and saves it on the phone.
  ///
  /// params:
  /// - miles: one of [radiusOptions], or null for anywhere
  Future<void> setRadius(double? miles) async {
    _radiusMiles = miles;
    _notify();
    await _preferences.setDouble(_radiusKey, miles ?? _anywhere);
  }

  /// Sets the user's RSVP to going or maybe. Only going takes a spot,
  /// so maybe works even when the event is full.
  ///
  /// params:
  /// - event: the event to join
  /// - status: going or maybe
  /// returns: null if it worked, or the problem that stopped it
  Future<EventProblem?> rsvp(Event event, RsvpStatus status) async {
    if (hasEnded(event)) {
      return EventProblem.ended;
    }
    if (isHost(event)) {
      return EventProblem.hostCannotLeave;
    }
    final alreadyGoing = _myRsvps[event.id] == RsvpStatus.going;
    if (status == RsvpStatus.going && !alreadyGoing && isFull(event)) {
      return EventProblem.full;
    }
    try {
      await _repository.setRsvp(eventId: event.id, status: status);
    } on EventFullException {
      await load();
      return EventProblem.full;
    } catch (_) {
      return EventProblem.saveFailed;
    }
    _myRsvps[event.id] = status;
    await _refreshAfterChange(event.id);
    return null;
  }

  /// Removes the user's RSVP. Hosts can't leave their own event.
  ///
  /// params:
  /// - event: the event to leave
  /// returns: null if it worked, or the problem that stopped it
  Future<EventProblem?> leave(Event event) async {
    if (isHost(event)) {
      return EventProblem.hostCannotLeave;
    }
    if (hasEnded(event)) {
      return EventProblem.ended;
    }
    try {
      await _repository.removeRsvp(event.id);
    } catch (_) {
      return EventProblem.saveFailed;
    }
    _myRsvps.remove(event.id);
    await _refreshAfterChange(event.id);
    return null;
  }

  /// Checks a create or edit form against the event rules.
  ///
  /// params:
  /// - title: the event title
  /// - startsAt: when the event starts
  /// - endsAt: when the event ends
  /// - placeName: where the event is
  /// - details: optional extra information
  /// - maxPeople: the cap, counting the host
  /// - existing: the event being edited, or null when creating
  /// returns: every issue found, empty when the form is valid
  Set<EventFormIssue> validate({
    required String title,
    required DateTime startsAt,
    required DateTime endsAt,
    required String placeName,
    required String details,
    required int maxPeople,
    Event? existing,
  }) {
    final issues = <EventFormIssue>{};
    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) {
      issues.add(EventFormIssue.titleMissing);
    }
    if (trimmedTitle.length > titleMaxLength) {
      issues.add(EventFormIssue.titleTooLong);
    }
    if (placeName.trim().isEmpty) {
      issues.add(EventFormIssue.placeMissing);
    }
    if (details.trim().length > detailsMaxLength) {
      issues.add(EventFormIssue.detailsTooLong);
    }
    final startUnchanged =
        existing != null && existing.startsAt.isAtSameMomentAs(startsAt);
    if (!startUnchanged && !startsAt.isAfter(_now())) {
      issues.add(EventFormIssue.startInPast);
    }
    final today = _startOfToday();
    final windowEnd = DateTime(today.year, today.month, today.day + daysShown);
    if (!startsAt.isBefore(windowEnd)) {
      issues.add(EventFormIssue.startTooFar);
    }
    if (!endsAt.isAfter(startsAt)) {
      issues.add(EventFormIssue.endNotAfterStart);
    }
    if (maxPeople < minPeople || maxPeople > maxPeopleLimit) {
      issues.add(EventFormIssue.maxPeopleOutOfRange);
    }
    if (existing != null && maxPeople < existing.goingCount) {
      issues.add(EventFormIssue.maxPeopleBelowGoing);
    }
    return issues;
  }

  /// Creates an event hosted by the user, who counts as going. Adding it
  /// to Google Calendar is a separate step that can't undo the event.
  ///
  /// params:
  /// - title: the event title
  /// - type: coffee, study, food, errand, or other
  /// - startsAt: when the event starts
  /// - endsAt: when it ends, or null for one hour after the start
  /// - placeName: where the event is
  /// - latitude: the place's latitude
  /// - longitude: the place's longitude
  /// - details: optional extra information
  /// - maxPeople: the cap, counting the host
  /// - addToCalendar: whether to also add it to Google Calendar
  /// returns: null if everything worked, [EventProblem.calendarFailed] if
  /// the event was created but the calendar step failed, or another
  /// problem if nothing was created
  Future<EventProblem?> createEvent({
    required String title,
    required EventType type,
    required DateTime startsAt,
    DateTime? endsAt,
    required String placeName,
    required double latitude,
    required double longitude,
    String details = '',
    int maxPeople = defaultMaxPeople,
    bool addToCalendar = false,
  }) async {
    final end = endsAt ?? startsAt.add(defaultLength);
    final issues = validate(
      title: title,
      startsAt: startsAt,
      endsAt: end,
      placeName: placeName,
      details: details,
      maxPeople: maxPeople,
    );
    if (issues.isNotEmpty) {
      return EventProblem.invalidForm;
    }
    final Event created;
    try {
      created = await _repository.createEvent(
        Event(
          id: '',
          hostId: currentUserId,
          title: title.trim(),
          type: type,
          startsAt: startsAt,
          endsAt: end,
          placeName: placeName.trim(),
          latitude: latitude,
          longitude: longitude,
          details: details.trim(),
          maxPeople: maxPeople,
          goingCount: 1,
        ),
      );
    } catch (_) {
      return EventProblem.saveFailed;
    }
    _myRsvps[created.id] = RsvpStatus.going;
    await load();
    if (addToCalendar) {
      return addToGoogleCalendar(created);
    }
    return null;
  }

  /// Saves the host's changes to an event.
  ///
  /// params:
  /// - original: the event before editing
  /// - updated: the edited copy, made with copyWith
  /// returns: null if it worked, or the problem that stopped it
  Future<EventProblem?> updateEvent({
    required Event original,
    required Event updated,
  }) async {
    if (!isHost(original)) {
      return EventProblem.notHost;
    }
    if (hasEnded(original)) {
      return EventProblem.ended;
    }
    final issues = validate(
      title: updated.title,
      startsAt: updated.startsAt,
      endsAt: updated.endsAt,
      placeName: updated.placeName,
      details: updated.details,
      maxPeople: updated.maxPeople,
      existing: original,
    );
    if (issues.isNotEmpty) {
      return EventProblem.invalidForm;
    }
    try {
      await _repository.updateEvent(updated);
    } catch (_) {
      return EventProblem.saveFailed;
    }
    await _refreshAfterChange(updated.id);
    return null;
  }

  /// Cancels an event the user is hosting, removing it for everyone.
  ///
  /// params:
  /// - event: the event to cancel
  /// returns: null if it worked, or the problem that stopped it
  Future<EventProblem?> cancelEvent(Event event) async {
    if (!isHost(event)) {
      return EventProblem.notHost;
    }
    try {
      await _repository.deleteEvent(event.id);
    } catch (_) {
      return EventProblem.saveFailed;
    }
    _myRsvps.remove(event.id);
    _attendees.remove(event.id);
    await load();
    return null;
  }

  /// Adds an event to the user's Google Calendar.
  ///
  /// params:
  /// - event: the event to add
  /// returns: null if it worked, or [EventProblem.calendarFailed]
  Future<EventProblem?> addToGoogleCalendar(Event event) async {
    try {
      await _calendar.addEvent(event);
      return null;
    } catch (_) {
      return EventProblem.calendarFailed;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _changes?.cancel();
    _location.removeListener(_onLocationChanged);
    super.dispose();
  }

  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  void _onLocationChanged() => _notify();

  Future<void> _refreshAfterChange(String eventId) async {
    await load();
    if (_attendees.containsKey(eventId)) {
      await loadAttendees(eventId);
    }
  }

  bool _isVisible(Event event) {
    if (hasEnded(event)) {
      return false;
    }
    if (isHost(event) || _myRsvps[event.id] == RsvpStatus.going) {
      return true;
    }
    final radius = _radiusMiles;
    final distance = distanceMilesTo(event);
    if (radius == null || distance == null) {
      return true;
    }
    return distance <= radius;
  }

  List<Event> _sorted(Iterable<Event> events) {
    final list = events.toList();
    list.sort((a, b) {
      final byTime = a.startsAt.compareTo(b.startsAt);
      if (byTime != 0) {
        return byTime;
      }
      final distanceA = distanceMilesTo(a) ?? double.infinity;
      final distanceB = distanceMilesTo(b) ?? double.infinity;
      return distanceA.compareTo(distanceB);
    });
    return list;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    final localA = a.toLocal();
    final localB = b.toLocal();
    return localA.year == localB.year &&
        localA.month == localB.month &&
        localA.day == localB.day;
  }

  DateTime _startOfToday() {
    final now = _now();
    return DateTime(now.year, now.month, now.day);
  }

  double? _readRadius() {
    final saved = _preferences.getDouble(_radiusKey);
    if (saved == null) {
      return defaultRadiusMiles;
    }
    if (saved == _anywhere) {
      return null;
    }
    return saved;
  }

  double _milesBetween(double lat1, double lng1, double lat2, double lng2) {
    final sinLat = math.sin(_toRadians(lat2 - lat1) / 2);
    final sinLng = math.sin(_toRadians(lng2 - lng1) / 2);
    final a =
        sinLat * sinLat +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            sinLng *
            sinLng;
    return 2 * _earthRadiusMiles * math.asin(math.sqrt(a));
  }

  double _toRadians(double degrees) => degrees * math.pi / 180;
}

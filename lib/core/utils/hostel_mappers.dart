// Translation helpers between backend JSON (snake_case) and the
// Flutter-facing map shape (camelCase).
//
// These are the single source of truth for what a "hostel" and a "room"
// look like on the Flutter side. Both `HostelService` and `AiService`
// import them so a change here propagates everywhere.
// Note: field names must match what `seeker_dashboard.dart` and
// `hostel_detail.dart` expect — those are the two big consumers.

Map<String, dynamic> hostelFromBackend(Map<String, dynamic> raw) {
  final rawRooms = (raw['rooms'] as List?) ?? const [];

  return {
    'id': raw['id'],
    'wardenId': raw['warden_id'],
    'name': raw['name'],
    'city': raw['city'],
    'address': raw['address'],
    'type': raw['type'],
    'latitude': raw['latitude'],
    'longitude': raw['longitude'],
    'facilities':
    (raw['facilities'] as List?)?.cast<String>() ?? const <String>[],
    'photos': (raw['photos'] as List?)?.cast<String>() ?? const <String>[],
    'phone': raw['phone'],
    'whatsapp': raw['whatsapp'],
    'inAppChat': raw['in_app_chat'] ?? true,
    'active': raw['active'] ?? true,
    'startingPrice': raw['starting_price'] ?? 0,
    'hasVacancy': raw['has_vacancy'] ?? false,
    'roomCount': raw['room_count'] ?? 0,
    'createdAt': raw['created_at'],
    'updatedAt': raw['updated_at'],
    'rooms': rawRooms
        .map((r) => roomFromBackend(r as Map<String, dynamic>))
        .toList(),
  };
}

Map<String, dynamic> roomFromBackend(Map<String, dynamic> raw) {
  return {
    'id': raw['id'],
    'hostelId': raw['hostel_id'],
    'number': raw['number'],
    'bookingType': raw['booking_type'],
    'roomType': raw['room_type'],
    'availableSeats': raw['available_seats'],
    'attachedWashroom': raw['attached_washroom'],
    'price': raw['price'],
    'advance': raw['advance'],
    'vacant': raw['vacant'],
    'availabilityDates': (raw['availability_dates'] as List?) ?? const [],
    'availabilitySameDate':
    _sameDate((raw['availability_dates'] as List?) ?? const []),
    'upcomingVacancies': <Map<String, dynamic>>[],
  };
}

bool _sameDate(List<dynamic> dates) {
  if (dates.length <= 1) return true;
  final first = dates.first;
  return dates.every((d) => d == first);
}
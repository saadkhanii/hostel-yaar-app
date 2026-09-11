// ── Shared Dummy Hostel Dataset ─────────────────────────────────────────────
// Single source of truth for placeholder hostel data used across the seeker
// side of the app (dashboard, hostel list/search, hostel detail). Replace
// `DummyHostels.all` with a real Firestore-backed fetch once the backend
// exists — every screen that reads from here will keep working unchanged
// since they all consume the same `Map<String, dynamic>` hostel shape.
//
// Expected shape of each hostel map (matches HostelDetailScreen's docs):
// {
//   'name', 'city', 'address', 'type', 'rating', 'reviewCount',
//   'matchPercent',                      // used for "AI Recommendations" sort
//   'photos': List<String>, 'facilities': List<String>,
//   'phone', 'whatsapp', 'inAppChat',
//   'rooms': List<Map<String, dynamic>>  // { number, bookingType, roomType,
//                                         //   availableSeats, attachedWashroom,
//                                         //   price, advance, vacant }
// }
class DummyHostels {
  DummyHostels._();

  static final List<Map<String, dynamic>> all = [
    {
      'name': 'Green View Hostel',
      'city': 'Gulberg, Lahore',
      'address': '12-B, Main Boulevard, Gulberg III, Lahore',
      'type': 'Boys',
      'rating': 4.5,
      'reviewCount': 32,
      'matchPercent': 94,
      'photos': <String>[],
      'facilities': ['WiFi', 'Meals', 'Laundry', 'Generator', 'CCTV', 'Parking'],
      'phone': '+92 300 1234567',
      'whatsapp': '+92 300 1234567',
      'inAppChat': true,
      'rooms': [
        {'number': '101', 'bookingType': 'Room', 'roomType': 2, 'availableSeats': 2, 'attachedWashroom': true, 'price': 16000, 'advance': 16000, 'vacant': true},
        {'number': '201', 'bookingType': 'Seat', 'roomType': 4, 'availableSeats': 2, 'attachedWashroom': true, 'price': 8000, 'advance': 8000, 'vacant': true},
      ],
    },
    {
      'name': 'Sunrise Boys Hostel',
      'city': 'Model Town, Lahore',
      'address': 'Block C, Model Town, Lahore',
      'type': 'Boys',
      'rating': 4.2,
      'reviewCount': 21,
      'matchPercent': 88,
      'photos': <String>[],
      'facilities': ['WiFi', 'Meals', 'CCTV'],
      'phone': '+92 300 2223344',
      'whatsapp': '+92 300 2223344',
      'inAppChat': true,
      'rooms': [
        {'number': '1', 'bookingType': 'Seat', 'roomType': 3, 'availableSeats': 0, 'attachedWashroom': false, 'price': 7500, 'advance': 7500, 'vacant': false},
      ],
    },
    {
      'name': 'Al-Noor Girls Hostel',
      'city': 'Johar Town, Lahore',
      'address': 'Phase 2, Johar Town, Lahore',
      'type': 'Girls',
      'rating': 4.7,
      'reviewCount': 45,
      'matchPercent': 81,
      'photos': <String>[],
      'facilities': ['WiFi', 'Meals', 'Laundry', 'Generator', 'Parking', 'Water Cooler'],
      'phone': '+92 300 3334455',
      'whatsapp': '+92 300 3334455',
      'inAppChat': true,
      'rooms': [
        {'number': '5', 'bookingType': 'Room', 'roomType': 1, 'availableSeats': 1, 'attachedWashroom': true, 'price': 9000, 'advance': 9000, 'vacant': true},
      ],
    },
    {
      'name': 'City Comfort Hostel',
      'city': 'DHA Phase 5, Lahore',
      'address': 'DHA Phase 5, Lahore',
      'type': 'Mixed',
      'rating': 4.0,
      'reviewCount': 14,
      'matchPercent': 76,
      'photos': <String>[],
      'facilities': ['WiFi', 'CCTV', 'Parking', 'Kitchen'],
      'phone': '+92 300 4445566',
      'whatsapp': '+92 300 4445566',
      'inAppChat': false,
      'rooms': [
        {'number': '12', 'bookingType': 'Room', 'roomType': 3, 'availableSeats': 3, 'attachedWashroom': false, 'price': 11000, 'advance': 11000, 'vacant': true},
      ],
    },
    {
      'name': 'Elite Boys Residency',
      'city': 'Faisal Town, Lahore',
      'address': 'Faisal Town, Lahore',
      'type': 'Boys',
      'rating': 3.9,
      'reviewCount': 9,
      'matchPercent': 70,
      'photos': <String>[],
      'facilities': ['WiFi', 'Meals', 'Generator', 'Refrigerator'],
      'phone': '+92 300 5556677',
      'whatsapp': '+92 300 5556677',
      'inAppChat': true,
      'rooms': [
        {'number': '4', 'bookingType': 'Seat', 'roomType': 6, 'availableSeats': 3, 'attachedWashroom': false, 'price': 6000, 'advance': 6000, 'vacant': true},
      ],
    },
    {
      'name': 'Rose Villa Girls Hostel',
      'city': 'Iqbal Town, Lahore',
      'address': 'Iqbal Town, Lahore',
      'type': 'Girls',
      'rating': 4.4,
      'reviewCount': 27,
      'matchPercent': 85,
      'photos': <String>[],
      'facilities': ['WiFi', 'Meals', 'Laundry', 'CCTV', 'Water Cooler'],
      'phone': '+92 300 6667788',
      'whatsapp': '+92 300 6667788',
      'inAppChat': true,
      'rooms': [
        {'number': '3', 'bookingType': 'Room', 'roomType': 2, 'availableSeats': 0, 'attachedWashroom': true, 'price': 13000, 'advance': 13000, 'vacant': false},
      ],
    },
  ];

  static int startingPrice(Map<String, dynamic> hostel) {
    final rooms = (hostel['rooms'] as List).cast<Map<String, dynamic>>();
    return rooms.map((r) => r['price'] as int).reduce((a, b) => a < b ? a : b);
  }

  static bool hasVacancy(Map<String, dynamic> hostel) {
    final rooms = (hostel['rooms'] as List).cast<Map<String, dynamic>>();
    return rooms.any((r) => r['bookingType'] == 'Room'
        ? r['vacant'] == true
        : (r['availableSeats'] as int? ?? 0) > 0);
  }

  /// Top hostels by AI match score, highest first.
  static List<Map<String, dynamic>> topRecommended({int count = 3}) {
    final sorted = [...all]
      ..sort((a, b) => (b['matchPercent'] as int).compareTo(a['matchPercent'] as int));
    return sorted.take(count).toList();
  }
}
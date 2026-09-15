import 'package:dio/dio.dart';

import '../network/api_client.dart';

class HostelService {
  final Dio _dio = ApiClient().dio;

  // ─────────────────────────────────────────────────────────────────
  // Hostels
  // ─────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> createHostel({
    required String name,
    required String city,
    required String address,
    required String type,
    required List<String> facilities,
    required List<String> photos,
    required String phone,
    String? whatsapp,
    bool inAppChat = true,
    bool active = true,
    double? latitude,
    double? longitude,
    required List<Map<String, dynamic>> rooms,
  }) async {
    try {
      final body = {
        'name': name,
        'city': city,
        'address': address,
        'type': type,
        'latitude': latitude,
        'longitude': longitude,
        'facilities': facilities,
        'photos': photos,
        'phone': phone,
        'whatsapp': whatsapp,
        'in_app_chat': inAppChat,
        'active': active,
        'rooms': rooms.map((r) => _roomToBackend(r)).toList(),
      };

      final response = await _dio.post('/hostels', data: body);
      return _hostelFromBackend(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(_errorMessage(e));
    }
  }

  Future<List<Map<String, dynamic>>> listHostels({
    String? city,
    String? type,
    String? q,
  }) async {
    try {
      final response = await _dio.get(
        '/hostels',
        queryParameters: {
          if (city != null && city.isNotEmpty) 'city': city,
          if (type != null && type != 'All') 'type': type,
          if (q != null && q.isNotEmpty) 'q': q,
        },
      );
      return (response.data as List)
          .map((h) => _hostelFromBackend(h as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(_errorMessage(e));
    }
  }

  Future<Map<String, dynamic>> getHostel(String hostelId) async {
    try {
      final response = await _dio.get('/hostels/$hostelId');
      return _hostelFromBackend(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(_errorMessage(e));
    }
  }

  Future<List<Map<String, dynamic>>> listMyHostels() async {
    try {
      final response = await _dio.get('/hostels/mine');
      return (response.data as List)
          .map((h) => _hostelFromBackend(h as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(_errorMessage(e));
    }
  }

  Future<Map<String, dynamic>> updateHostel(
      String hostelId, {
        String? name,
        String? city,
        String? address,
        String? type,
        List<String>? facilities,
        List<String>? photos,
        String? phone,
        String? whatsapp,
        bool? inAppChat,
        bool? active,
      }) async {
    try {
      final body = <String, dynamic>{
        if (name != null) 'name': name,
        if (city != null) 'city': city,
        if (address != null) 'address': address,
        if (type != null) 'type': type,
        if (facilities != null) 'facilities': facilities,
        if (photos != null) 'photos': photos,
        if (phone != null) 'phone': phone,
        if (whatsapp != null) 'whatsapp': whatsapp,
        if (inAppChat != null) 'in_app_chat': inAppChat,
        if (active != null) 'active': active,
      };

      final response = await _dio.put('/hostels/$hostelId', data: body);
      return _hostelFromBackend(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(_errorMessage(e));
    }
  }

  Future<void> deleteHostel(String hostelId) async {
    try {
      await _dio.delete('/hostels/$hostelId');
    } on DioException catch (e) {
      throw Exception(_errorMessage(e));
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // Rooms
  // ─────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> addRoom(
      String hostelId,
      Map<String, dynamic> room,
      ) async {
    try {
      final response = await _dio.post(
        '/hostels/$hostelId/rooms',
        data: _roomToBackend(room),
      );
      return _roomFromBackend(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(_errorMessage(e));
    }
  }

  Future<Map<String, dynamic>> updateRoom(
      String hostelId,
      String roomId,
      Map<String, dynamic> updates,
      ) async {
    try {
      final response = await _dio.put(
        '/hostels/$hostelId/rooms/$roomId',
        data: _roomToBackend(updates, partial: true),
      );
      return _roomFromBackend(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(_errorMessage(e));
    }
  }

  Future<void> deleteRoom(String hostelId, String roomId) async {
    try {
      await _dio.delete('/hostels/$hostelId/rooms/$roomId');
    } on DioException catch (e) {
      throw Exception(_errorMessage(e));
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // Translation: backend (snake_case) <-> Flutter (camelCase)
  // ─────────────────────────────────────────────────────────────────

  /// Convert a Flutter-shaped room map into the backend's snake_case JSON.
  ///
  /// When [partial] is true (for updates), only keys actually present in
  /// the input map are included — this lets PUT be a true partial update.
  Map<String, dynamic> _roomToBackend(
      Map<String, dynamic> room, {
        bool partial = false,
      }) {
    final out = <String, dynamic>{};

    void copy(String dartKey, String jsonKey) {
      if (room.containsKey(dartKey)) {
        out[jsonKey] = room[dartKey];
      } else if (!partial) {
        // For full creates, pass through null so Pydantic uses defaults.
        // (Pydantic's Field(default=...) applies when the key is absent;
        // sending null where a value is required would fail validation.)
      }
    }

    copy('number', 'number');
    copy('bookingType', 'booking_type');
    copy('roomType', 'room_type');
    copy('availableSeats', 'available_seats');
    copy('attachedWashroom', 'attached_washroom');
    copy('price', 'price');
    copy('advance', 'advance');
    copy('vacant', 'vacant');
    copy('availabilityDates', 'availability_dates');

    // Carried-over keys that don't exist on the backend are silently dropped.
    return out;
  }

  /// Convert a backend hostel JSON object into the Flutter shape.
  ///
  /// The Flutter side keeps using camelCase everywhere, but the backend
  /// speaks snake_case — this normalizes so existing screens don't need
  /// to know about the backend's naming.
  Map<String, dynamic> _hostelFromBackend(Map<String, dynamic> raw) {
    final facilitiesList = (raw['facilities'] as List?)?.cast<String>() ?? [];
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
      'facilities': {
        for (final f in facilitiesList) f: true,
      },
      'photos': (raw['photos'] as List?)?.cast<String>() ?? const [],
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
          .map((r) => _roomFromBackend(r as Map<String, dynamic>))
          .toList(),
      // Placeholder until reviews exist.
      'reviewCount': 0,
      'rating': 0.0,
    };
  }

  /// Convert a backend room JSON object into the Flutter shape used by
  /// HostelRoomsScreen, HostelDetailScreen, and the Add Hostel wizard.
  Map<String, dynamic> _roomFromBackend(Map<String, dynamic> raw) {
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

  String _errorMessage(DioException e) {
    if (e.response?.data is Map && e.response!.data['detail'] != null) {
      return e.response!.data['detail'].toString();
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Server not responding. Is the backend running?';
    }
    if (e.type == DioExceptionType.connectionError) {
      return 'Cannot reach the server. Check your network.';
    }
    return 'Request failed: ${e.message ?? 'unknown error'}';
  }
}
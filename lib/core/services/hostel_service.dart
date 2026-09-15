import 'package:dio/dio.dart';

import '../network/api_client.dart';

class HostelService {
  final Dio _dio = ApiClient().dio;

  // ─────────────────────────────────────────────────────────────────
  // Hostels
  // ─────────────────────────────────────────────────────────────────

  /// Create a hostel (with rooms) for the logged-in warden.
  /// The Flutter wizard collects rooms in a `List<Map<String, dynamic>>`
  /// using camelCase keys — this method translates them to the backend's
  /// snake_case before sending.
  Future<Map<String, dynamic>> createHostel({
    required String name,
    required String city,
    required String address,
    required String type, // 'Boys' | 'Girls' | 'Mixed'
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
        'rooms': rooms.map(_roomToJson).toList(),
      };

      final response = await _dio.post('/hostels', data: body);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(_errorMessage(e));
    }
  }

  /// List all active hostels (public). Optional filters.
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
      return (response.data as List).cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw Exception(_errorMessage(e));
    }
  }

  /// Get a single hostel with its rooms.
  Future<Map<String, dynamic>> getHostel(String hostelId) async {
    try {
      final response = await _dio.get('/hostels/$hostelId');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(_errorMessage(e));
    }
  }

  /// The logged-in warden's own hostels (includes inactive).
  Future<List<Map<String, dynamic>>> listMyHostels() async {
    try {
      final response = await _dio.get('/hostels/mine');
      return (response.data as List).cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw Exception(_errorMessage(e));
    }
  }

  /// Update a hostel. Only the fields you pass are changed.
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
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(_errorMessage(e));
    }
  }

  /// Delete a hostel (its rooms cascade-delete).
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
        data: _roomToJson(room),
      );
      return response.data as Map<String, dynamic>;
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
        data: _roomToJson(updates, partial: true),
      );
      return response.data as Map<String, dynamic>;
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
  // Internals
  // ─────────────────────────────────────────────────────────────────

  /// Convert a Flutter room map (camelCase) into the backend's
  /// snake_case JSON shape.
  ///
  /// When [partial] is true (for updates), only keys actually present in
  /// the input map are included — this lets `PUT` be a true partial
  /// update rather than overwriting everything with nulls.
  Map<String, dynamic> _roomToJson(
      Map<String, dynamic> room, {
        bool partial = false,
      }) {
    final out = <String, dynamic>{};

    void put(String dartKey, String jsonKey) {
      if (room.containsKey(dartKey)) {
        out[jsonKey] = room[dartKey];
      } else if (!partial) {
        // For full creates, always include the key so Pydantic picks up
        // its defaults rather than complaining about a missing field.
        // (Actually Pydantic defaults make this optional, but being
        // explicit avoids surprises.)
      }
    }

    put('number', 'number');
    put('bookingType', 'booking_type');
    put('roomType', 'room_type');
    put('availableSeats', 'available_seats');
    put('attachedWashroom', 'attached_washroom');
    put('price', 'price');
    put('advance', 'advance');
    put('vacant', 'vacant');
    put('availabilityDates', 'availability_dates');

    return out;
  }

  /// Pull a readable message out of a DioException.
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
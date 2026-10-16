import 'package:dio/dio.dart';

import '../network/api_client.dart';
import '../utils/hostel_mappers.dart';

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
      return hostelFromBackend(response.data as Map<String, dynamic>);
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
          .map((h) => hostelFromBackend(h as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(_errorMessage(e));
    }
  }

  Future<Map<String, dynamic>> getHostel(String hostelId) async {
    try {
      final response = await _dio.get('/hostels/$hostelId');
      return hostelFromBackend(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(_errorMessage(e));
    }
  }

  Future<List<Map<String, dynamic>>> listMyHostels() async {
    try {
      final response = await _dio.get('/hostels/mine');
      return (response.data as List)
          .map((h) => hostelFromBackend(h as Map<String, dynamic>))
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
      return hostelFromBackend(response.data as Map<String, dynamic>);
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
      return roomFromBackend(response.data as Map<String, dynamic>);
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
      return roomFromBackend(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(_errorMessage(e));
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // Saved Hostels
  // ─────────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> listSavedHostels() async {
    try {
      final response = await _dio.get('/saved-hostels');
      return (response.data as List).map((item) {
        final m = item as Map<String, dynamic>;
        return {
          'savedAt': m['saved_at'],
          'hostel': hostelFromBackend(m['hostel'] as Map<String, dynamic>),
        };
      }).toList();
    } on DioException catch (e) {
      throw Exception(_errorMessage(e));
    }
  }

  Future<void> saveHostel(String hostelId) async {
    try {
      await _dio.post('/saved-hostels/$hostelId');
    } on DioException catch (e) {
      throw Exception(_errorMessage(e));
    }
  }

  Future<void> unsaveHostel(String hostelId) async {
    try {
      await _dio.delete('/saved-hostels/$hostelId');
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
  // Backend-shape translation (Flutter -> backend)
  // ─────────────────────────────────────────────────────────────────

  /// Convert a Flutter-side room map to the backend shape (snake_case).
  /// Kept private because only this service creates/updates rooms.
  Map<String, dynamic> _roomToBackend(
      Map<String, dynamic> room, {
        bool partial = false,
      }) {
    final out = <String, dynamic>{};

    void copy(String dartKey, String jsonKey) {
      if (room.containsKey(dartKey)) {
        out[jsonKey] = room[dartKey];
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

    return out;
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
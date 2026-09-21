import 'package:dio/dio.dart';

import '../network/api_client.dart';

/// API client for booking requests.
///
/// Seeker side: create, list own.
/// Warden side: list for their hostels, accept, reject.
class BookingService {
  final Dio _dio = ApiClient().dio;

  // ─────────────────────────────────────────────────────────────────
  // Seeker
  // ─────────────────────────────────────────────────────────────────

  /// Create a booking request. Returns the created request.
  Future<Map<String, dynamic>> createRequest({
    required String hostelId,
    required String roomId,
    required DateTime moveInDate,
    String? message,
  }) async {
    try {
      final response = await _dio.post('/booking-requests', data: {
        'hostel_id': hostelId,
        'room_id': roomId,
        'move_in_date': moveInDate.toIso8601String(),
        if (message != null && message.trim().isNotEmpty)
          'message': message.trim(),
      });
      return _fromBackend(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(_errorMessage(e));
    }
  }

  /// Current seeker's requests, newest first.
  Future<List<Map<String, dynamic>>> listMyRequests() async {
    try {
      final response = await _dio.get('/booking-requests/mine');
      return (response.data as List)
          .map((r) => _fromBackend(r as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(_errorMessage(e));
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // Warden
  // ─────────────────────────────────────────────────────────────────

  /// All requests for the logged-in warden's hostels, newest first.
  Future<List<Map<String, dynamic>>> listWardenRequests() async {
    try {
      final response = await _dio.get('/booking-requests/warden');
      return (response.data as List)
          .map((r) => _fromBackend(r as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(_errorMessage(e));
    }
  }

  /// Cancel a pending booking request. Seeker-only.
  Future<void> cancelRequest(String requestId) async {
    try {
      await _dio.delete('/booking-requests/$requestId');
    } on DioException catch (e) {
      throw Exception(_errorMessage(e));
    }
  }

  Future<Map<String, dynamic>> acceptRequest(
      String requestId, {
        String? wardenReply,
      }) async {
    try {
      final response = await _dio.patch(
        '/booking-requests/$requestId/accept',
        data: {
          if (wardenReply != null && wardenReply.trim().isNotEmpty)
            'warden_reply': wardenReply.trim(),
        },
      );
      return _fromBackend(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(_errorMessage(e));
    }
  }

  Future<Map<String, dynamic>> rejectRequest(
      String requestId, {
        String? wardenReply,
      }) async {
    try {
      final response = await _dio.patch(
        '/booking-requests/$requestId/reject',
        data: {
          if (wardenReply != null && wardenReply.trim().isNotEmpty)
            'warden_reply': wardenReply.trim(),
        },
      );
      return _fromBackend(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(_errorMessage(e));
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // Translation: backend (snake_case) -> Flutter (camelCase)
  // ─────────────────────────────────────────────────────────────────

  Map<String, dynamic> _fromBackend(Map<String, dynamic> raw) {
    return {
      'id': raw['id'],
      'seekerId': raw['seeker_id'],
      'hostelId': raw['hostel_id'],
      'roomId': raw['room_id'],
      'seatRequested': raw['seat_requested'] ?? false,
      'moveInDate': raw['move_in_date'],
      'message': raw['message'],
      'wardenReply': raw['warden_reply'],
      'status': raw['status'],
      'createdAt': raw['created_at'],
      'respondedAt': raw['responded_at'],
      'seekerName': raw['seeker_name'] ?? '',
      'seekerPhone': raw['seeker_phone'],
      'hostelName': raw['hostel_name'] ?? '',
      'hostelCity': raw['hostel_city'] ?? '',
      'roomNumber': raw['room_number'] ?? '',
      'roomType': raw['room_type'] ?? 0,
      'roomBookingType': raw['room_booking_type'] ?? '',
      'roomPrice': raw['room_price'] ?? 0,
      'roomAdvance': raw['room_advance'] ?? 0,
    };
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
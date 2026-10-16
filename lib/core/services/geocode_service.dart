import 'package:dio/dio.dart';

import '../network/api_client.dart';

/// Client for the backend's /geocode endpoints.
///
/// The backend proxies Nominatim so we don't hit their servers directly
/// from the app (they require a specific User-Agent and rate-limit at
/// the application level, not the device level).
class GeocodeService {
  final Dio _dio = ApiClient().dio;

  /// Turn (lat, lng) into a human-readable address.
  ///
  /// Returns an empty string if the upstream service has no data for
  /// those coordinates (common in less-mapped areas of Pakistan).
  /// Throws on network or server errors so callers can decide what to do.
  Future<String> reverse({
    required double lat,
    required double lng,
  }) async {
    try {
      final response = await _dio.get(
        '/geocode/reverse',
        queryParameters: {'lat': lat, 'lng': lng},
      );
      final data = response.data as Map<String, dynamic>;
      return (data['address'] as String?) ?? '';
    } on DioException catch (e) {
      throw Exception(_errorMessage(e));
    }
  }

  String _errorMessage(DioException e) {
    final body = e.response?.data;
    if (body is Map && body['detail'] != null) {
      return body['detail'].toString();
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Location lookup timed out. Please try again.';
    }
    if (e.type == DioExceptionType.connectionError) {
      return 'Cannot reach the server. Check your connection.';
    }
    return 'Something went wrong: ${e.message ?? 'unknown error'}';
  }
}
import 'package:dio/dio.dart';

import '../network/api_client.dart';
import '../utils/hostel_mappers.dart';

/// Result of an AI-powered hostel search.
///
/// `filters` mirrors what the LLM extracted from the free-text query
/// (all fields optional — the LLM fills what it can).
///
/// `hostels` is already converted to the Flutter map shape, so callers
/// can feed the list straight into the same card widgets used elsewhere.
class AiSearchResult {
  final Map<String, dynamic> filters;
  final String explanation;
  final List<Map<String, dynamic>> hostels;

  const AiSearchResult({
    required this.filters,
    required this.explanation,
    required this.hostels,
  });
}

/// Talks to the FastAPI /ai endpoints.
///
/// Currently just one method — `search` — which turns a free-text query
/// into filters (extracted by Gemini server-side) and returns matching
/// hostels.
class AiService {
  final Dio _dio = ApiClient().dio;

  /// Send a free-text query like
  /// "student looking for boys hostel in Lahore under 15k with wifi"
  /// and get back the parsed filters, an explanation, and matches.
  Future<AiSearchResult> search(String query) async {
    try {
      final response = await _dio.post(
        '/ai/search',
        data: {'query': query},
      );

      final data = response.data as Map<String, dynamic>;

      final rawHostels = (data['hostels'] as List?) ?? const [];
      final hostels = rawHostels
          .map((h) => hostelFromBackend(h as Map<String, dynamic>))
          .toList();

      return AiSearchResult(
        filters: (data['filters'] as Map?)?.cast<String, dynamic>() ??
            <String, dynamic>{},
        explanation: data['explanation'] as String? ?? '',
        hostels: hostels,
      );
    } on DioException catch (e) {
      throw Exception(_errorMessage(e));
    }
  }

  String _errorMessage(DioException e) {
    // Backend sends `detail` on errors — surface that verbatim when present.
    final body = e.response?.data;
    if (body is Map && body['detail'] != null) {
      return body['detail'].toString();
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'AI search timed out. Please try again.';
    }
    if (e.type == DioExceptionType.connectionError) {
      return 'Cannot reach the server. Check your connection.';
    }
    if (e.response?.statusCode == 503) {
      return 'AI search is not available right now.';
    }
    return 'Something went wrong: ${e.message ?? 'unknown error'}';
  }
}
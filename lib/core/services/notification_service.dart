import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../network/api_client.dart';

/// Client for the notifications API. Also exposes [version] — a
/// ValueNotifier that bumps whenever the unread count changes, so
/// badges across the app can listen and refresh without polling.
class NotificationService {
  final Dio _dio = ApiClient().dio;

  /// Bumped whenever the unread count is known to have changed.
  static final ValueNotifier<int> version = ValueNotifier<int>(0);

  /// List all notifications for the current user, newest first.
  Future<List<Map<String, dynamic>>> listNotifications() async {
    try {
      final response = await _dio.get('/notifications');
      return (response.data as List)
          .map((n) => _fromBackend(n as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(_errorMessage(e));
    }
  }

  /// Number of unread notifications for the current user.
  Future<int> unreadCount() async {
    try {
      final response = await _dio.get('/notifications/unread-count');
      final data = response.data as Map<String, dynamic>;
      return (data['count'] as int?) ?? 0;
    } on DioException catch (e) {
      throw Exception(_errorMessage(e));
    }
  }

  /// Mark a single notification as read. Bumps [version].
  Future<void> markRead(String notificationId) async {
    try {
      await _dio.patch('/notifications/$notificationId/read');
      version.value++;
    } on DioException catch (e) {
      throw Exception(_errorMessage(e));
    }
  }

  /// Mark every notification as read. Bumps [version].
  Future<void> markAllRead() async {
    try {
      await _dio.patch('/notifications/read-all');
      version.value++;
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
      'type': raw['type'],
      'title': raw['title'] ?? '',
      'body': raw['body'],
      'relatedId': raw['related_id'],
      'isRead': raw['is_read'] ?? false,
      'createdAt': raw['created_at'],
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
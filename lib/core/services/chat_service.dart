import 'package:dio/dio.dart';

import '../network/api_client.dart';

/// Talks to the FastAPI /chat endpoints.
///
/// All methods return maps in Flutter camelCase shape so the UI layer
/// never has to think about snake_case. Timestamps come back as ISO-8601
/// strings and are parsed by callers when they need a DateTime.
class ChatService {
  final Dio _dio = ApiClient().dio;

  // ── Start / fetch a conversation ────────────────────────────────────

  /// Gets-or-creates the conversation between the current user and
  /// [otherUserId], scoped to [hostelId] (pass null for a generic thread).
  ///
  /// Returns a map with keys: id, seekerId, wardenId, hostelId,
  /// lastMessageAt, createdAt.
  Future<Map<String, dynamic>> startConversation({
    required String otherUserId,
    String? hostelId,
  }) async {
    try {
      final res = await _dio.post(
        '/chat/conversations',
        data: {
          'other_user_id': otherUserId,
          if (hostelId != null) 'hostel_id': hostelId,
        },
      );
      return _conversationFromBackend(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(_msg(e, 'Could not start conversation'));
    }
  }

  // ── Inbox list ──────────────────────────────────────────────────────

  /// Returns every conversation the current user is part of, newest first.
  /// Server has already picked the right `displayName`/`subtitle` based
  /// on who's asking (seeker sees hostel name, warden sees seeker name).
  Future<List<Map<String, dynamic>>> listConversations() async {
    try {
      final res = await _dio.get('/chat/conversations');
      final list = (res.data as List).cast<Map<String, dynamic>>();
      return list.map(_previewFromBackend).toList();
    } on DioException catch (e) {
      throw Exception(_msg(e, 'Could not load conversations'));
    }
  }

  // ── Messages ────────────────────────────────────────────────────────

  /// Fetches the full message history for [conversationId]. The server
  /// also marks any unread messages from the other person as read as a
  /// side effect — that's why we don't need a separate "mark read" call.
  Future<List<Map<String, dynamic>>> listMessages(String conversationId) async {
    try {
      final res = await _dio.get('/chat/conversations/$conversationId/messages');
      final list = (res.data as List).cast<Map<String, dynamic>>();
      return list.map(_messageFromBackend).toList();
    } on DioException catch (e) {
      throw Exception(_msg(e, 'Could not load messages'));
    }
  }

  /// Sends a message. Returns the created message in Flutter shape.
  Future<Map<String, dynamic>> sendMessage(
      String conversationId,
      String text,
      ) async {
    try {
      final res = await _dio.post(
        '/chat/conversations/$conversationId/messages',
        data: {'text': text},
      );
      return _messageFromBackend(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(_msg(e, 'Could not send message'));
    }
  }

  // ── Shape converters ────────────────────────────────────────────────

  Map<String, dynamic> _conversationFromBackend(Map<String, dynamic> j) => {
    'id': j['id'],
    'seekerId': j['seeker_id'],
    'wardenId': j['warden_id'],
    'hostelId': j['hostel_id'],
    'lastMessageAt': j['last_message_at'],
    'createdAt': j['created_at'],
  };

  Map<String, dynamic> _previewFromBackend(Map<String, dynamic> j) => {
    'id': j['id'],
    'otherUserId': j['other_user_id'],
    'hostelId': j['hostel_id'],
    'displayName': j['display_name'],
    'subtitle': j['subtitle'],
    'avatarUrl': j['avatar_url'],
    'lastMessageText': j['last_message_text'],
    'lastMessageAt': j['last_message_at'],
    'unreadCount': j['unread_count'],
  };

  Map<String, dynamic> _messageFromBackend(Map<String, dynamic> j) => {
    'id': j['id'],
    'conversationId': j['conversation_id'],
    'senderId': j['sender_id'],
    'text': j['text'],
    'createdAt': j['created_at'],
    'readAt': j['read_at'],
  };

  String _msg(DioException e, String fallback) {
    final data = e.response?.data;
    if (data is Map && data['detail'] != null) {
      return data['detail'].toString();
    }
    return fallback;
  }
}
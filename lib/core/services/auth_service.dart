import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../network/api_client.dart';

/// Keys used in secure storage. Centralized here so we don't typo them
/// in different places.
class _StorageKeys {
  static const token = 'jwt_token';
  static const userId = 'user_id';
  static const fullName = 'user_full_name';
  static const email = 'user_email';
  static const role = 'user_role';
  static const phone = 'user_phone';
  static const profilePicture = 'user_profile_picture';
}

class AuthService {
  final Dio _dio = ApiClient().dio;
  final _storage = const FlutterSecureStorage();

  /// Bumped whenever cached user identity changes (name, picture, phone).
  /// UserAvatar and other identity-aware widgets listen to this so they
  /// can re-fetch without a full screen rebuild.
  static final ValueNotifier<int> identityVersion = ValueNotifier<int>(0);

  // ─────────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────────

  /// Title-case a name: "saad khan" -> "Saad Khan".
  /// Preserves existing capitalization after the first letter.
  static String titleCase(String input) {
    if (input.isEmpty) return input;
    return input
        .split(' ')
        .map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1);
    })
        .join(' ');
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

  // --- LOGIN ---
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );

      await _persistSession(response.data);
      return response.data;
    } on DioException catch (e) {
      String msg;
      if (e.response?.data is Map && e.response!.data['detail'] != null) {
        msg = e.response!.data['detail'].toString();
      } else {
        msg = 'Login failed';
      }
      throw Exception(msg);
    }
  }

  // --- SIGNUP ---
  Future<Map<String, dynamic>> signup({
    required String fullName,
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/signup',
        data: {
          'full_name': fullName,
          'email': email,
          'password': password,
          'role': role,
        },
      );

      await _persistSession(response.data);
      return response.data;
    } on DioException catch (e) {
      String msg;
      if (e.response?.data is Map && e.response!.data['detail'] != null) {
        msg = e.response!.data['detail'].toString();
      } else {
        msg = 'Signup failed';
      }
      throw Exception(msg);
    }
  }

  // --- FORGOT PASSWORD (send OTP) ---
  Future<void> forgotPassword(String email) async {
    try {
      await _dio.post('/auth/forgot-password', data: {'email': email});
    } on DioException catch (e) {
      throw Exception(e.response?.data['detail'] ?? 'Failed to send reset code');
    }
  }

  // --- VERIFY OTP ---
  Future<void> verifyOtp(String email, String code) async {
    try {
      await _dio.post(
        '/auth/verify-otp',
        data: {'email': email, 'code': code},
      );
    } on DioException catch (e) {
      throw Exception(e.response?.data['detail'] ?? 'Invalid or expired code');
    }
  }

  // --- RESET PASSWORD ---
  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    try {
      await _dio.post(
        '/auth/reset-password',
        data: {
          'email': email,
          'code': code,
          'new_password': newPassword,
        },
      );
    } on DioException catch (e) {
      throw Exception(e.response?.data['detail'] ?? 'Failed to reset password');
    }
  }

  // --- SESSION PERSISTENCE ---

  /// Save everything we need to know about the logged-in user so the app
  /// can restore state instantly on next launch without a network call.
  Future<void> _persistSession(Map<String, dynamic> data) async {
    await _storage.write(key: _StorageKeys.token, value: data['access_token']);
    await _storage.write(key: _StorageKeys.userId, value: data['user_id']);
    await _storage.write(
      key: _StorageKeys.fullName,
      value: titleCase((data['full_name'] as String? ?? '').trim()),
    );
    await _storage.write(key: _StorageKeys.email, value: data['email']);
    await _storage.write(key: _StorageKeys.role, value: data['role']);
    // Only present on some responses (e.g. after profile update).
    final phone = data['phone'] as String?;
    if (phone != null) {
      await _storage.write(key: _StorageKeys.phone, value: phone);
    }
    final profilePicture = data['profile_picture_url'] as String?;
    if (profilePicture != null) {
      await _storage.write(
        key: _StorageKeys.profilePicture,
        value: profilePicture,
      );
    }

    identityVersion.value++;
  }

  Future<String?> getToken() => _storage.read(key: _StorageKeys.token);

  Future<String?> getRole() => _storage.read(key: _StorageKeys.role);

  /// Returns the cached full name, title-cased on read. This covers users
  /// whose name was stored before we started title-casing at write time.
  Future<String?> getFullName() async {
    final raw = await _storage.read(key: _StorageKeys.fullName);
    if (raw == null || raw.isEmpty) return raw;
    return titleCase(raw);
  }

  Future<String?> getEmail() => _storage.read(key: _StorageKeys.email);

  Future<String?> getPhone() => _storage.read(key: _StorageKeys.phone);

  Future<String?> getProfilePicture() =>
      _storage.read(key: _StorageKeys.profilePicture);

  Future<String?> getUserId() => _storage.read(key: _StorageKeys.userId);

  // ─────────────────────────────────────────────────────────────────
  // Profile
  // ─────────────────────────────────────────────────────────────────

  /// Update the logged-in user's name, phone, and/or picture. Also
  /// refreshes the locally cached identity so the drawer/greeting/avatars
  /// reflect the change without needing a re-login.
  Future<void> updateProfile({
    String? fullName,
    String? phone,
    String? profilePictureUrl,
  }) async {
    try {
      final body = <String, dynamic>{
        if (fullName != null) 'full_name': fullName,
        if (phone != null) 'phone': phone,
        if (profilePictureUrl != null) 'profile_picture_url': profilePictureUrl,
      };
      if (body.isEmpty) return;

      final response = await _dio.patch('/auth/me', data: body);
      final data = response.data as Map<String, dynamic>;

      // Refresh cached identity so the UI is consistent everywhere.
      final newName = data['full_name'] as String?;
      if (newName != null && newName.isNotEmpty) {
        await _storage.write(
          key: _StorageKeys.fullName,
          value: titleCase(newName.trim()),
        );
      }
      final newPhone = data['phone'] as String?;
      if (newPhone != null) {
        await _storage.write(key: _StorageKeys.phone, value: newPhone);
      }
      // Empty string means "photo was removed" — clear the cached value.
      final newPicture = data['profile_picture_url'] as String?;
      if (newPicture != null && newPicture.isNotEmpty) {
        await _storage.write(
          key: _StorageKeys.profilePicture,
          value: newPicture,
        );
      } else {
        await _storage.delete(key: _StorageKeys.profilePicture);
      }

      identityVersion.value++;
    } on DioException catch (e) {
      throw Exception(_errorMessage(e));
    }
  }

  /// Change the logged-in user's password.
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      await _dio.patch('/auth/change-password', data: {
        'old_password': oldPassword,
        'new_password': newPassword,
      });
    } on DioException catch (e) {
      throw Exception(_errorMessage(e));
    }
  }

  /// True if a JWT token is present. Note: does NOT verify the token hasn't
  /// expired — that's handled by the backend (returns 401) and by the Dio
  /// interceptor if you add one later.
  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: _StorageKeys.token);
    return token != null && token.isNotEmpty;
  }

  /// Wipes all stored session data. Call on logout.
  Future<void> logout() async {
    await _storage.delete(key: _StorageKeys.token);
    await _storage.delete(key: _StorageKeys.userId);
    await _storage.delete(key: _StorageKeys.fullName);
    await _storage.delete(key: _StorageKeys.email);
    await _storage.delete(key: _StorageKeys.role);
    await _storage.delete(key: _StorageKeys.phone);
    await _storage.delete(key: _StorageKeys.profilePicture);

    identityVersion.value++;
  }
}
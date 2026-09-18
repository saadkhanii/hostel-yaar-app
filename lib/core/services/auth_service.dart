import 'package:dio/dio.dart';
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
}

class AuthService {
  final Dio _dio = ApiClient().dio;
  final _storage = const FlutterSecureStorage();

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
    await _storage.write(key: _StorageKeys.fullName, value: data['full_name']);
    await _storage.write(key: _StorageKeys.email, value: data['email']);
    await _storage.write(key: _StorageKeys.role, value: data['role']);
    // Only present on some responses (e.g. after profile update).
    final phone = data['phone'] as String?;
    if (phone != null) {
      await _storage.write(key: _StorageKeys.phone, value: phone);
    }
  }

  Future<String?> getToken() => _storage.read(key: _StorageKeys.token);

  Future<String?> getRole() => _storage.read(key: _StorageKeys.role);

  Future<String?> getFullName() =>
      _storage.read(key: _StorageKeys.fullName);

  Future<String?> getEmail() => _storage.read(key: _StorageKeys.email);

  Future<String?> getPhone() => _storage.read(key: _StorageKeys.phone);

  Future<String?> getUserId() => _storage.read(key: _StorageKeys.userId);
  // ─────────────────────────────────────────────────────────────────
  // Profile
  // ─────────────────────────────────────────────────────────────────

  /// Update the logged-in user's name and/or phone. Also refreshes the
  /// locally cached `full_name` so the drawer/greeting reflect the
  /// change without needing a re-login.
  Future<void> updateProfile({
    String? fullName,
    String? phone,
  }) async {
    try {
      final body = <String, dynamic>{
        if (fullName != null) 'full_name': fullName,
        if (phone != null) 'phone': phone,
      };
      if (body.isEmpty) return;

      final response = await _dio.patch('/auth/me', data: body);
      final data = response.data as Map<String, dynamic>;

      // Refresh cached identity so the UI is consistent everywhere.
      final newName = data['full_name'] as String?;
      if (newName != null && newName.isNotEmpty) {
        await _storage.write(key: _StorageKeys.fullName, value: newName);
      }
      final newPhone = data['phone'] as String?;
      if (newPhone != null) {
        await _storage.write(key: _StorageKeys.phone, value: newPhone);
      }
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
  }
}
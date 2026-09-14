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
  }

  Future<String?> getToken() => _storage.read(key: _StorageKeys.token);

  Future<String?> getRole() => _storage.read(key: _StorageKeys.role);

  Future<String?> getFullName() =>
      _storage.read(key: _StorageKeys.fullName);

  Future<String?> getEmail() => _storage.read(key: _StorageKeys.email);

  Future<String?> getUserId() => _storage.read(key: _StorageKeys.userId);

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
  }
}
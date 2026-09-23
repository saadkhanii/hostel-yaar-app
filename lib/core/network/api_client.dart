import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final Dio dio;
  final _storage = const FlutterSecureStorage();

  ApiClient._internal() {
    dio = Dio(
      BaseOptions(
        // Android emulator: 10.0.2.2 | iOS sim: localhost | Physical device: your PC's LAN IP
        baseUrl: 'https://hostel-yaar-backend.onrender.com',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Attach JWT automatically to every request that has one stored
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: 'jwt_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          final status = e.response?.statusCode;

          // Only retry on 401, and never retry the refresh endpoint
          // itself (avoids infinite loops).
          final isUnauthorized = status == 401;
          final isRefreshCall =
          e.requestOptions.path.contains('/auth/refresh');
          final alreadyRetried =
              e.requestOptions.extra['retried_after_refresh'] == true;

          if (!isUnauthorized || isRefreshCall || alreadyRetried) {
            return handler.next(e);
          }

          try {
            // Attempt to get a new access token.
            final newToken = await _refreshToken();

            // Retry the original request with the new token.
            final opts = e.requestOptions;
            opts.headers['Authorization'] = 'Bearer $newToken';
            opts.extra['retried_after_refresh'] = true;

            final clone = await dio.fetch(opts);
            return handler.resolve(clone);
          } catch (_) {
            // Refresh failed — the refresh token is expired or revoked.
            // Pass the original 401 up so the UI can react (e.g. the
            // next screen the user visits will force a logout).
            return handler.next(e);
          }
        },

      ),
    );
  }
  /// Calls /auth/refresh using a bare Dio instance so we don't
  /// recursively trigger this same interceptor.
  Future<String> _refreshToken() async {
    final refresh = await _storage.read(key: 'refresh_token');
    if (refresh == null || refresh.isEmpty) {
      throw Exception('No refresh token');
    }

    // A separate Dio so this call doesn't go through the interceptor.
    final bareDio = Dio(BaseOptions(
      baseUrl: dio.options.baseUrl,
      headers: {'Content-Type': 'application/json'},
    ));

    final response = await bareDio.post(
      '/auth/refresh',
      data: {'refresh_token': refresh},
    );

    final data = response.data as Map<String, dynamic>;
    final newAccess = data['access_token'] as String;
    final newRefresh = data['refresh_token'] as String?;

    // Persist both.
    await _storage.write(key: 'jwt_token', value: newAccess);
    if (newRefresh != null && newRefresh.isNotEmpty) {
      await _storage.write(key: 'refresh_token', value: newRefresh);
    }

    return newAccess;
  }
}
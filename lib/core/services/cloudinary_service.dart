import 'dart:io';

import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';

/// Uploads images to Cloudinary and returns the resulting secure URL.
///
/// Uses an **unsigned upload preset**, so no API secret is embedded in
/// the app. The preset name and cloud name are the only credentials
/// needed and are safe to ship.
class CloudinaryService {
  static const String _cloudName = 'dtk7jx3bj';
  static const String _uploadPreset = 'hostel_yaar_unsigned';

  static const String _uploadUrl =
      'https://api.cloudinary.com/v1_1/$_cloudName/image/upload';

  final Dio _dio = Dio();

  /// Upload a local file and return its public HTTPS URL.
  /// Throws an Exception with a readable message on failure.
  Future<String> uploadImage(File file) async {
    try {
      final fileName = file.path.split(Platform.pathSeparator).last;

      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: fileName,
          contentType: _contentTypeFor(fileName),
        ),
        'upload_preset': _uploadPreset,
      });

      final response = await _dio.post(_uploadUrl, data: formData);

      final data = response.data as Map<String, dynamic>;
      final url = data['secure_url'] as String?;

      if (url == null || url.isEmpty) {
        throw Exception('Cloudinary returned no URL');
      }
      return url;
    } on DioException catch (e) {
      final detail = e.response?.data is Map
          ? (e.response!.data['error']?['message']?.toString() ?? e.message)
          : e.message;
      throw Exception('Upload failed: ${detail ?? 'unknown error'}');
    }
  }

  /// Best-effort content type from the file extension. Cloudinary
  /// accepts the file even if this is wrong, but a correct type helps
  /// it decide how to process the image.
  MediaType _contentTypeFor(String filename) {
    final ext = filename.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return MediaType('image', 'jpeg');
      case 'png':
        return MediaType('image', 'png');
      case 'gif':
        return MediaType('image', 'gif');
      case 'webp':
        return MediaType('image', 'webp');
      case 'heic':
        return MediaType('image', 'heic');
      default:
        return MediaType('image', 'jpeg');
    }
  }
}
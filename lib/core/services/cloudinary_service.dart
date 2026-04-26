// FILE LOCATION: lib/core/services/cloudinary_service.dart

import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class CloudinaryService {
  // ⚠️ Replace these with your actual Cloudinary credentials
  static const String _cloudName = 'dmb8wdvpn';
  static const String _uploadPreset = 'pantry_pals_preset'; // unsigned preset

  static const String _baseUrl = 'https://api.cloudinary.com/v1_1';

  /// Uploads an image file to Cloudinary and returns {url, publicId}
  static Future<Map<String, String>?> uploadImage(
    File imageFile, {
    String folder = 'pantryshare',
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/$_cloudName/image/upload');

      final request = http.MultipartRequest('POST', uri);
      request.fields['upload_preset'] = _uploadPreset;
      request.fields['folder'] = folder;

      final mimeType = _getMimeType(imageFile.path);
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          imageFile.path,
          contentType: MediaType.parse(mimeType),
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'url': data['secure_url'] as String,
          'publicId': data['public_id'] as String,
        };
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  /// Deletes an image from Cloudinary by publicId
  static Future<bool> deleteImage(String publicId) async {
    // Implement with a backend endpoint or Firebase Cloud Function if needed.
    return false;
  }

  static String _getMimeType(String path) {
    final ext = path.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }
}

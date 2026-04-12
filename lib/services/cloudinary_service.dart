import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CloudinaryService {
  final String cloudName = 'djohgddcj';
  final String uploadPreset = 'wi_app';

// Upload post video to Cloudinary
  Future<String?> uploadVideo(File videoFile) async {
  try {
    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/video/upload',
    );

    final request = http.MultipartRequest('POST', uri);
    request.fields['upload_preset'] = uploadPreset;
    request.fields['folder'] = 'post_videos';
    request.files.add(
      await http.MultipartFile.fromPath('file', videoFile.path),
    );

    final response = await request.send();
    final responseData = await response.stream.toBytes();
    final responseString = String.fromCharCodes(responseData);
    final jsonData = jsonDecode(responseString);

    if (response.statusCode == 200) {
      return jsonData['secure_url'];
    } else {
      print('Cloudinary video error: ${jsonData['error']['message']}');
      return null;
    }
  } catch (e) {
    print('Video upload error: $e');
    return null;
  }
}

Future<String?> uploadPostImage(File imageFile) async {
  try {
    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
    );

    final request = http.MultipartRequest('POST', uri);
    request.fields['upload_preset'] = uploadPreset;
    request.fields['folder'] = 'post_images';
    request.files.add(
      await http.MultipartFile.fromPath('file', imageFile.path),
    );

    final response = await request.send();
    final responseData = await response.stream.toBytes();
    final responseString = String.fromCharCodes(responseData);
    final jsonData = jsonDecode(responseString);

    if (response.statusCode == 200) {
      return jsonData['secure_url'];
    } else {
      print('Cloudinary image error: ${jsonData['error']['message']}');
      return null;
    }
  } catch (e) {
    print('Image upload error: $e');
    return null;
  }
}
  // Upload profile picture to Cloudinary
  Future<String?> uploadProfilePicture(File imageFile) async {
    try {
      final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
      );

      final request = http.MultipartRequest('POST', uri);
      request.fields['upload_preset'] = uploadPreset;
      request.fields['folder'] = 'profile_pictures';
      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );

      final response = await request.send();
      final responseData = await response.stream.toBytes();
      final responseString = String.fromCharCodes(responseData);
      final jsonData = jsonDecode(responseString);

      if (response.statusCode == 200) {
        return jsonData['secure_url'];
      } else {
        print('Cloudinary error: ${jsonData['error']['message']}');
        return null;
      }
    } catch (e) {
      print('Upload error: $e');
      return null;
    }
  }
  
}
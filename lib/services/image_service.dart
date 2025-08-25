import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';

class ImageService {
  static final ImagePicker _picker = ImagePicker();

  // Pick an image from gallery and return as base64 string
  static Future<String?> pickImageAsBase64({
    ImageSource source = ImageSource.gallery,
    int imageQuality = 70,
  }) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: imageQuality,
      );

      if (pickedFile == null) return null;

      final bytes = await pickedFile.readAsBytes();
      return base64Encode(bytes);
    } catch (e) {
      debugPrint('Error picking image: $e');
      return null;
    }
  }

  // Convert base64 string to Image widget
  static Widget base64ToImage(
    String? base64String, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
  }) {
    if (base64String == null || base64String.isEmpty) {
      return placeholder ?? const Icon(Icons.person, size: 100);
    }

    try {
      return Image.memory(
        base64Decode(base64String),
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) {
          return placeholder ?? const Icon(Icons.broken_image, size: 100);
        },
      );
    } catch (e) {
      debugPrint('Error decoding base64 image: $e');
      return placeholder ?? const Icon(Icons.broken_image, size: 100);
    }
  }

  // Display a dialog to choose camera or gallery
  static Future<String?> showImageSourceDialog(BuildContext context) async {
    ImageSource? source = await showDialog<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Image Source'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                GestureDetector(
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Text('Camera'),
                  ),
                  onTap: () {
                    Navigator.pop(context, ImageSource.camera);
                  },
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Divider(),
                ),
                GestureDetector(
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Text('Gallery'),
                  ),
                  onTap: () {
                    Navigator.pop(context, ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );

    if (source == null) return null;

    return await pickImageAsBase64(source: source);
  }
}

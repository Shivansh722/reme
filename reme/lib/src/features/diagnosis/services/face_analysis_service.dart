import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class FaceAnalysisService {
  // Move the image processing methods from _CameraScreenState here
  Future<Face?> detectFace(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final options = FaceDetectorOptions(
      enableContours: true,
      enableClassification: true,
      performanceMode: FaceDetectorMode.accurate,
    );
    final faceDetector = FaceDetector(options: options);

    try {
      final List<Face> faces = await faceDetector.processImage(inputImage);
      await faceDetector.close();
      
      return faces.isNotEmpty ? faces.first : null;
    } catch (e) {
      print('Error detecting face: $e');
      return null;
    }
  }

  Future<File> cropFaceRegion(File imageFile, Face face) async {
    final bytes = await imageFile.readAsBytes();
    final originalImage = img.decodeImage(bytes);
    
    if (originalImage == null) throw Exception('Failed to decode image');

    final boundingBox = face.boundingBox;
    
    // Add padding around the face (20%)
    final padding = 0.2;
    final paddedLeft = (boundingBox.left - boundingBox.width * padding).clamp(0, originalImage.width.toDouble());
    final paddedTop = (boundingBox.top - boundingBox.height * padding).clamp(0, originalImage.height.toDouble());
    final paddedWidth = (boundingBox.width * (1 + 2 * padding)).clamp(0, originalImage.width.toDouble() - paddedLeft);
    final paddedHeight = (boundingBox.height * (1 + 2 * padding)).clamp(0, originalImage.height.toDouble() - paddedTop);

    final cropped = img.copyCrop(
      originalImage,
      x: paddedLeft.toInt(),
      y: paddedTop.toInt(),
      width: paddedWidth.toInt(),
      height: paddedHeight.toInt(),
    );

    final directory = await getTemporaryDirectory();
    final croppedPath = '${directory.path}/cropped_face.jpg';
    final croppedFile = File(croppedPath)..writeAsBytesSync(img.encodeJpg(cropped));

    return croppedFile;
  }

  String encodeImageToBase64(File imageFile) {
    // Compress the image to reduce size before encoding
    final bytes = imageFile.readAsBytesSync();
    final image = img.decodeImage(bytes);
    
    // Resize if needed - Gemini has size limitations
    final resized = img.copyResize(
      image!, 
      width: 800, // Set appropriate size based on Gemini requirements
    );
    
    final compressedBytes = img.encodeJpg(resized, quality: 85);
    return base64Encode(compressedBytes);
  }

  Future<String> analyzeSkinWithGemini(String base64Image) async {
    // Get API key from .env file
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    
    if (apiKey == null || apiKey.isEmpty) {
      return 'Error: API key not found. Please check your environment configuration.';
    }
    
    // Use the correct model name for Gemini 2.0 Flash
    final url = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$apiKey';

    const prompt = "Analyze this face's skin. Provide a detailed assessment including: "
        "1. Visible pimples or acne (location and severity) "
        "2. Open pores (size and distribution) "
        "3. Signs of dryness or oiliness "
        "4. Any other notable skin conditions "
        "5. Specific skincare recommendations based on these observations "
        "Format the response in clear sections and use non-technical language.";

    final response = await http.post(
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "contents": [
          {
            "parts": [
              {"text": prompt},
              {
                "inline_data": {
                  "mime_type": "image/jpeg",
                  "data": base64Image,
                }
              }
            ]
          }
        ],
        "generation_config": {
          "temperature": 0.4,
          "top_p": 0.95,
          "max_output_tokens": 1024,
        },
      }),
    );

    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      // Check if the response structure is as expected
      if (result.containsKey('candidates') && 
          result['candidates'].isNotEmpty && 
          result['candidates'][0].containsKey('content')) {
        return result['candidates'][0]['content']['parts'][0]['text'];
      } else {
        // Handle unexpected response structure
        print('Unexpected response structure: ${response.body}');
        return 'Unable to analyze skin. Please try again.';
      }
    } else if (response.statusCode == 400) {
      // Handle model-specific errors
      final error = jsonDecode(response.body);
      print('Model error: ${error.toString()}');
      
      // Check for specific error types
      if (error['error'] != null && error['error']['message'] != null) {
        final errorMessage = error['error']['message'];
        if (errorMessage.contains('API_KEY_INVALID')) {
          return 'Authentication error: Invalid API key. Please check your configuration.';
        } else if (errorMessage.contains('quota')) {
          return 'API quota exceeded. Please try again later.';
        }
      }
      
      return 'Skin analysis failed: The model encountered an error. Please try again.';
    } else if (response.statusCode == 429) {
      // Handle rate limiting errors
      final error = jsonDecode(response.body);
      print('Rate limit error: ${error.toString()}');
      return 'API rate limit exceeded. Please try again in a few minutes or contact support to upgrade your plan.';
    } else {
      // Handle other HTTP errors
      print('HTTP error: ${response.statusCode}, Body: ${response.body}');
      return 'Failed to connect to the analysis service. Please check your internet connection.';
    }
  }
}
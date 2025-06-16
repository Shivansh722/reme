import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:reme/src/widgets/customButton.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import 'package:http/http.dart' as http;

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  File? _image;
  File? _croppedImage;
  final ImagePicker _picker = ImagePicker();
  bool _isProcessing = false;
  String? _analysisResult;

  // API key for Gemini Vision API
  // In production, this should be stored securely
  static const String _apiKey = 'YOUR_GEMINI_API_KEY';

  Future<void> _requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.camera,
      Permission.photos,
    ].request();

    if (statuses[Permission.camera] != PermissionStatus.granted ||
        statuses[Permission.photos] != PermissionStatus.granted) {
      // Handle permission denied
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Camera and gallery permissions are required'),
        ),
      );
    }
  }

  Future<void> _takePicture() async {
    await _requestPermissions();
    
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      setState(() {
        _image = File(photo.path);
      });
      _showImagePreview();
    }
  }

  Future<void> _pickFromGallery() async {
    await _requestPermissions();
    
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _image = File(image.path);
      });
      _showImagePreview();
    }
  }

  void _showImagePreview() {
    if (_image == null) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Image Preview'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.file(
              _image!,
              height: 300,
              width: 300,
              fit: BoxFit.cover,
            ),
            const SizedBox(height: 16),
            const Text('Would you like to use this image for diagnosis?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Clear the selected image
              setState(() {
                _image = null;
              });
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Proceed with the selected image
              _processImage();
            },
            child: const Text('Proceed'),
          ),
        ],
      ),
    );
  }

  Future<void> _processImage() async {
    if (_image == null) return;

    setState(() {
      _isProcessing = true;
      _analysisResult = null;
    });

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Processing image...'),
          duration: Duration(seconds: 2),
        ),
      );

      // Step 1: Detect face using ML Kit
      final Face? face = await _detectFace(_image!);
      
      if (face == null) {
        setState(() {
          _isProcessing = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No face detected. Please try again with a clearer image.'),
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }

      // Step 2: Crop to face region
      _croppedImage = await _cropFaceRegion(_image!, face);
      
      // Step 3: Convert to base64
      final String base64Image = _encodeImageToBase64(_croppedImage ?? _image!);
      
      // Step 4: Send to Gemini Vision API
      final String result = await _analyzeSkinWithGemini(base64Image);
      
      setState(() {
        _isProcessing = false;
        _analysisResult = result;
      });
      
      // Show results
      _showAnalysisResults();
      
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error processing image: ${e.toString()}'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<Face?> _detectFace(File imageFile) async {
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

  Future<File> _cropFaceRegion(File imageFile, Face face) async {
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

  String _encodeImageToBase64(File imageFile) {
    final bytes = imageFile.readAsBytesSync();
    return base64Encode(bytes);
  }

  Future<String> _analyzeSkinWithGemini(String base64Image) async {
    const url = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro-vision:generateContent?key=$_apiKey';

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
        ]
      }),
    );

    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      return result['candidates'][0]['content']['parts'][0]['text'];
    } else {
      throw Exception('Failed to analyze skin: ${response.body}');
    }
  }

  void _showAnalysisResults() {
    if (_analysisResult == null) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Skin Analysis Results'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_croppedImage != null) ...[
                Center(
                  child: Image.file(
                    _croppedImage!,
                    height: 200,
                    width: 200,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Text(_analysisResult!),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text('Upload face image'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.camera_alt,
                size: 100,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 30),
              const Text(
                'Take a photo or select from gallery',
                style: TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 60),
              if (_isProcessing)
                Column(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    const Text('Analyzing skin...'),
                  ],
                )
              else ...[
                Custombutton(
                  text: 'Take Photo',
                  onTap: _takePicture,
                ),
                const SizedBox(height: 16),
                Custombutton(
                  text: 'Select from Gallery',
                  onTap: _pickFromGallery,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
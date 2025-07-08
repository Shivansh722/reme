import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';
import 'package:reme/src/features/diagnosis/views/custom_camera_screen.dart';
import 'package:reme/src/features/diagnosis/views/diagnosisChatScreen.dart';
import 'package:reme/src/widgets/customButton.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:reme/src/features/diagnosis/services/face_analysis_service.dart';
import 'package:reme/src/features/shared/radiusChart.dart';
import 'package:reme/src/features/diagnosis/views/analysisResultsScreen.dart';



class DiagnosisView extends StatefulWidget {
  const DiagnosisView({super.key});

  @override
  State<DiagnosisView> createState() => _DiagnosisViewState();
}

class _DiagnosisViewState extends State<DiagnosisView> {
  final ImagePicker _picker = ImagePicker();
  bool _isProcessing = false;

  // Method to request necessary permissions
  Future<void> _requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.camera,
      // Removing Permission.photos as it's not required for camera functionality
    ].request();

    if (statuses[Permission.camera] != PermissionStatus.granted) {
      // Handle permission denied
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Camera permission is required'),
          ),
        );
      }
    }
  }

  // Method to show platform-specific image source picker
  void _showImageSourceDialog() {
    if (Theme.of(context).platform == TargetPlatform.iOS) {
      _showCupertinoImageSourceDialog();
    } else {
      _showMaterialImageSourceDialog();
    }
  }

  // iOS-specific action sheet
  void _showCupertinoImageSourceDialog() {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: const Text('Select Image Source'),
        message: const Text('Choose a source for your image'),
        actions: <CupertinoActionSheetAction>[
          CupertinoActionSheetAction(
            isDefaultAction: true,
            onPressed: () {
              Navigator.pop(context);
              _getImage(ImageSource.camera);
            },
            child: const Text('Take Photo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _getImage(ImageSource.gallery);
            },
            child: const Text('Choose from Library', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDestructiveAction: true,
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Cancel', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),),
        ),
      ),
    );
  }

  // Android-specific bottom sheet
  void _showMaterialImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take a Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _getImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _getImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.cancel),
                title: const Text('Cancel'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Method to get image from selected source
  Future<void> _getImage(ImageSource source) async {
    await _requestPermissions();
    
    try {
      if (source == ImageSource.camera) {
        if (mounted) {
          final result = await Navigator.push<File>(
            context,
            MaterialPageRoute(builder: (context) => const CustomCameraScreen()),
          );
          if (result != null) {
            // Navigate to chat screen for both camera and gallery
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DiagnosisChatScreen(faceImage: result),
              ),
            );
          }
        }
      } else {
        // Use image_picker for gallery
        final XFile? image = await _picker.pickImage(source: source);
        if (image != null) {
          // Navigate to chat screen for both camera and gallery
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DiagnosisChatScreen(faceImage: File(image.path)),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting image: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
     
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                //text
                const Text(
                  '              顔写真を\nアップロードしてください',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 40),

                //image
                Image.asset(
                  'lib/assets/images/img.png',
                  width: 150,
                  height: 150,
                ),
                const SizedBox(height: 60),
                
                if (_isProcessing)
                  const CircularProgressIndicator(),
              ],
            ),
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Custombutton(
                  text: '撮影をはじめる',
                  onTap: _showImageSourceDialog,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// A screen that processes the image
class _ImageProcessingScreen extends StatefulWidget {
  final File imageFile;
  
  const _ImageProcessingScreen({required this.imageFile});
  
  @override
  State<_ImageProcessingScreen> createState() => _ImageProcessingScreenState();
}

class _ImageProcessingScreenState extends State<_ImageProcessingScreen> {
  bool _isProcessing = true;
  String? _analysisResult;
  File? _croppedImage;
  final FaceAnalysisService _analysisService = FaceAnalysisService();
  
  @override
  void initState() {
    super.initState();
    _processImage();
  }
  
  Future<void> _processImage() async {
    try {
      // Use the shared service instead of _CameraScreenState methods
      final face = await _analysisService.detectFace(widget.imageFile);
      
      if (face == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No face detected. Please try again with a clearer image.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
        
        setState(() {
          _isProcessing = false;
        });
        return;
      }
      
      _croppedImage = await _analysisService.cropFaceRegion(widget.imageFile, face);
      final base64Image = _analysisService.encodeImageToBase64(_croppedImage ?? widget.imageFile);
      final result = await _analysisService.analyzeSkinWithGemini(base64Image);
      
      setState(() {
        _analysisResult = result;
        _isProcessing = false;
      });
      
      if (mounted && _analysisResult != null) {
        // Navigate to the analysis results screen
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => AnalysisResultsScreen(
              faceImage: _croppedImage,
              analysisResult: _analysisResult!,
            ),
          ),
        );
      }
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing image: ${e.toString()}'),
          ),
        );
      }
      
      setState(() {
        _isProcessing = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    // Extract scores from analysis result for the radar chart
    Map<String, int> extractScores() {
      final Map<String, int> scores = {};
      
      if (_analysisResult != null) {
        // Try to extract JSON
        final jsonRegex = RegExp(r'\{[\s\S]*?\}');
        final jsonMatch = jsonRegex.firstMatch(_analysisResult!);
        if (jsonMatch != null) {
          try {
            final jsonString = jsonMatch.group(0);
            final Map<String, dynamic> jsonScores = jsonDecode(jsonString!);
            scores['pimples'] = jsonScores['pimples_acne_spots'] ?? 0;
            scores['pores'] = jsonScores['pores'] ?? 0;
            scores['redness'] = jsonScores['redness'] ?? 0;
            scores['firmness'] = jsonScores['firmness'] ?? 0;
            scores['sagging'] = jsonScores['sagging'] ?? 0;
            scores['skin grade'] = jsonScores['skin_grade'] ?? 0;
          } catch (e) {
            print('Error decoding JSON: $e');
            // Default values if JSON parsing fails
            scores['pimples'] = 50;
            scores['pores'] = 50;
            scores['redness'] = 50;
            scores['firmness'] = 50;
            scores['sagging'] = 50;
            scores['skin grade'] = 50;
          }
        } else {
          // Default values if no JSON found
          scores['pimples'] = 50;
          scores['pores'] = 50;
          scores['redness'] = 50;
          scores['firmness'] = 50;
          scores['sagging'] = 50;
          scores['skin grade'] = 50;
        }
      } else {
        // Default values if no analysis result
        scores['pimples'] = 50;
        scores['pores'] = 50;
        scores['redness'] = 50;
        scores['firmness'] = 50;
        scores['sagging'] = 50;
        scores['skin grade'] = 50;
      }
      
      return scores;
    }
    
    final scores = extractScores();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Skin Analysis'),
      ),
      body: _isProcessing
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Analyzing your skin...'),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Replace the image with the radar chart
                  Center(
                    child: SizedBox(
                      width: 280,
                      height: 280,
                      child: CustomRadarChart(
                        values: [
                          scores['pores'] ?? 0,
                          scores['pimples'] ?? 0,
                          scores['redness'] ?? 0, 
                          scores['firmness'] ?? 0,
                          scores['sagging'] ?? 0,
                          scores['skin grade'] ?? 0,
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  if (_analysisResult != null) ...[
                    const Text(
                      'Analysis Results',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(_analysisResult!),
                  ] else
                    const Text('Unable to analyze the image. Please try again.'),
                ],
              ),
            ),
    );
  }
}
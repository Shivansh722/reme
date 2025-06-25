import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';
import 'package:reme/src/widgets/customButton.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:reme/src/features/diagnosis/services/face_analysis_service.dart';

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
      Permission.photos,
    ].request();

    if (statuses[Permission.camera] != PermissionStatus.granted ||
        statuses[Permission.photos] != PermissionStatus.granted) {
      // Handle permission denied
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Camera and gallery permissions are required'),
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
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        // Navigate to a processing screen or show a loading indicator
        setState(() {
          _isProcessing = true;
        });
        
        // Pass the selected image to be processed using a new screen
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => _ImageProcessingScreen(imageFile: File(image.path)),
            ),
          );
        }
        
        setState(() {
          _isProcessing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting image: ${e.toString()}'),
          ),
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
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image/image.dart' as img;
import 'dart:math' as Math;

import 'package:reme/src/features/diagnosis/views/diagnosisChatScreen.dart';
import 'package:reme/src/features/profile/services/profileServices.dart';




class CustomCameraScreen extends StatefulWidget {
  final bool forProfileImage;
  
  const CustomCameraScreen({
    super.key, 
    this.forProfileImage = false,
  });

  @override
  State<CustomCameraScreen> createState() => _CustomCameraScreenState();
}

class _CustomCameraScreenState extends State<CustomCameraScreen> with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> cameras = [];
  bool _isCameraInitialized = false;
  bool _isCapturing = false;
  bool _isFrontCamera = true; // Start with front camera
  bool _hasError = false;
  String _errorMessage = '';
  
  // Face detection
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: true,
      enableClassification: true,
      enableTracking: true,
      performanceMode: FaceDetectorMode.accurate,
    )
  );
  
  // Detection status
  bool _isFaceDetected = false;
  bool _isGoodPosition = false;
  bool _isGoodBrightness = false;
  bool _isFacingFront = false;
  
  // Processing
  bool _isProcessingFrame = false;
  Timer? _autoCaptureCooldown;
  int _frameCount = 0;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _requestPermissions().then((_) => _initializeCamera());
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    _faceDetector.close();
    _autoCaptureCooldown?.cancel();
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _controller;
    
    // App state changed before we got the chance to initialize.
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }
    
    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      if (cameras.isNotEmpty) {
        _initializeController(cameraController.description);
      }
    }
  }

  // Request camera permissions explicitly
  Future<void> _requestPermissions() async {
    try {
      // Only request camera permission, remove microphone and others
      PermissionStatus status = await Permission.camera.request();

      if (status != PermissionStatus.granted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Camera permission is required for this feature';
        });
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Error requesting permissions: $e';
      });
    }
  }
  
  Future<void> _initializeCamera() async {
    try {
      // Initialize with a delay to ensure permissions are processed
      await Future.delayed(const Duration(milliseconds: 500));
      
      cameras = await availableCameras();
      
      if (cameras.isEmpty) {
        setState(() {
          _hasError = true;
          _errorMessage = 'No cameras available on this device';
        });
        return;
      }
      
      // Find front camera by default
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras[0],
      );
      
      await _initializeController(frontCamera);
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Error initializing camera: $e';
      });
    }
  }
  
Future<void> _initializeController(CameraDescription cameraDescription) async {
  try {
    final CameraController cameraController = CameraController(
      cameraDescription,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    _controller = cameraController;

    // Lock orientation to portrait during initialization
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    await cameraController.initialize();
    await cameraController.startImageStream(_processCameraImage);

    if (!mounted) return;

    setState(() {
      _isCameraInitialized = true;
      _hasError = false;
    });
  } catch (e) {
    setState(() {
      _hasError = true;
      _errorMessage = 'Error initializing camera controller: $e';
    });
  }
}
  Future<void> _switchCamera() async {
    if (cameras.length < 2) return;
    
    setState(() {
      _isCameraInitialized = false;
      _isFrontCamera = !_isFrontCamera;
    });
    
    await _controller?.stopImageStream();
    await _controller?.dispose();
    
    if (_isFrontCamera) {
      // Find front camera
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras[0],
      );
      await _initializeController(frontCamera);
    } else {
      // Find back camera
      final backCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras[0],
      );
      await _initializeController(backCamera);
    }
  }
  
  Future<void> _processCameraImage(CameraImage image) async {
  _frameCount++;
  if (_frameCount % 15 != 0) return;

  if (_isCapturing || _isProcessingFrame) return;

  _isProcessingFrame = true;

  try {
    final rotation = _getInputImageRotation();
    final inputImage = _getInputImageFromCameraImage(image, rotation);
    if (inputImage == null) return;

    final List<Face> faces = await _faceDetector.processImage(inputImage);
    _updateFaceMetrics(faces, Size(image.width.toDouble(), image.height.toDouble()), 
                       _getYuvData(image), image.width, image.height);

    // Auto-capture as soon as face is detected
    if (_isFaceDetected && _autoCaptureCooldown == null) {
      print('Auto-capture triggered');
      _autoCaptureCooldown = Timer(const Duration(seconds: 2), () {
        _autoCaptureCooldown = null;
      });

      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        _takePicture();
      }
    }
  } catch (e) {
    print('Error processing camera image: $e');
  } finally {
    _isProcessingFrame = false;
  }
}
  
  // Helper method to get YUV data for brightness calculation
  Uint8List _getYuvData(CameraImage image) {
    // For YUV format, the Y plane (plane[0]) contains the luminance data
    return image.planes[0].bytes;
  }

  // Helper method to get the correct rotation for the input image
InputImageRotation _getInputImageRotation() {
  final orientation = MediaQuery.of(context).orientation;
  final isFrontCamera = _controller?.description.lensDirection == CameraLensDirection.front;

  // Adjust rotation based on device orientation and camera direction
  switch (orientation) {
    case Orientation.portrait:
      return isFrontCamera ? InputImageRotation.rotation270deg : InputImageRotation.rotation90deg;
    case Orientation.landscape:
      return isFrontCamera ? InputImageRotation.rotation0deg : InputImageRotation.rotation0deg;
    default:
      return InputImageRotation.rotation0deg;
  }
}

  // Convert CameraImage to InputImage
InputImage? _getInputImageFromCameraImage(CameraImage image, InputImageRotation rotation) {
  try {
    final format = InputImageFormat.nv21;
    final allBytes = WriteBuffer();

    // Reuse a static buffer if possible
    for (final plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    final imageSize = Size(image.width.toDouble(), image.height.toDouble());
    final metadata = InputImageMetadata(
      size: imageSize,
      rotation: rotation,
      format: format,
      bytesPerRow: image.planes[0].bytesPerRow,
    );

    return InputImage.fromBytes(bytes: bytes, metadata: metadata);
  } catch (e) {
    print("Error creating input image: $e");
    return null;
  }
}
  
  void _updateFaceMetrics(List<Face> faces, Size imageSize, Uint8List bytes, int width, int height) {
  if (!mounted) return;

  setState(() {
    _isFaceDetected = faces.isNotEmpty;
    print('Face Detected: $_isFaceDetected');

    if (!_isFaceDetected) {
      _isGoodPosition = false;
      _isGoodBrightness = false;
      _isFacingFront = false;
      print('No face detected, skipping metrics');
      return;
    }

    final Face face = faces.first;

    final double faceWidth = face.boundingBox.width;
    final double faceHeight = face.boundingBox.height;
    final double faceCenterX = face.boundingBox.left + faceWidth / 2;
    final double faceCenterY = face.boundingBox.top + faceHeight / 2;

    final double imageCenterX = imageSize.width / 2;
    final double imageCenterY = imageSize.height / 2;

    final double distanceFromCenter = Math.sqrt(
      Math.pow(faceCenterX - imageCenterX, 2) + Math.pow(faceCenterY - imageCenterY, 2)
    );
    _isGoodPosition = distanceFromCenter < (imageSize.width * 0.2) && 
                      faceWidth > (imageSize.width * 0.25) &&
                      faceHeight > (imageSize.height * 0.25);
    print('Good Position: $_isGoodPosition (Distance: $distanceFromCenter, FaceWidth: $faceWidth, FaceHeight: $faceHeight)');

    _isFacingFront = face.headEulerAngleY != null && face.headEulerAngleY!.abs() < 15;
    print('Facing Front: $_isFacingFront (EulerAngleY: ${face.headEulerAngleY})');

    _isGoodBrightness = _calculateBrightness(bytes, width, height);
    print('Good Brightness: $_isGoodBrightness');
  });
}

// Relax brightness thresholds
bool _calculateBrightness(Uint8List bytes, int width, int height) {
  int totalBrightness = 0;
  int sampleCount = 0;

  for (int i = 0; i < width * height; i += 20) {
    if (i < bytes.length) {
      totalBrightness += bytes[i];
      sampleCount++;
    }
  }

  if (sampleCount == 0) return false;

  final double averageBrightness = totalBrightness / sampleCount;
  final double normalizedBrightness = averageBrightness / 255;

  // Relaxed brightness range: 0.2 to 0.8
  return normalizedBrightness > 0.2 && normalizedBrightness < 0.8;
}
  
  Future<void> _takePicture() async {
    final CameraController? cameraController = _controller;
    if (cameraController == null || !cameraController.value.isInitialized || _isCapturing) {
      return;
    }
    
    try {
      setState(() {
        _isCapturing = true;
      });
      
      // Stop the image stream before taking a picture
      await cameraController.stopImageStream();
      
      // Wait a moment for the camera to stabilize
      await Future.delayed(const Duration(milliseconds: 300));
      
      final XFile image = await cameraController.takePicture();
      
      setState(() {
        _isCapturing = false;
      });
      
      if (!mounted) return;
      
      final imageFile = File(image.path);
      
      // If this is for profile image, save it and navigate back
      if (widget.forProfileImage) {
        final imagePath = await ProfileImageService.saveProfileImage(imageFile);
        
        // Show success message and return to profile
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('プロフィール画像を更新しました')),
        );
        
        // Return to profile page
        Navigator.pop(context, true);
        return;
      }
      
      // For diagnosis use, navigate to DiagnosisChatScreen as before
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => DiagnosisChatScreen(
            faceImage: imageFile,
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _isCapturing = false;
        _hasError = true;
        _errorMessage = 'Error capturing image: $e';
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    // Lock screen to portrait mode
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: _hasError 
          ? _buildErrorScreen() 
          : (!_isCameraInitialized 
              ? _buildLoadingScreen() 
              : _buildCameraScreen()),
    );
  }

  Widget _buildErrorScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              _errorMessage,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Go Back'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                setState(() {
                  _hasError = false;
                });
                _requestPermissions().then((_) => _initializeCamera());
              },
              child: const Text('Try Again', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.white),
          SizedBox(height: 16),
          Text(
            'Initializing camera...',
            style: TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraScreen() {
    return Stack(
      children: [
        // Camera preview
        SizedBox.expand(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: _controller!.value.previewSize!.height,
              height: _controller!.value.previewSize!.width,
              child: CameraPreview(_controller!),
            ),
          ),
        ),
        
        // Face guide overlay
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 250,
                height: 320, // Oval shape for face
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _isFaceDetected && _isGoodPosition && _isGoodBrightness && _isFacingFront
                        ? Colors.green
                        : Colors.white,
                    width: 2
                  ),
                  borderRadius: BorderRadius.circular(160),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '枠に顔を合わせてください \n'
                '下記にすべてチェックが付くと \n'
                '自動で撮影されます。',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),

              const Text('すべてにチェックが付くように撮影場所や\n'
                  'カメラ位置を調整してください。',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 40),

              // Row of ticks that turn yellow when conditions are met
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildTickIndicator("明るさ", _isFaceDetected),//face detected
                  _buildTickIndicator("ポジション", _isGoodPosition),
                  _buildTickIndicator("正面", _isGoodBrightness),//brightness
                  _buildTickIndicator("ポジション", _isFacingFront),//facing front
                ],
              ),


              


            ],
          ),
        ),
        
        // Top bar with close button
        Positioned(
          top: 40,
          right: 16,
          child: IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 30),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        
        // Bottom controls
        Positioned(
          bottom: 40,
          left: 0,
          right: 0,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
             mainAxisAlignment: MainAxisAlignment.end,
             children: [
            
            
               IconButton(
                 icon: const Icon(Icons.flip_camera_ios, color: Colors.white, size: 30),
                 onPressed: _switchCamera,
               ),
             ],
                            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildStatusIndicator(String label, bool isActive) {
    return Row(
      children: [
        Icon(
          isActive ? Icons.check_circle : Icons.circle_outlined,
          color: isActive ? Colors.green : Colors.white,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.green : Colors.white,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildCompactStatusIndicator(IconData icon, bool isActive) {
    return Column(
      children: [
        Icon(
          isActive ? icon : Icons.circle,
          color: isActive ? Colors.green : Colors.white,
          size: 24,
        ),
        const SizedBox(height: 4),
        Icon(
          isActive ? Icons.check_circle : Icons.circle_outlined,
          color: isActive ? Colors.green : Colors.white,
          size: 16,
        ),
      ],
    );
  }

  Widget _buildTickIndicator(String label, bool isActive) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8.0),
    child: Column(
      children: [
        Icon(
          Icons.check,  // Simple checkmark without circle
          color: isActive ? Colors.yellow : Colors.white,
          size: 24,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.yellow : Colors.white,
            fontSize: 12,
          ),
        ),
      ],
    ),
  );
}
}
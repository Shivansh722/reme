import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:reme/src/widgets/customButton.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  File? _image;
  final ImagePicker _picker = ImagePicker();

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
              // Here you would typically send the image for processing
              _processImage();
            },
            child: const Text('Proceed'),
          ),
        ],
      ),
    );
  }

  void _processImage() {
    // This is where you would send the image for processing
    // For now, just show a snackbar indicating success
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Image processing started...'),
        duration: Duration(seconds: 2),
      ),
    );
    
    // In a real app, you might navigate to a results screen
    // or show a loading indicator while the image is processed
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
          ),
        ),
      ),
    );
  }
}
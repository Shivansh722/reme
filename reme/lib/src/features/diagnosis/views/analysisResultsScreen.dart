import 'dart:io';
import 'package:flutter/material.dart';
import 'package:reme/src/widgets/customButton.dart';

class AnalysisResultsScreen extends StatelessWidget {
  final File? faceImage;
  final String analysisResult;

  const AnalysisResultsScreen({
    super.key,
    required this.faceImage,
    required this.analysisResult,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Skin Analysis Results'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (faceImage != null) ...[
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    faceImage!,
                    height: 250,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
            
            const Text(
              'Your Skin Analysis',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            Text(
              analysisResult,
              style: const TextStyle(fontSize: 16),
            ),
            
            const SizedBox(height: 32),
            
            Custombutton(
              text: 'Back to Home',
              onTap: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}
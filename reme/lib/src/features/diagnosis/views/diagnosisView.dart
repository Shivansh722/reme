import 'package:flutter/material.dart';
import 'package:reme/src/widgets/customButton.dart';
import 'package:reme/src/features/diagnosis/views/cameraScreen.dart';

class DiagnosisView extends StatelessWidget {
  const DiagnosisView({super.key});

  // Method to handle camera diagnosis
  void cameraDiagnosis(BuildContext context) {
    // Navigate to camera screen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CameraScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text('Diagnosis'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'lib/assets/images/img.png',
                  width: 200,
                  height: 200,
                ),
                const SizedBox(height: 60),
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
                  text: 'Start Diagnosis',
                  onTap: () => cameraDiagnosis(context),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:reme/src/widgets/customButton.dart';

class DiagnosisView extends StatelessWidget {
  const DiagnosisView({super.key});


  // // Method to handle camera diagnosis
  // void cameraDiagnosis() {
  //   // For now, this is a placeholder for camera functionality
  //   // You should create a CameraScreen widget and import it
  //   debugPrint('Opening camera for diagnosis');
      
  //   // Navigate to camera screen
  //   Navigator.of(context).push(
  //     MaterialPageRoute(
  //     builder: (context) => const CameraScreen(), // Create this widget
  //     ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text('Diagnosis'),
      backgroundColor: Colors.transparent,
      elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'lib/assets/images/img.png',
              width: 200,
              height: 200,
            ),
            const SizedBox(height: 60),

          Custombutton(text: 'Start Diagnosis', onTap:() {} )
          ],
        ),
      ),
    );
  }
}
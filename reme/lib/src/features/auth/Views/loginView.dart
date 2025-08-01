import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_line_sdk/flutter_line_sdk.dart';
import 'package:reme/src/features/auth/services/authService.dart';
import 'package:reme/src/features/diagnosis/views/diagnosisView.dart';
import 'package:reme/src/features/home/views/homeView.dart';
import 'package:reme/src/helpers/helper_functions.dart';
import 'package:reme/src/widgets/customButton.dart';
import 'package:reme/src/widgets/customTextField.dart';
import 'package:reme/src/widgets/squareTile.dart';

class Loginview extends StatefulWidget {
  // Callback function to handle tap events
  final void Function() onTap;
  final Map<String, dynamic>? pendingAnalysisData;

  const Loginview({super.key, required this.onTap, this.pendingAnalysisData});

  @override
  State<Loginview> createState() => _LoginviewState();
}

class _LoginviewState extends State<Loginview> {
  //text controllers
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  
  // Create an instance of the auth service
  final Authservice _authService = Authservice();

  //login method
  void login() async {
    //show loading indicator
    showDialog(
      context: context,
      builder: (context) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      }
    );

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );

      //pop loading circle
      if (context.mounted) Navigator.pop(context);

      // Always go to HomeviewMain with detailed analysis tab
      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeviewMain(
              initialTab: 3,
              faceImage: widget.pendingAnalysisData?['faceImage'],
              analysisResult: widget.pendingAnalysisData?['analysisResult'],
              scores: widget.pendingAnalysisData?['scores'],
            ),
          ),
        );
      }
    } on FirebaseAuthException catch (e) { 
      if (context.mounted) Navigator.pop(context);
      //show error message using our helper function
      showErrorMessage(context, e.code);
    }
  }
  
  // LINE login method
  void loginWithLine() async {
    print("Starting LINE login process...");
    
    //show loading indicator
    showDialog(
      context: context,
      builder: (context) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      }
    );

    try {
      print("Calling LINE SDK login method...");
      final result = await LineSDK.instance.login();
      print("LINE SDK login completed successfully");
      
      // Pop loading circle
      if (context.mounted) {
        Navigator.pop(context);
      }
      
      // Get user details if needed
      final userId = result.userProfile?.userId;
      final displayName = result.userProfile?.displayName;
      final pictureUrl = result.userProfile?.pictureUrl;
      
      print("LINE Login Success - User ID: $userId, Name: $displayName");
      
      // Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('LINE Login Success! User: $displayName'),
            duration: Duration(seconds: 3),
          ),
        );
      }
      
      // If there's pending analysis data, the AuthGate will handle navigation
      // Otherwise, normal flow continues
      
    } on PlatformException catch (e) {
      print("LINE SDK login error: ${e.toString()}");
      // Hide loading indicator
      if (context.mounted) Navigator.pop(context);
      
      // Show error message
      if (context.mounted) _authService.showErrorDialog(context, e.toString());
    } catch (e) {
      print("Unexpected error during LINE login: ${e.toString()}");
      // Handle any other errors
      if (context.mounted) Navigator.pop(context);
      if (context.mounted) _authService.showErrorDialog(context, e.toString());
    }
  }

  void startDiagnosis() async {
    // Show loading indicator
    showDialog(
      context: context,
      builder: (context) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      }
    );

    // Hide loading indicator
    if (context.mounted) {
      Navigator.pop(context);
    }

    // Navigate to the diagnosis screen
    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const DiagnosisView(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Stack(
        children: [
          // Main content
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  //logo
                
                  //app name
                  const Text('R E: M E ', style: TextStyle(
                    fontSize: 32,
                  )),

                  const SizedBox(height: 20),

                  // Show message if there's pending analysis data
                  if (widget.pendingAnalysisData != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info, color: Colors.blue[700]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Sign in to view your detailed skin analysis results',
                              style: TextStyle(
                                color: Colors.blue[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // //email
                  Customtextfield(
                    hintText: 'Email',
                    obscureText: false,
                    controller: emailController,
                  ),

                  const SizedBox(height: 10),
              
              
                  //password
                  Customtextfield(
                    hintText: 'Password',
                    obscureText: true,
                    controller: passwordController,
                  ),

                  const SizedBox(height: 10),
              
                  //forgot password
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text('Forgot Password?',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.inversePrimary,
                          fontSize: 16,
                        ),),
                    ],
                  ),
              
                  const SizedBox(height: 24),
                  //login button
                  Custombutton(text: 'Login', onTap: login),
              
                  const SizedBox(height: 10),

                  // Only show "Start Diagnosis" button if there's no pending analysis data
                  if (widget.pendingAnalysisData == null)
                    Custombutton(text: 'Start Diagnosis', onTap: startDiagnosis),
                  
                  const SizedBox(height: 24),

                  // Text divider
                  Row(
                    children: [
                      Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          "Or continue with",
                          style: TextStyle(color: Theme.of(context).colorScheme.inversePrimary),
                        ),
                      ),
                      Expanded(child: Divider()),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Social login buttons row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                    Squaretile(
                        imagePath: 'lib/assets/images/google_logo.png',
                        onTap: () => Authservice().signInWithGoogle(),
                         ),
                       const SizedBox(width: 25),
                      // LINE login button
                      GestureDetector(
                        onTap: loginWithLine,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.white,
                          ),
                          child: Image.asset(
                            'lib/assets/images/line_logo.png', // Make sure this image exists in your assets
                            height: 40,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // Registration link at bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 80,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Don\'t have an account? ',
                  style: TextStyle(
                    fontSize: 16,
                  ),
                ),
                GestureDetector(
                  onTap: widget.onTap, 
                  child: Text('Register here',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.tertiary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
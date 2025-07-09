import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:reme/src/features/auth/services/authService.dart';
import 'package:reme/src/features/home/views/homeView.dart';
import 'package:reme/src/helpers/helper_functions.dart';

class SignUpScreen extends StatelessWidget {
  // Controllers for sign up
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  
  // Additional controllers for login
  final TextEditingController loginEmailController = TextEditingController();
  final TextEditingController loginPasswordController = TextEditingController();
  
  final Authservice _authService = Authservice();
  final Map<String, dynamic>? pendingAnalysisData;
  
  SignUpScreen({Key? key, this.pendingAnalysisData}) : super(key: key);

  // Login with email/password
  void loginUser(BuildContext context) async {
    // Show loading indicator
    showDialog(
      context: context,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Sign in the user with Firebase - use login controllers here
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: loginEmailController.text,
        password: loginPasswordController.text,
      );
      
      // Dismiss loading indicator
      if (context.mounted) Navigator.pop(context);
      
      // Navigate to home view
      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeviewMain(
              initialTab: 3,
              faceImage: pendingAnalysisData?['faceImage'],
              analysisResult: pendingAnalysisData?['analysisResult'],
              scores: pendingAnalysisData?['scores'],
            ),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      // Dismiss loading indicator
      if (context.mounted) Navigator.pop(context);
      
      // Show error message
      if (context.mounted) {
        _authService.showErrorDialog(context, e.message ?? 'Login failed');
      }
    }
  }

  // Google Sign In
  void signInWithGoogle(BuildContext context) async {
    // Show loading indicator
    showDialog(
      context: context,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Use the existing auth service for Google sign-in
      await _authService.signInWithGoogle();
      
      // Dismiss loading indicator
      if (context.mounted) Navigator.pop(context);
      
      // Firebase Auth state changes will handle navigation via AuthGate
      
    } catch (e) {
      // Dismiss loading indicator
      if (context.mounted) Navigator.pop(context);
      
      // Show error message
      if (context.mounted) {
        _authService.showErrorDialog(context, 'Google login failed: ${e.toString()}');
      }
    }
  }

  // LINE Sign In
  void signInWithLine(BuildContext context) async {
    // Show loading indicator
    showDialog(
      context: context,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Use the existing auth service for LINE sign-in
      await _authService.signInWithLine();
      
      // Dismiss loading indicator
      if (context.mounted) Navigator.pop(context);
      
      // LINE login doesn't automatically update Firebase Auth state
      // So we'd need to handle navigation manually or implement custom Firebase Auth
      
    } catch (e) {
      // Dismiss loading indicator
      if (context.mounted) Navigator.pop(context);
      
      // Show error message
      if (context.mounted) {
        _authService.showErrorDialog(context, 'LINE login failed: ${e.toString()}');
      }
    }
  }

  Widget buildTextField(String label, String hint, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: label == 'Password' || label == 'Confirm Password', // Enable obscureText for password fields
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Color(0xFFF6F6F6),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        SizedBox(height: 16),
      ],
    );
  }

  Widget buildButton(String text, VoidCallback onPressed, {Color color = const Color(0xFFEB7B8F), Color textColor = Colors.white}) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(text, style: TextStyle(color: textColor, fontSize: 16)),
      ),
    );
  }

  Widget buildLoginButtonWithIcon(String text, IconData icon, Color color, Color textColor, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        icon: Icon(icon, color: textColor),
        label: Text(text, style: TextStyle(color: textColor)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: onPressed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 56),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sign Up', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 24),
      
            // Sign up fields
            buildTextField('Email', 'Enter your email address', emailController),
            buildTextField('Password', 'Enter your password', passwordController),
            buildTextField('Confirm Password', 'Confirm your password', confirmPasswordController),
      
            // Terms and privacy policy
            Text.rich(
              TextSpan(
                text: 'Terms of Service',
                style: TextStyle(color: Colors.blue, fontSize: 12),
                children: [
                  TextSpan(text: ' and '),
                  TextSpan(text: 'Privacy Policy', style: TextStyle(color: Colors.blue)),
                  TextSpan(text: '. Please proceed to register or login after agreement.'),
                ],
              ),
            ),
            SizedBox(height: 16),
            buildButton('Register New Account', () {
              // Check if passwords match
              if (passwordController.text != confirmPasswordController.text) {
              _authService.showErrorDialog(context, 'Passwords do not match');
              return;
              }
              
              // Show loading indicator
              showDialog(
              context: context,
              builder: (context) => const Center(child: CircularProgressIndicator()),
              );
              
              // Create user with email and password
              FirebaseAuth.instance.createUserWithEmailAndPassword(
              email: emailController.text,
              password: passwordController.text,
              ).then((userCredential) {
              // Dismiss loading indicator
              if (context.mounted) Navigator.pop(context);
              
              // Navigate to home view
              if (context.mounted) {
                Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => HomeviewMain(
                  initialTab: 3,
                  faceImage: pendingAnalysisData?['faceImage'],
                  analysisResult: pendingAnalysisData?['analysisResult'],
                  scores: pendingAnalysisData?['scores'],
                  ),
                ),
                );
              }
              }).catchError((e) {
              // Dismiss loading indicator
              if (context.mounted) Navigator.pop(context);
              
              // Show error message
              if (context.mounted && e is FirebaseAuthException) {
                _authService.showErrorDialog(context, e.message ?? 'Registration failed');
              } else if (context.mounted) {
                _authService.showErrorDialog(context, 'Registration failed: ${e.toString()}');
              }
              });
            }),
      
            SizedBox(height: 32),
            Center(child: Text('Already have an account?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
            SizedBox(height: 16),
      
            ElevatedButton(
              onPressed: () => signInWithGoogle(context),
              style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('lib/assets/images/google_logo.png', height: 24, width: 24),
                SizedBox(width: 12),
                Text('Login with Google', style: TextStyle(color: Colors.black, fontSize: 16)),
              ],
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => signInWithLine(context),
              style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('lib/assets/images/line_logo_white.png', height: 24, width: 24),
                SizedBox(width: 12),
                Text('Login with LINE', style: TextStyle(color: Colors.white, fontSize: 16)),
              ],
              ),
            ),
            SizedBox(height: 32),
      
            // Login fields - now using separate controllers
            buildTextField('Email', 'Enter your email address', loginEmailController),
            buildTextField('Password', 'Enter your password', loginPasswordController),
      
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () => loginUser(context),
                icon: Icon(Icons.mail_outline, color: Colors.pinkAccent),
                label: Text('Login', style: TextStyle(color: Colors.pinkAccent)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.pinkAccent),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

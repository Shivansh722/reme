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
      // First ensure context is still valid
      if (!context.mounted) return;

      // Add error handling for navigation
      try {
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
      } catch (e) {
        print("Navigation error: $e");
        // Show fallback error to user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("ホーム画面への移動中にエラーが発生しました")),
        );
      }
    } on FirebaseAuthException catch (e) {
      // Dismiss loading indicator
      if (context.mounted) Navigator.pop(context);
      
      // Show error message
      if (context.mounted) {
        _authService.showErrorDialog(context, e.message ?? 'ログインに失敗しました');
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
      
      // Explicitly navigate to home view after successful sign-in
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
    } catch (e) {
      // Dismiss loading indicator
      if (context.mounted) Navigator.pop(context);
      
      // Show error message with more details
      if (context.mounted) {
        _authService.showErrorDialog(context, 'Googleログインに失敗しました: ${e.toString()}');
      }
      print("Google login error details: $e");
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
        _authService.showErrorDialog(context, 'LINEログインに失敗しました: ${e.toString()}');
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
          obscureText: label == 'パスワード' || label == 'パスワード確認', // Enable obscureText for password fields
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
            Text('アカウント登録', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 24),
      
            // Sign up fields
            buildTextField('メールアドレス', 'メールアドレスを入力してください', emailController),
            buildTextField('パスワード', 'パスワードを入力してください', passwordController),
            buildTextField('パスワード確認', 'パスワードを再入力してください', confirmPasswordController),
      
            // Terms and privacy policy
            Text.rich(
              TextSpan(
                text: '利用規約',
                style: TextStyle(color: Colors.blue, fontSize: 12),
                children: [
                  TextSpan(text: ' および '),
                  TextSpan(text: 'プライバシーポリシー', style: TextStyle(color: Colors.blue)),
                  TextSpan(text: 'に同意の上、登録またはログインしてください。'),
                ],
              ),
            ),
            SizedBox(height: 16),
            buildButton('新規アカウント登録', () {
              // Check if passwords match
              if (passwordController.text != confirmPasswordController.text) {
                _authService.showErrorDialog(context, 'パスワードが一致しません');
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
              ).then((userCredential) async {
                // Save user data to Firestore
                await _authService.saveEmailPasswordUserData(
                  userCredential.user!,
                  null, // You could add a name field to your form if desired
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
              }).catchError((e) {
                // Dismiss loading indicator
                if (context.mounted) Navigator.pop(context);
                
                // Show error message
                if (context.mounted && e is FirebaseAuthException) {
                  _authService.showErrorDialog(context, e.message ?? '登録に失敗しました');
                } else if (context.mounted) {
                  _authService.showErrorDialog(context, '登録に失敗しました: ${e.toString()}');
                }
              });
            }),
      
            SizedBox(height: 32),
            Center(child: Text('すでにアカウントをお持ちの方', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
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
                  Text('Googleでログイン', style: TextStyle(color: Colors.black, fontSize: 16)),
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
                Text('LINEでログイン', style: TextStyle(color: Colors.white, fontSize: 16)),
              ],
              ),
            ),
            SizedBox(height: 32),
      
            // Login fields - now using separate controllers
            buildTextField('メールアドレス', 'メールアドレスを入力してください', loginEmailController),
            buildTextField('パスワード', 'パスワードを入力してください', loginPasswordController),
      
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () => loginUser(context),
                icon: Icon(Icons.mail_outline, color: Colors.pinkAccent),
                label: Text('ログイン', style: TextStyle(color: Colors.pinkAccent)),
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

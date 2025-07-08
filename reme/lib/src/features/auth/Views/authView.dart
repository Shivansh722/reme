import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:reme/src/features/auth/services/authService.dart';
import 'package:reme/src/features/home/views/homeView.dart';
import 'package:reme/src/helpers/helper_functions.dart';

class SignUpScreen extends StatelessWidget {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final Authservice _authService = Authservice();
  final Map<String, dynamic>? pendingAnalysisData;
  
  SignUpScreen({Key? key, this.pendingAnalysisData}) : super(key: key);

  // Registration with email/password
  void registerUser(BuildContext context) async {
    // Show loading indicator
    showDialog(
      context: context,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Register the user with Firebase
      UserCredential? userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
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
        _authService.showErrorDialog(context, e.message ?? 'Registration failed');
      }
    }
  }

  // Login with email/password
  void loginUser(BuildContext context) async {
    // Show loading indicator
    showDialog(
      context: context,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Sign in the user with Firebase
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
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
      
      // Firebase Auth state changes will handle navigation via AuthGate
      
    } catch (e) {
      // Dismiss loading indicator
      if (context.mounted) Navigator.pop(context);
      
      // Show error message
      if (context.mounted) {
        _authService.showErrorDialog(context, 'Googleログインに失敗しました: ${e.toString()}');
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
          obscureText: label == 'パスワード', // Enable obscureText for password fields
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

  Widget buildButton(String text, VoidCallback onPressed, {Color color = Colors.pinkAccent, Color textColor = Colors.white}) {
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('会員登録', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              SizedBox(height: 24),

              buildTextField('メールアドレス', 'メールアドレスを入力して下さい', emailController),
              buildTextField('パスワード', 'パスワードを入力して下さい', passwordController),

              Text.rich(
                TextSpan(
                  text: '利用規約',
                  style: TextStyle(color: Colors.blue, fontSize: 12),
                  children: [
                    TextSpan(text: '及び'),
                    TextSpan(text: 'プライバシーポリシー', style: TextStyle(color: Colors.blue)),
                    TextSpan(text: 'に同意の上、登録又はログインへお進みください。'),
                  ],
                ),
              ),
              SizedBox(height: 16),
              buildButton('新規会員登録', () => registerUser(context)),

              SizedBox(height: 32),
              Center(child: Text('アカウントをお持ちの方', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
              SizedBox(height: 16),

              buildLoginButtonWithIcon('Googleログイン', Icons.g_mobiledata, Colors.white, Colors.black, 
                () => signInWithGoogle(context)),
              SizedBox(height: 16),
              buildLoginButtonWithIcon('LINEログイン', Icons.chat_bubble_outline, Colors.green, Colors.white,
                () => signInWithLine(context)),
              SizedBox(height: 32),

              buildTextField('メールアドレス', 'メールアドレスを入力して下さい', emailController),
              buildTextField('パスワード', 'パスワードを入力して下さい', passwordController),

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
      ),
    );
  }
}

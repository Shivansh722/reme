import 'package:flutter/material.dart';



class SignUpScreen extends StatelessWidget {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  Widget buildTextField(String label, String hint, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        TextField(
          controller: controller,
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

  Widget buildLoginButtonWithIcon(String text, IconData icon, Color color, Color textColor) {
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
        onPressed: () {},
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
              buildButton('新規会員登録', () {}),

              SizedBox(height: 32),
              Center(child: Text('アカウントをお持ちの方', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
              SizedBox(height: 16),

              buildLoginButtonWithIcon('Googleログイン', Icons.g_mobiledata, Colors.white, Colors.black),
              SizedBox(height: 16),
              buildLoginButtonWithIcon('LINEログイン', Icons.chat_bubble_outline, Colors.green, Colors.white),
              SizedBox(height: 32),

              buildTextField('メールアドレス', 'メールアドレスを入力して下さい', emailController),
              buildTextField('パスワード', 'パスワードを入力して下さい', passwordController),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () {},
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

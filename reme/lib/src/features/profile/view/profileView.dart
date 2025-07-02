import 'package:flutter/material.dart';


class MyPageScreen extends StatefulWidget {
  const MyPageScreen({super.key});

  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  bool notificationsEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // Remove the SafeArea for consistency with other screens
      body: Column(
        children: [
          // Add padding at the top to compensate for status bar
          SizedBox(height: MediaQuery.of(context).padding.top),
          const SizedBox(height: 30),
          const Center(
            child: Text(
              'マイページ',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 20),
          const CircleAvatar(
            radius: 45,
            backgroundImage: AssetImage('lib/assets/images/profile.png'), // Replace with your asset path
          ),
          const SizedBox(height: 30),
          buildInfoRow('名前', '吉永久百合'),
          const SizedBox(height: 16),
          buildInfoRow('メール\nアドレス', 'cgtieruajk@gmail.com'),
          const SizedBox(height: 16),
          buildInfoRow('パスワード', '＊＊＊＊＊＊＊＊'),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Row(
              children: [
                const Text(
                  '通知設定',
                  style: TextStyle(fontSize: 16),
                ),
              SizedBox(width: 16),
                Switch(
                  value: notificationsEnabled,
                  onChanged: (val) {
                    setState(() {
                      notificationsEnabled = val;
                    });
                  },
                  activeColor: Colors.white,
                  activeTrackColor: Colors.pink.shade300,
                  inactiveTrackColor: Colors.grey.shade300,
                  inactiveThumbColor: Colors.white,
                ),
              ],
            ),
          ),
          const Spacer(),
          Divider(height: 1, color: Colors.grey.shade300),
          ListTile(
            title: const Text('利用規約'),
            trailing: Icon(Icons.chevron_right, color: Colors.grey.shade300),
            onTap: () {},
          ),
          Divider(height: 1, color: Colors.grey.shade300),
          ListTile(
            title: const Text('プライバシーポリシー'),
            trailing: Icon(Icons.chevron_right, color: Colors.grey.shade300),
            onTap: () {},
          ),
          Divider(height: 1, color: Colors.grey.shade300),
          ListTile(
            title: const Text('ログアウト'),
           
          ),
        ],
      ),
    );
  }

  Widget buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}

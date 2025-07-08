import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:reme/src/features/auth/Views/authGate.dart'; // Add this import
import 'package:reme/src/features/profile/services/profileServices.dart';

import 'package:reme/src/features/diagnosis/views/custom_camera_screen.dart';

// Import Authgate if it's in a different file
class MyPageScreen extends StatefulWidget {
  const MyPageScreen({super.key});

  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  bool notificationsEnabled = false;
  String userEmail = 'Loading...'; // Default value while loading
  String? profileImagePath;

  @override
  void initState() {
    super.initState();
    // Get the current user's email when the widget initializes
    getCurrentUserEmail();
    // Load profile image
    loadProfileImage();
  }

  // Load profile image path
  Future<void> loadProfileImage() async {
    final path = await ProfileImageService.getProfileImagePath();
    if (path != null) {
      setState(() {
        profileImagePath = path;
      });
    }
  }

  // Method to capture a new profile image
  Future<void> captureProfileImage() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CustomCameraScreen(forProfileImage: true),
      ),
    );

    // If result is true, reload the profile image
    if (result == true) {
      loadProfileImage();
    }
  }

  // Method to get current user's email from Firebase
  void getCurrentUserEmail() {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null && currentUser.email != null) {
      setState(() {
        userEmail = currentUser.email!;
      });
    } else {
      setState(() {
        userEmail = 'Not signed in';
      });
    }
  }

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
          
          // Profile image with edit option
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              // Profile image
              CircleAvatar(
                radius: 45,
                backgroundImage: profileImagePath != null
                    ? FileImage(File(profileImagePath!))
                    : const AssetImage('lib/assets/images/profile.png') as ImageProvider,
              ),
              
              // Edit button
              GestureDetector(
                onTap: captureProfileImage,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.pink.shade300,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.edit,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          buildInfoRow('名前', '吉永久百合'),
          const SizedBox(height: 16),
          buildInfoRow('メール\nアドレス', userEmail), // Use the current user's email
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
            onTap: () async {
              // Show confirmation dialog
              bool confirm = await showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('ログアウト'),
                    content: const Text('本当にログアウトしますか？'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('キャンセル'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('ログアウト'),
                      ),
                    ],
                  );
                },
              ) ?? false;
              
              if (confirm && context.mounted) {
                try {
                  await FirebaseAuth.instance.signOut();
                  // Clear user data in the state
                  setState(() {
                    userEmail = 'Not signed in';
                  });
                  
                  // Navigate to AuthGate after sign out
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (context) => const Authgate(),
                      ),
                      (route) => false,
                    );
                  }
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('ログアウトしました')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('ログアウトに失敗しました: ${e.toString()}')),
                  );
                }
              }
            },
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

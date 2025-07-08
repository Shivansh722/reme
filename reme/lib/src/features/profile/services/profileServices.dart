import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileImageService {
  static const String _profileImagePathKey = 'profile_image_path';
  
  // Save profile image and return the path where it's saved
  static Future<String> saveProfileImage(File imageFile) async {
    try {
      final String userId = FirebaseAuth.instance.currentUser?.uid ?? 'default';
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String imagePath = '${appDir.path}/profile_$userId.jpg';
      
      // Copy the image to the new location
      final File localImage = await imageFile.copy(imagePath);
      
      // Save the path in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_profileImagePathKey, imagePath);
      
      return imagePath;
    } catch (e) {
      print('Error saving profile image: $e');
      rethrow;
    }
  }
  
  // Save diagnosis image as profile image too
  static Future<void> useDiagnosisImageAsProfile(File imageFile) async {
    try {
      await saveProfileImage(imageFile);
    } catch (e) {
      print('Error saving diagnosis image as profile: $e');
    }
  }
  
  // Get the current profile image path
  static Future<String?> getProfileImagePath() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_profileImagePathKey);
    } catch (e) {
      print('Error getting profile image path: $e');
      return null;
    }
  }
}
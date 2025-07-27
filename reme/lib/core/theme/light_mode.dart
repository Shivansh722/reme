
import 'package:flutter/material.dart';

ThemeData lightMode = ThemeData(
  brightness: Brightness.light,
  colorScheme: ColorScheme.light(
    primary: Color(0xFFEB7B8F), // Primary color
    secondary: Colors.grey.shade400, // Secondary color
    background: Colors.white, // Background color
    inversePrimary: Colors.grey.shade800, // Inverse primary color
    onBackground: Colors.black, 
    tertiary: Colors.blue,// Text color on background
    onPrimary: Colors.green.shade600, // Text color on primary
    
  ),
  textTheme: ThemeData.light().textTheme.apply(
    bodyColor: Colors.grey.shade800, // Body text color
    displayColor: Colors.black, // Display text color
  ),
 

);
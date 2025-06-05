
import 'package:flutter/material.dart';

ThemeData lightMode = ThemeData(
  brightness: Brightness.light,
  colorScheme: ColorScheme.light(
    primary: Colors.grey.shade200, // Primary color
    secondary: Colors.grey.shade400, // Secondary color
    background: Colors.grey.shade300, // Background color
    inversePrimary: Colors.grey.shade800, // Inverse primary color
    onBackground: Colors.black, // Text color on background
  ),
  textTheme: ThemeData.light().textTheme.apply(
    bodyColor: Colors.grey.shade800, // Body text color
    displayColor: Colors.black, // Display text color
  ),
 

);
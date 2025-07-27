import 'package:flutter/material.dart';

class CustomCircularProgress extends StatelessWidget {
  final double progress; // between 0 and 100
  final Color? color; // Add this parameter

  const CustomCircularProgress({
    super.key, 
    required this.progress, 
    this.color, // Optional color parameter
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
     
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: progress / 100,
            strokeWidth: 4,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(
              color ?? Color(0xDECDB892)), // Use provided color or default beige-ish
          ),
          Text(
            progress.toInt().toString(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w500,
              color: color ?? Colors.black87, // Use provided color or default black
            ),
          ),
        ],
      ),
    );
  }
}

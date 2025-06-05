import 'package:flutter/material.dart';

class Custombutton extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget child;
  final double width;
  final double height;

  const Custombutton({
    super.key,
    required this.onPressed,
    required this.child,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 196, 194, 197),
        borderRadius: BorderRadius.circular(24),
      ),
      child: TextButton(
        onPressed: onPressed,
        child: DefaultTextStyle.merge(
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
          ),
          child: child,
        ),
      ),
    );
  }
}
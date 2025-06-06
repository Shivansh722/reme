import 'package:flutter/material.dart';

class Squaretile extends StatelessWidget {

  // Path to the image asset
  final String imagePath;
  final void Function()? onTap;

  const Squaretile({super.key, required this.imagePath, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.primary,
            width: 1.5,
          ),
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Image.asset(
          imagePath,
          height: 60,
        )
      ),
    );
  }
}
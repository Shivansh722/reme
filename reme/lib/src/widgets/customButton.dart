import 'package:flutter/material.dart';

class Custombutton extends StatelessWidget {
  final String text;
  final void Function()? onTap;

  const Custombutton({
    super.key,
    required this.text,
    required this.onTap,
  });



  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(


        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(24),
        ),
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: Theme.of(context).colorScheme.inversePrimary,
              fontSize: 18,
             
            ),
          ),
        ),
      ),
    );
  }
}
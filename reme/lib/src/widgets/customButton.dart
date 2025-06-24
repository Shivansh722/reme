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

        width: 310,
        height: 50,


        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(24),
        ),
       
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
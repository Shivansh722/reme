import 'package:flutter/material.dart';

void showErrorMessage(BuildContext context, String message) {
  showDialog(context: context, builder: (context) {
    return AlertDialog(
      title: const Text("Error"),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text("OK"),
        ),
      ],
    );
  }
  );
}
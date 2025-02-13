import 'package:flutter/material.dart';

class MyTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  const MyTextField({super.key, required this.controller, required this.hintText, required this.obscureText });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: TextStyle(fontSize: 21),
      decoration: InputDecoration(
        enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.blue),
        ),
        fillColor: Colors.grey.shade100,
        filled: true,
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey.shade300),
      ),
    );
  }
}

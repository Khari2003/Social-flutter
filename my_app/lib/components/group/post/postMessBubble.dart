import 'package:flutter/material.dart';

class PostMessBubble extends StatelessWidget {
  final String message;
  final String email;

  const PostMessBubble({super.key, required this.message, required this.email});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Color.fromARGB(255, 74, 74, 76),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            email, // Hiển thị email người gửi
            style: const TextStyle(fontSize: 12, color: Color.fromARGB(255,226,229,233), fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4), // Khoảng cách giữa email và tin nhắn
          Text(
            message, // Hiển thị tin nhắn
            style: const TextStyle(fontSize: 16, color: Color.fromARGB(255,226,229,233)),
          ),
        ],
      ),
    );
  }
}

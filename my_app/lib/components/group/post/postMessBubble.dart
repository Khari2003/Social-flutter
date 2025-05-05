import 'package:flutter/material.dart';

class PostMessBubble extends StatelessWidget {
  final String message;
  final String email;

  const PostMessBubble({super.key, required this.message, required this.email});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: const Color(0xFF3A3A3A),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            email,
            style: TextStyle(fontSize: 12, color: Colors.grey[400], fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            message,
            style: const TextStyle(fontSize: 14, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
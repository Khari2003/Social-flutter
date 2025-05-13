import 'package:flutter/material.dart';

class ChatBubble extends StatelessWidget {
  final String message;
  final bool isSender;

  const ChatBubble({
    super.key,
    required this.message,
    this.isSender = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        color: isSender ? Colors.blueAccent : const Color(0xFF3A3A3A),
        borderRadius: BorderRadius.circular(16).copyWith(
          topLeft: isSender ? const Radius.circular(16) : const Radius.circular(4),
          topRight:
              isSender ? const Radius.circular(4) : const Radius.circular(16),
        ),
      ),
      child: Text(
        message,
        style: const TextStyle(
          fontSize: 16,
          color: Colors.white,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }
}
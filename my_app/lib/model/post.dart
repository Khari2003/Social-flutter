import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  final String userId;
  final String userEmail;
  final String content;
  final String? imageUrl;
  final Timestamp timestamp;
  final List<String> likes;
  final List<Map<String, dynamic>> comments;

  Post({
    required this.userId,
    required this.userEmail,
    required this.content,
    this.imageUrl,
    required this.timestamp,
    required this.likes,
    required this.comments,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userEmail': userEmail,
      'content': content,
      'imageUrl': imageUrl,
      'timestamp': timestamp,
      'likes': likes,
      'comments': comments,
    };
  }
}
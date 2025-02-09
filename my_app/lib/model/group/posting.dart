  import 'package:cloud_firestore/cloud_firestore.dart';

  class Posting {
    final String postId;
    final String groupId;
    final String userId;
    final String content;
    final Timestamp timestamp;
    final List<String> likes;
    final List<String> comments;
    final List<String>? imageUrls; // List of image URLs
    final String? videoUrl; // URL for a video
    final String? voiceChatUrl; // URL for a voice chat

    Posting({
      required this.postId,
      required this.groupId,
      required this.userId,
      required this.content,
      required this.timestamp,
      List<String>? likes,
      List<String>? comments,
      this.imageUrls,
      this.videoUrl,
      this.voiceChatUrl,
    })  : this.likes = likes ?? [],
          this.comments = comments ?? [];

    // Convert Posting to a Map (for Firestore)
    Map<String, dynamic> toMap() {
      return {
        'postId': postId,
        'groupId': groupId,
        'userId': userId,
        'content': content,
        'timestamp': timestamp,
        'likes': likes,
        'comments': comments,
        'imageUrls': imageUrls,
        'videoUrl': videoUrl,
        'voiceChatUrl': voiceChatUrl,
      };
    }

    // Create a Posting object from a Firestore document
    factory Posting.fromMap(Map<String, dynamic> data) {
      return Posting(
        postId: data['postId'],
        groupId: data['groupId'],
        userId: data['userId'],
        content: data['content'],
        timestamp: data['timestamp'],
        likes: List<String>.from(data['likes'] ?? []),
        comments: List<String>.from(data['comments'] ?? []),
        imageUrls: List<String>.from(data['imageUrls'] ?? []),
        videoUrl: data['videoUrl'],
        voiceChatUrl: data['voiceChatUrl'],
      );
    }
  }
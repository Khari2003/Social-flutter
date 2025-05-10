import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String senderId;
  final String senderEmail;
  final String receiverId; // Empty if it's a group message
  final String message;
  final Timestamp timestamp;
  final String type; // 'group', 'private', or 'share_post'
  final List<String>? imageUrls; // List of image URLs
  final String? videoUrl; // URL for a video
  final String? voiceChatUrl; // URL for a voice chat
  final String? postId; // ID of the shared post (for share_post type)
  final String? originalGroupId; // Group ID of the shared post (for share_post type)

  Message({
    required this.senderId,
    required this.senderEmail,
    required this.receiverId,
    required this.message,
    required this.timestamp,
    required this.type,
    this.imageUrls,
    this.videoUrl,
    this.voiceChatUrl,
    this.postId,
    this.originalGroupId,
  });

  // Convert Message object to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderEmail': senderEmail,
      'receiverId': receiverId,
      'message': message,
      'timestamp': timestamp,
      'type': type,
      'imageUrls': imageUrls,
      'videoUrl': videoUrl,
      'voiceChatUrl': voiceChatUrl,
      'postId': postId,
      'originalGroupId': originalGroupId,
    };
  }

  // Create a Message object from Firestore document
  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      senderId: map['senderId'],
      senderEmail: map['senderEmail'],
      receiverId: map['receiverId'],
      message: map['message'],
      timestamp: map['timestamp'],
      type: map['type'],
      imageUrls: map['imageUrls'] != null ? List<String>.from(map['imageUrls']) : null,
      videoUrl: map['videoUrl'],
      voiceChatUrl: map['voiceChatUrl'],
      postId: map['postId'],
      originalGroupId: map['originalGroupId'],
    );
  }
}
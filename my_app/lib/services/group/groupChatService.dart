import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:my_app/model/group/message.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:my_app/services/auth/authService.dart';

class GroupChatService extends ChangeNotifier {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _fireStore = FirebaseFirestore.instance;

  final String apiEndpoint = "http://192.168.1.200:5000/upload";
  final Authservice _authservice = Authservice();

  /// Upload ảnh lên Cloudinary
  Future<List<String>> _uploadImages(List<File> images) async {
    return _uploadFiles(images, 'image');
  }

  /// Upload video lên Cloudinary
  Future<List<String>> _uploadVideos(List<File> videos) async {
    return _uploadFiles(videos, 'video');
  }

  /// Upload voice lên Cloudinary
  Future<List<String>> _uploadVoices(List<File> voices) async {
    return _uploadFiles(voices, 'video');
  }

  /// Hàm upload file lên Cloudinary qua API server
  Future<List<String>> _uploadFiles(List<File> files, String type) async {
    List<String> urls = [];

    for (File file in files) {
      var request = http.MultipartRequest('POST', Uri.parse(apiEndpoint));
      request.fields['type'] = type;
      request.files.add(await http.MultipartFile.fromPath('file', file.path));

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();
      var jsonData = json.decode(responseBody);

      if (response.statusCode == 200 && jsonData['url'] != null) {
        urls.add(jsonData['url']);
      } else {
        throw Exception("Upload failed: ${jsonData['error']}");
      }
    }
    return urls;
  }

  // Send Shared Post Message
  Future<void> sendSharePostMessage(
      String groupId,
      String postId,
      String originalGroupId,
      String content,
      String? videoUrl,
      List<String>? imageUrls, // Sửa thành danh sách
      {String? postOwnerName}) async {
    try {
      final user =
          await _authservice.getUserById(_firebaseAuth.currentUser!.uid);
      final String currentUserId = _firebaseAuth.currentUser!.uid;
      final String currentUserEmail =
          _firebaseAuth.currentUser!.email.toString();
      final String messageId = _fireStore
          .collection('groups')
          .doc(groupId)
          .collection('chat_rooms')
          .doc(groupId)
          .collection('messages')
          .doc()
          .id;
      final Timestamp timestamp = Timestamp.now();

      // Kết hợp thông tin chia sẻ thành chuỗi message
      String shareMessage =
          'Đã chia sẻ bài đăng từ ${postOwnerName ?? 'Ẩn danh'}: $content';
      if (imageUrls != null && imageUrls.isNotEmpty) {
        shareMessage += ' (Có ${imageUrls.length} ảnh)';
      }
      if (videoUrl != null) {
        shareMessage += ' (Có video)';
      }

      print("Sending share post with imageUrls: $imageUrls"); // Log để kiểm tra

      Message newMessage = Message(
        senderId: currentUserId,
        senderEmail: user!.fullName ?? currentUserEmail,
        receiverId: '',
        message: shareMessage,
        timestamp: timestamp,
        type: 'share_post',
        imageUrls: imageUrls, // Lưu toàn bộ danh sách
        videoUrl: videoUrl,
        postId: postId,
        originalGroupId: originalGroupId,
      );

      await _fireStore
          .collection('groups')
          .doc(groupId)
          .collection('chat_rooms')
          .doc(groupId)
          .collection('messages')
          .doc(messageId)
          .set(newMessage.toMap());
    } catch (e) {
      throw Exception("Failed to share post: $e");
    }
  }

  // Send Group Message (Public Chat)
  Future<void> sendGroupMessage(String groupId, String message,
      {List<File>? images, List<File>? videos, List<File>? voices}) async {
    try {
      final user =
          await _authservice.getUserById(_firebaseAuth.currentUser!.uid);
      final String currentUserId = _firebaseAuth.currentUser!.uid;
      final String currentUserEmail =
          _firebaseAuth.currentUser!.email.toString();
      final String messageId = _fireStore
          .collection('groups')
          .doc(groupId)
          .collection('chat_rooms')
          .doc(groupId)
          .collection('messages')
          .doc()
          .id;
      final Timestamp timestamp = Timestamp.now();
      List<String> imageUrls =
          images != null ? await _uploadImages(images) : [];
      List<String> videoUrls =
          videos != null ? await _uploadVideos(videos) : [];
      List<String> voiceChatUrls =
          voices != null ? await _uploadVoices(voices) : [];

      Message newMessage = Message(
        senderId: currentUserId,
        senderEmail: user!.fullName ?? currentUserEmail,
        receiverId: '',
        message: message,
        timestamp: timestamp,
        type: 'group',
        imageUrls: imageUrls.isNotEmpty ? imageUrls : null,
        videoUrl: videoUrls.isNotEmpty ? videoUrls[0] : null,
        voiceChatUrl: voiceChatUrls.isNotEmpty ? voiceChatUrls[0] : null,
      );

      await _fireStore
          .collection('groups')
          .doc(groupId)
          .collection('chat_rooms')
          .doc(groupId)
          .collection('messages')
          .doc(messageId)
          .set(newMessage.toMap());
    } catch (e) {
      throw Exception("Failed to send group message: $e");
    }
  }

  // Send Private Message in Group
  Future<void> sendPrivateMessage(
    String groupId,
    String receiverId,
    String message, {
    List<File>? images,
    List<String>? sharedImages,
    List<File>? videos,
    List<File>? voices,
    String? videoUrl,
    String? postOwnerName,
    String? type = 'private',
    String? postId,
    String? originalGroupId,
  }) async {
    try {
      final user =
          await _authservice.getUserById(_firebaseAuth.currentUser!.uid);
      final String currentUserId = _firebaseAuth.currentUser!.uid;
      final String currentUserEmail =
          _firebaseAuth.currentUser!.email.toString();

      final Timestamp timestamp = Timestamp.now();

      List<String> ids = [currentUserId, receiverId];
      ids.sort();
      String chatRoomId = ids.join("_");

      final String messageId = _fireStore
          .collection('groups')
          .doc(groupId)
          .collection('chat_rooms')
          .doc(chatRoomId)
          .collection('messages')
          .doc()
          .id;

      List<String> imageUrls =
          images != null ? await _uploadImages(images) : [];
      if (sharedImages != null && sharedImages.isNotEmpty) {
        imageUrls.addAll(sharedImages);
      }
      List<String> videoUrls =
          videos != null ? await _uploadVideos(videos) : [];
      List<String> voiceChatUrls =
          voices != null ? await _uploadVoices(voices) : [];

      String finalMessage = message;
      if (type == 'share_post') {
        finalMessage =
            'Đã chia sẻ bài đăng từ ${postOwnerName ?? 'Ẩn danh'}: $message';
        if (imageUrls.isNotEmpty) {
          finalMessage += ' (Có ${imageUrls.length} ảnh)';
        }
        if (videoUrl != null && videoUrl.isNotEmpty) {
          finalMessage += ' (Có video)';
        }
      }

      print(
          "Sending private message with imageUrls: $imageUrls"); // Log để kiểm tra

      Message newMessage = Message(
        senderId: currentUserId,
        senderEmail: user!.fullName ?? currentUserEmail,
        receiverId: receiverId,
        message: finalMessage,
        timestamp: timestamp,
        type: type ?? 'private',
        imageUrls: imageUrls.isNotEmpty ? imageUrls : null,
        videoUrl:
            type == 'share_post' && videoUrl != null && videoUrl.isNotEmpty
                ? videoUrl
                : (videoUrls.isNotEmpty ? videoUrls[0] : null),
        voiceChatUrl: voiceChatUrls.isNotEmpty ? voiceChatUrls[0] : null,
        postId: postId,
        originalGroupId: originalGroupId,
      );

      await _fireStore
          .collection('groups')
          .doc(groupId)
          .collection('chat_rooms')
          .doc(chatRoomId)
          .collection('messages')
          .doc(messageId)
          .set(newMessage.toMap());
    } catch (e) {
      throw Exception("Failed to send private message: $e");
    }
  }

  // Get Group Messages (Public Chat)
  Stream<QuerySnapshot> getGroupMessages(String groupId) {
    return _fireStore
        .collection('groups')
        .doc(groupId)
        .collection('chat_rooms')
        .doc(groupId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  // Get Private Messages in Group
  Stream<QuerySnapshot> getPrivateMessages(
      String groupId, String userId, String receiverId) {
    List<String> ids = [userId, receiverId];
    ids.sort();
    String chatRoomId = ids.join("_");

    return _fireStore
        .collection('groups')
        .doc(groupId)
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

import 'package:my_app/model/group/posting.dart';

class GroupPostingService extends ChangeNotifier {
  final FirebaseFirestore _fireStore = FirebaseFirestore.instance;
  final String apiEndpoint = "http://192.168.0.100:5000/upload"; 

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
    return _uploadFiles(voices, 'audio');
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

  /// Tạo post mới, lưu URL trên Firestore
  Future<void> createPost(String groupId, String content,
      {List<File>? images, List<File>? videos, List<File>? voices}) async {
    try {
      final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
      final Timestamp timestamp = Timestamp.now();
      final String postId =
          _fireStore.collection('groups').doc(groupId).collection('posts').doc().id;

      List<String> imageUrls = images != null ? await _uploadImages(images) : [];
      List<String> videoUrls = videos != null ? await _uploadVideos(videos) : [];
      List<String> voiceChatUrls = voices != null ? await _uploadVoices(voices) : [];

      Posting newPost = Posting(
        postId: postId,
        groupId: groupId,
        userId: currentUserId,
        content: content,
        timestamp: timestamp,
        likes: [],
        comments: [],
        imageUrls: imageUrls.isNotEmpty ? imageUrls : null,
        videoUrl: videoUrls.isNotEmpty ? videoUrls[0] : null,
        voiceChatUrl: voiceChatUrls.isNotEmpty ? voiceChatUrls[0] : null,
      );

      await _fireStore
          .collection('groups')
          .doc(groupId)
          .collection('posts')
          .doc(newPost.postId)
          .set(newPost.toMap());
    } catch (e) {
      throw Exception("Failed to post: $e");
    }
  }

  /// Lấy danh sách bài đăng từ nhóm
  Stream<QuerySnapshot> getGroupPosts(String groupId) {
    return _fireStore
        .collection('groups')
        .doc(groupId)
        .collection('posts')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:my_app/model/group/message.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
class GroupChatService extends ChangeNotifier {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _fireStore = FirebaseFirestore.instance;

   // Save images to local storage
  Future<List<String>> _saveImages(String groupId, String chatRoomId, String messageId, List<File> images) async {
    return _saveFiles(groupId, chatRoomId, messageId, images, 'images');
  }

  // Save videos to local storage
  Future<List<String>> _saveVideos(String groupId, String chatRoomId, String messageId, List<File> videos) async {
    return _saveFiles(groupId, chatRoomId, messageId, videos, 'videos');
  }

  // Save voice recordings to local storage
  Future<List<String>> _saveVoices(String groupId, String chatRoomId, String messageId, List<File> voices) async {
    return _saveFiles(groupId, chatRoomId, messageId, voices, 'voices');
  }

  Future<List<String>> _saveFiles(String groupId, String chatRoomId, String messageId, List<File> files, String folder) async {
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    List<String> filePaths = [];

    final folderPath = '${directory.path}/group/$groupId/chatrooms/$chatRoomId/messages/$messageId/$folder';
    await Directory(folderPath).create(recursive: true);

    for (File file in files) {
      final filename = '${folder}_${timestamp}_${file.hashCode}_${file.path.split('/').last}';
      final filePath = '$folderPath/$filename';
      await file.copy(filePath);
      filePaths.add(filePath);
    }
    return filePaths;
  }

  // Send Group Message (Public Chat)
  Future<void> sendGroupMessage(String groupId, String message, {List<File>? images, List<File>? videos, List<File>? voices}) async {
    try{
      final String currentUserId = _firebaseAuth.currentUser!.uid;
      final String currentUserEmail = _firebaseAuth.currentUser!.email.toString();
      final String messageId = _fireStore.collection('groups').doc(groupId).collection('chat_rooms').doc(groupId).collection('messages').doc().id;
      final Timestamp timestamp = Timestamp.now();
      List<String> imageUrls = [];
      List<String> videoUrls = [];
      List<String> voiceChatUrls = [];

      if (images != null) imageUrls.addAll(await _saveImages(groupId, groupId, messageId, images));
      if (videos != null) videoUrls.addAll(await _saveVideos(groupId, groupId, messageId, videos));
      if (voices != null) voiceChatUrls.addAll(await _saveVoices(groupId, groupId, messageId, voices));

      Message newMessage = Message(
        senderId: currentUserId,
        senderEmail: currentUserEmail,
        receiverId: '',
        message: message,
        timestamp: timestamp,
        type: 'group',
        imageUrls: imageUrls.isNotEmpty ? imageUrls : null,
        videoUrl: videoUrls.isNotEmpty ? videoUrls[0] : null,
        voiceChatUrl: voiceChatUrls.isNotEmpty ? voiceChatUrls[0] : null,
      );

      await _fireStore.collection('groups')
          .doc(groupId)
          .collection('chat_rooms')
          .doc(groupId)
          .collection('messages')
          .doc(messageId)
          .set(newMessage.toMap());
    }catch (e) {
      throw Exception("Failed to send group message: $e");
    }
  }


  // Send Private Message in Group
  Future<void> sendPrivateMessage(String groupId, String receiverId, String message, {List<File>? images, List<File>? videos, List<File>? voices}) async {
    try{
      final String currentUserId = _firebaseAuth.currentUser!.uid;
      final String currentUserEmail = _firebaseAuth.currentUser!.email.toString();
      
      final Timestamp timestamp = Timestamp.now();
      List<String> imageUrls = [];
      List<String> videoUrls = [];
      List<String> voiceChatUrls = [];

      List<String> ids = [currentUserId, receiverId];
      ids.sort();
      String chatRoomId = ids.join("_");

      final String messageId = _fireStore.collection('groups').doc(groupId).collection('chat_rooms').doc(chatRoomId).collection('messages').doc().id;

      if (images != null) imageUrls.addAll(await _saveImages(groupId, chatRoomId, messageId, images));
      if (videos != null) videoUrls.addAll(await _saveVideos(groupId, chatRoomId, messageId, videos));
      if (voices != null) voiceChatUrls.addAll(await _saveVoices(groupId, chatRoomId, messageId, voices));

      Message newMessage = Message(
        senderId: currentUserId,
        senderEmail: currentUserEmail,
        receiverId: receiverId,
        message: message,
        timestamp: timestamp,
        type: 'private',
        imageUrls: imageUrls.isNotEmpty ? imageUrls : null,
        videoUrl: videoUrls.isNotEmpty ? videoUrls[0] : null,
        voiceChatUrl: voiceChatUrls.isNotEmpty ? voiceChatUrls[0] : null,
      );

      await _fireStore.collection('groups')
          .doc(groupId)
          .collection('chat_rooms')
          .doc(chatRoomId) 
          .collection('messages')
          .doc(messageId)
          .set(newMessage.toMap());
    }catch (e) {
      throw Exception("Failed to send private message: $e");
    }
  }

  // Get Group Messages (Public Chat)
  Stream<QuerySnapshot> getGroupMessages(String groupId) {
    return _fireStore.collection('groups')
        .doc(groupId)
        .collection('chat_rooms')
        .doc(groupId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  // Get Private Messages in Group
  Stream<QuerySnapshot> getPrivateMessages(String groupId, String userId, String receiverId) {
    List<String> ids = [userId, receiverId];
    ids.sort();
    String chatRoomId = ids.join("_");

    return _fireStore.collection('groups')
        .doc(groupId)
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }
}
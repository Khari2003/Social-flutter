// ignore_for_file: file_names

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:my_app/model/user/user.dart' as model;
import 'package:flutter/material.dart';

class Authservice extends ChangeNotifier {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _fireStore = FirebaseFirestore.instance;

  // Đăng nhập và cập nhật vị trí
  Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    try {
      // Đăng nhập vào Firebase Authentication
      UserCredential userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email, 
        password: password
      );

      // Lấy UID của người dùng
      String userId = userCredential.user!.uid;

      // Yêu cầu quyền và lấy vị trí hiện tại
      Position? position = await _determinePosition();
      GeoPoint? location;
      
      if (position != null) {
        location = GeoPoint(position.latitude, position.longitude);
      }

      // Cập nhật Firestore với thông tin người dùng và tọa độ
      _fireStore.collection('users').doc(userId).set({
        'uid': userId,
        'email': email,
        'location': location != null 
            ? {'lat': location.latitude, 'lng': location.longitude} 
            : null,
        'isAllowedLocation': location != null,
      }, SetOptions(merge: true));

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.code);
    }
  }


   Future<String?> getEmailById(String userId) async {
    try {
      DocumentSnapshot userDoc = await _fireStore.collection('users').doc(userId).get();
      
      if (userDoc.exists) {
        // Cast the data to a Map<String, dynamic>
        Map<String, dynamic>? data = userDoc.data() as Map<String, dynamic>?;
        return data?['email'] as String?;
      } else {
        return null; // User not found
      }
    } catch (e) {
      throw Exception("Error fetching email: $e");
    }
  }

  // Lưu bài viết
  Future<void> savePost(String postId) async {
    try {
      String userId = _firebaseAuth.currentUser!.uid;
      await _fireStore.collection('users').doc(userId).update({
        'savedPosts': FieldValue.arrayUnion([postId]),
      });
    } catch (e) {
      throw Exception("Failed to save post: $e");
    }
  }

  // Bỏ lưu bài viết
  Future<void> unsavePost(String postId) async {
    try {
      String userId = _firebaseAuth.currentUser!.uid;
      await _fireStore.collection('users').doc(userId).update({
        'savedPosts': FieldValue.arrayRemove([postId]),
      });
    } catch (e) {
      throw Exception("Failed to unsave post: $e");
    }
  }

  // Lấy danh sách postId đã lưu
  Future<List<String>> getSavedPosts() async {
    try {
      String userId = _firebaseAuth.currentUser!.uid;
      DocumentSnapshot userDoc = await _fireStore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        Map<String, dynamic>? data = userDoc.data() as Map<String, dynamic>?;
        return List<String>.from(data?['savedPosts'] ?? []);
      }
      return [];
    } catch (e) {
      throw Exception("Failed to fetch saved posts: $e");
    }
  }


  // Lấy vị trí người dùng
  Future<Position?> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Kiểm tra xem dịch vụ vị trí có được bật không
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null; // Dịch vụ vị trí bị tắt
    }

    // Kiểm tra quyền truy cập vị trí
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null; // Người dùng từ chối quyền truy cập
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return null; // Người dùng chặn vĩnh viễn quyền truy cập vị trí
    }

    // Lấy tọa độ hiện tại của người dùng
    return await Geolocator.getCurrentPosition();
  }

  Future<UserCredential> signUpWithEmailAndPassword(String email, String password, bool isAllowedLocation, GeoPoint? location) async {
    try {
      UserCredential userCredential = await _firebaseAuth.createUserWithEmailAndPassword(email: email, password: password);

      model.User newUser = model.User(
        userId: userCredential.user!.uid,
        userEmail: email,
        timestamp: Timestamp.now(),
        location: isAllowedLocation ? location : null,
        isAllowedLocation: isAllowedLocation,
      );

      _fireStore.collection('users').doc(newUser.userId).set(newUser.toMap());
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.code);
    }
  }

  Future<void> updateUserLocation(String userId, GeoPoint location) async {
    try {
      await _fireStore.collection('users').doc(userId).update({
        'location': {'lat': location.latitude, 'lng': location.longitude},
        'isAllowedLocation': true,
      });
    } catch (e) {
      throw Exception('Failed to update location');
    }
  }

  Future<void> signOut() async {
    return await FirebaseAuth.instance.signOut();
  }
}
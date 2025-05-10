import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:my_app/model/user/user.dart' as model;
import 'package:flutter/material.dart';

class Authservice extends ChangeNotifier {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _fireStore = FirebaseFirestore.instance;

  Future<UserCredential> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      UserCredential userCredential = await _firebaseAuth
          .signInWithEmailAndPassword(email: email, password: password);

      String userId = userCredential.user!.uid;

      Position? position = await _determinePosition();
      GeoPoint? location;

      if (position != null) {
        location = GeoPoint(position.latitude, position.longitude);
      }

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
      DocumentSnapshot userDoc =
          await _fireStore.collection('users').doc(userId).get();

      if (userDoc.exists) {
        Map<String, dynamic>? data = userDoc.data() as Map<String, dynamic>?;
        return data?['email'] as String?;
      } else {
        return null;
      }
    } catch (e) {
      throw Exception("Error fetching email: $e");
    }
  }

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

  Future<List<String>> getSavedPosts() async {
    try {
      String userId = _firebaseAuth.currentUser!.uid;
      DocumentSnapshot userDoc =
          await _fireStore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        Map<String, dynamic>? data = userDoc.data() as Map<String, dynamic>?;
        return List<String>.from(data?['savedPosts'] ?? []);
      }
      return [];
    } catch (e) {
      throw Exception("Failed to fetch saved posts: $e");
    }
  }

  Future<Position?> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return null;
    }

    return await Geolocator.getCurrentPosition();
  }

  Future<UserCredential> signUpWithEmailAndPassword(String email,
      String password, bool isAllowedLocation, GeoPoint? location) async {
    try {
      UserCredential userCredential = await _firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: password);

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

  Future<void> updateUser({
    required String userId,
    String? fullName,
    String? avatarUrl,
    String? coverPhotoUrl, // New field
    String? phoneNumber,
    String? bio,
  }) async {
    try {
      final Map<String, dynamic> updateData = {
        if (fullName != null) 'fullName': fullName,
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
        if (coverPhotoUrl != null) 'coverPhotoUrl': coverPhotoUrl, // New field
        if (phoneNumber != null) 'phoneNumber': phoneNumber,
        if (bio != null) 'bio': bio,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (updateData.isNotEmpty) {
        await _fireStore.collection('users').doc(userId).update(updateData);
      }
    } catch (e) {
      throw Exception("Failed to update user: $e");
    }
  }

  Future<model.User?> getUserById(String userId) async {
    try {
      DocumentSnapshot userDoc =
          await _fireStore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        return model.User.fromMap(userDoc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception("Failed to fetch user: $e");
    }
  }

  Stream<QuerySnapshot> getUserPosts(String userId) {
    return _fireStore
        .collectionGroup('posts')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(20)
        .snapshots();
  }

  Stream<QuerySnapshot> getUserPostsInGroup(String userId, String groupId) {
    return _fireStore
        .collection('groups')
        .doc(groupId)
        .collection('posts')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(20)
        .snapshots();
  }
}
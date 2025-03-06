import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_app/model/user/user.dart' as model;
import 'package:flutter/material.dart';

class Authservice extends ChangeNotifier {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _fireStore = FirebaseFirestore.instance;

  Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential userCredential = await _firebaseAuth.signInWithEmailAndPassword(email: email, password: password);
      _fireStore.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'email': email,
      }, SetOptions(merge: true));
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.code);
    }
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
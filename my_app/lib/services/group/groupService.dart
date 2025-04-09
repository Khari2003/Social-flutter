import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:my_app/model/group/group.dart';


class GroupService extends ChangeNotifier {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _fireStore = FirebaseFirestore.instance;


  // Create Group with Join Link
  Future<String> createGroup(String groupName) async {
    try {
      String groupId = _fireStore.collection('groups').doc().id;
      String adminId = _firebaseAuth.currentUser!.uid;
      String joinLink = base64Url.encode(utf8.encode(groupId));

      Group newGroup = Group(
        groupId: groupId,
        groupName: groupName,
        adminId: adminId,
        members: [adminId],
        joinLink: joinLink,
        createdAt: Timestamp.now(),
      );

      await _fireStore.collection('groups').doc(groupId).set(newGroup.toMap());
      return joinLink;
    } catch (e) {
      throw Exception("Failed to create group: $e");
    }
  }

  // Join Group using Link
  Future<void> joinGroup(String joinLink) async {
    try {
      String groupId = utf8.decode(base64Url.decode(joinLink));
      String userId = _firebaseAuth.currentUser!.uid;

      // Check if the group exists
      DocumentSnapshot groupSnapshot = await _fireStore.collection('groups').doc(groupId).get();
      if (!groupSnapshot.exists) {
        throw Exception("Group does not exist");
      }

      // Add the user to the group's members list
      await _fireStore.collection('groups').doc(groupId).update({
        'members': FieldValue.arrayUnion([userId]),
      });
    } catch (e) {
      throw Exception("Failed to join group: $e");
    }
  }

  // Remove Member from Group (Admin Only)
  Future<void> removeMemberFromGroup(String groupId, String userId) async {
    try {
      String currentUserId = _firebaseAuth.currentUser!.uid;

      // Check if the current user is the admin
      DocumentSnapshot groupSnapshot = await _fireStore.collection('groups').doc(groupId).get();
      if (groupSnapshot['adminId'] != currentUserId) {
        throw Exception("Only the admin can remove members");
      }

      // Remove the user from the group's members list
      await _fireStore.collection('groups').doc(groupId).update({
        'members': FieldValue.arrayRemove([userId]),
      });
    } catch (e) {
      throw Exception("Failed to remove member: $e");
    }
  }

  //
  // Get Groups for a User
  Stream<QuerySnapshot> getUserGroups() {
    try {
      String userId = _firebaseAuth.currentUser!.uid;
      return _fireStore.collection('groups')
          .where('members', arrayContains: userId)
          .snapshots();
    } catch (e) {
      throw Exception("Failed to fetch user groups: $e");
    }
  }

  Future<List<Map<String, dynamic>>> getGroupMemberLocations(String groupId) async {
    print("Fetching locations for group: $groupId");
    try {
      DocumentSnapshot groupSnapshot = 
          await _fireStore.collection('groups').doc(groupId).get();
      
      if (!groupSnapshot.exists) {
        throw Exception("Group does not exist");
      }

      List<dynamic> members = groupSnapshot['members'];
      List<Map<String, dynamic>> memberLocations = [];

      for (String memberId in members) {
        DocumentSnapshot userSnapshot = await _fireStore.collection('users').doc(memberId).get();
        print(userSnapshot);
        if (userSnapshot.exists) {
          var userData = userSnapshot.data() as Map<String, dynamic>;
          if (userData.containsKey('location')) {
            memberLocations.add({
              "id": memberId,
              "lat": userData['location']['lat'],
              "lng": userData['location']['lng']
            });
          }
        }
      }
      return memberLocations;
    } catch (e) {
      throw Exception("Failed to fetch member locations: $e");
    }
  }
}
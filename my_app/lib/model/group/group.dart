import 'package:cloud_firestore/cloud_firestore.dart';

class Group {
  final String groupId;
  final String groupName;
  final String adminId;
  final List<String> members;
  final String joinLink;
  final Timestamp createdAt;

  Group({
    required this.groupId,
    required this.groupName,
    required this.adminId,
    required this.members,
    required this.joinLink,
    required this.createdAt,
  });

  // Convert Group object to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'groupId': groupId,
      'groupName': groupName,
      'adminId': adminId,
      'members': members,
      'joinLink': joinLink,
      'createdAt': createdAt,
    };
  }

  // Create a Group object from Firestore document
  factory Group.fromMap(Map<String, dynamic> map) {
    return Group(
      groupId: map['groupId'],
      groupName: map['groupName'],
      adminId: map['adminId'],
      members: List<String>.from(map['members']),
      joinLink: map['joinLink'],
      createdAt: map['createdAt'],
    );
  }
}
import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String userId;
  final String userEmail;
  final Timestamp timestamp;
  final GeoPoint? location;
  final bool isAllowedLocation;
  final String? fullName;
  final String? avatarUrl;
  final String? phoneNumber;
  final String? bio;
  final Timestamp? updatedAt;

  User({
    required this.userId,
    required this.userEmail,
    required this.timestamp,
    this.location,
    required this.isAllowedLocation,
    this.fullName,
    this.avatarUrl,
    this.phoneNumber,
    this.bio,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': userId,
      'email': userEmail,
      'timestamp': timestamp,
      'location': location != null
          ? {'lat': location!.latitude, 'lng': location!.longitude}
          : null,
      'isAllowedLocation': isAllowedLocation,
      'fullName': fullName,
      'avatarUrl': avatarUrl,
      'phoneNumber': phoneNumber,
      'bio': bio,
      'updatedAt': updatedAt ?? FieldValue.serverTimestamp(),
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      userId: map['uid'] as String,
      userEmail: map['email'] as String,
      timestamp: map['timestamp'] as Timestamp,
      location: map['location'] != null
          ? GeoPoint(
              (map['location']['lat'] as num).toDouble(),
              (map['location']['lng'] as num).toDouble(),
            )
          : null,
      isAllowedLocation: map['isAllowedLocation'] as bool,
      fullName: map['fullName'] as String?,
      avatarUrl: map['avatarUrl'] as String?,
      phoneNumber: map['phoneNumber'] as String?,
      bio: map['bio'] as String?,
      updatedAt: map['updatedAt'] as Timestamp?,
    );
  }
}

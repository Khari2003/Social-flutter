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
    print("Dữ liệu từ Firestore trong User.fromMap: $map");

    if (map['uid'] == null ||
        map['email'] == null ||
        map['timestamp'] == null ||
        map['isAllowedLocation'] == null) {
      throw Exception(
          "Dữ liệu người dùng không đầy đủ: Thiếu các trường bắt buộc (uid, email, timestamp, isAllowedLocation)");
    }

    if (map['uid'] is! String) {
      throw Exception("Trường 'uid' phải là String, nhận được: ${map['uid']}");
    }
    if (map['email'] is! String) {
      throw Exception(
          "Trường 'email' phải là String, nhận được: ${map['email']}");
    }
    if (map['timestamp'] is! Timestamp) {
      throw Exception(
          "Trường 'timestamp' phải là Timestamp, nhận được: ${map['timestamp']}");
    }
    if (map['isAllowedLocation'] is! bool) {
      throw Exception(
          "Trường 'isAllowedLocation' phải là bool, nhận được: ${map['isAllowedLocation']}");
    }
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
      updatedAt: map['updatedAt'] != null ? map['updatedAt'] as Timestamp : null,
    );
  }
}

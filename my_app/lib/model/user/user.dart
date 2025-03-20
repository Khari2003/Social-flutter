import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String userId;
  final String userEmail;
  final Timestamp timestamp;
  final GeoPoint? location;
  final bool isAllowedLocation;

  User({
    required this.userId,
    required this.userEmail,
    required this.timestamp,
    this.location,
    required this.isAllowedLocation,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': userId,
      'email': userEmail,
      'timestamp': timestamp,
      'location': location != null ? {'lat': location!.latitude, 'lng': location!.longitude} : null,
      'isAllowedLocation': isAllowedLocation,
    };
  }
}
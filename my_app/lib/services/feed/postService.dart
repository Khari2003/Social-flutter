import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:my_app/model/post.dart'; 

class PostService extends ChangeNotifier {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _fireStore = FirebaseFirestore.instance;

  // Create a new post
  Future<void> createPost(String content, {String? imageUrl}) async {
    // Get current user
    final String currentUserId = _firebaseAuth.currentUser!.uid;
    final String currentUserEmail = _firebaseAuth.currentUser!.email.toString();
    final Timestamp timestamp = Timestamp.now();

    // Create a new post object
    Post newPost = Post(
      userId: currentUserId,
      userEmail: currentUserEmail,
      content: content,
      imageUrl: imageUrl,
      timestamp: timestamp,
      likes: [], // Initialize with no likes
      comments: [], // Initialize with no comments
    );

    // Add the new post to the 'posts' collection in Firestore
    await _fireStore.collection('posts').add(newPost.toMap());
  }

  // Get all posts
  Stream<QuerySnapshot> getPosts() {
    return _fireStore
        .collection('posts')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Like a post
  Future<void> likePost(String postId) async {
    final String currentUserId = _firebaseAuth.currentUser!.uid;

    // Get the post document
    DocumentReference postRef = _fireStore.collection('posts').doc(postId);

    // Update the likes array to include the current user's ID
    await postRef.update({
      'likes': FieldValue.arrayUnion([currentUserId])
    });
  }

  // Add a comment to a post
  Future<void> addComment(String postId, String comment) async {
    final String currentUserId = _firebaseAuth.currentUser!.uid;
    final String currentUserEmail = _firebaseAuth.currentUser!.email.toString();
    final Timestamp timestamp = Timestamp.now();

    // Create a new comment object
    Map<String, dynamic> newComment = {
      'userId': currentUserId,
      'userEmail': currentUserEmail,
      'comment': comment,
      'timestamp': timestamp,
    };

    // Get the post document
    DocumentReference postRef = _fireStore.collection('posts').doc(postId);

    // Update the comments array to include the new comment
    await postRef.update({
      'comments': FieldValue.arrayUnion([newComment])
    });
  }
}
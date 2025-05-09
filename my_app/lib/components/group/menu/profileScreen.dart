import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_app/components/group/homepage/groupPostCard.dart';
import 'package:my_app/model/user/user.dart' as model;
import 'package:my_app/services/auth/authService.dart';
import 'package:my_app/services/group/groupPostingService.dart';
import 'package:my_app/components/group/menu/editProfileScreen.dart';
import 'package:my_app/model/group/posting.dart';

class ProfileScreen extends StatelessWidget {
  final String userId;

  const ProfileScreen({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Authservice authService = Authservice();
    final GroupPostingService postService = GroupPostingService();
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;
    final isOwnProfile = userId == currentUserId;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Hồ sơ cá nhân"),
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
        actions: [
          if (isOwnProfile)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EditProfileScreen(),
                  ),
                );
              },
            ),
        ],
      ),
      backgroundColor: Colors.black87,
      body: FutureBuilder<model.User?>(
        future: authService.getUserById(userId),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (userSnapshot.hasError) {
            return Center(
              child: Text(
                "Lỗi khi tải thông tin người dùng: ${userSnapshot.error}",
                style: const TextStyle(color: Colors.white),
              ),
            );
          }
          if (!userSnapshot.hasData || userSnapshot.data == null) {
            return const Center(
              child: Text(
                "Không tìm thấy thông tin người dùng",
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          final user = userSnapshot.data!;

          return Column(
            children: [
              // Thông tin cá nhân
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: user.avatarUrl != null
                          ? NetworkImage(user.avatarUrl!)
                          : null,
                      child: user.avatarUrl == null
                          ? const Icon(Icons.person, size: 50, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user.fullName ?? user.userEmail.split('@')[0],
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      user.userEmail,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    if (user.phoneNumber != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        user.phoneNumber!,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                    if (user.bio != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        user.bio!,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
              const Divider(color: Colors.grey),
              // Danh sách bài đăng
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collectionGroup('posts')
                      .where('userId', isEqualTo: userId)
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          "Lỗi khi tải bài đăng: ${snapshot.error}",
                          style: const TextStyle(color: Colors.white),
                        ),
                      );
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(
                        child: Text(
                          "Không có bài đăng nào",
                          style: TextStyle(color: Colors.white),
                        ),
                      );
                    }

                    final posts = snapshot.data!.docs.map((doc) {
                      try {
                        return GroupPostCard(
                          post: Posting.fromMap(doc.data() as Map<String, dynamic>),
                          postService: postService,
                        );
                      } catch (e) {
                        return const SizedBox.shrink(); // Bỏ qua bài đăng lỗi
                      }
                    }).toList();

                    return ListView(
                      children: posts,
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
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
  final String groupId;

  const ProfileScreen({Key? key, required this.userId, required this.groupId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Authservice authService = Authservice();
    final GroupPostingService postService = GroupPostingService();
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;
    final isOwnProfile = userId == currentUserId;

    return Scaffold(
      backgroundColor: Colors.black87,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 450, // Chiều cao tổng để chứa ảnh bìa, avatar, và thông tin
            floating: false,
            pinned: true,
            backgroundColor: Colors.black87,
            elevation: 4,
            flexibleSpace: FlexibleSpaceBar(
              background: FutureBuilder<model.User?>(
                future: authService.getUserById(userId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Container(
                      color: Colors.black87,
                      child: const Center(child: CircularProgressIndicator(color: Colors.blueAccent)),
                    );
                  }
                  final user = snapshot.data;
                  return Stack(
                    children: [
                      // Phần ảnh bìa (chỉ chiếm phần trên)
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        height: 200, // Chiều cao ảnh bìa
                        child: user?.coverPhotoUrl != null
                            ? Image.network(
                                user!.coverPhotoUrl!,
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    color: Colors.grey[900],
                                    child: const Center(
                                      child: CircularProgressIndicator(color: Colors.blueAccent),
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [Colors.blueGrey.shade900, Colors.black87],
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                      ),
                                    ),
                                  );
                                },
                              )
                            : Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.blueGrey.shade900, Colors.black87],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                ),
                              ),
                      ),
                      // Gradient phủ lên ảnh bìa
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        height: 200,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.black.withOpacity(0.3), Colors.transparent],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                          ),
                        ),
                      ),
                      // Avatar nằm giữa
                      Positioned(
                        top: 140, // Nửa trên nằm trên ảnh bìa, nửa dưới trên thông tin
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Hero(
                            tag: 'userAvatar_$userId',
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [Colors.blueAccent, Colors.tealAccent],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.5),
                                    blurRadius: 12,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(3),
                              child: CircleAvatar(
                                radius: 60,
                                backgroundImage: user?.avatarUrl != null
                                    ? NetworkImage(user!.avatarUrl!)
                                    : null,
                                backgroundColor: Colors.grey[800],
                                child: user?.avatarUrl == null
                                    ? const Icon(Icons.person, size: 60, color: Colors.white70)
                                    : null,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Phần thông tin cá nhân (bên dưới avatar)
                      Positioned(
                        top: 260, // Bắt đầu dưới avatar (140 + 120 + 16 khoảng cách)
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Column(
                          children: [
                            Text(
                              user?.fullName ?? user?.userEmail.split('@')[0] ?? 'Unknown',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 0.8,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              user?.userEmail ?? '',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[400],
                                fontStyle: FontStyle.italic,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            if (user?.phoneNumber != null) ...[
                              const SizedBox(height: 12),
                              Text(
                                user!.phoneNumber!,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[400],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                            if (user?.bio != null) ...[
                              const SizedBox(height: 16),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                child: Text(
                                  user!.bio!,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white70,
                                    height: 1.5,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                            const SizedBox(height: 20),
                            StreamBuilder<QuerySnapshot>(
                              stream: authService.getUserPostsInGroup(userId, groupId),
                              builder: (context, snapshot) {
                                int postCount = snapshot.hasData ? snapshot.data!.docs.length : 0;
                                return Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _buildStatItem(context, 'Bài đăng', postCount.toString()),
                                    const SizedBox(width: 24),
                                    _buildStatItem(context, 'Tham gia', '2023'),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            actions: [
              if (isOwnProfile)
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.white),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EditProfileScreen(),
                      ),
                    );
                  },
                  splashRadius: 20,
                ),
            ],
          ),
          // Phần bài đăng
          SliverToBoxAdapter(
            child: StreamBuilder<QuerySnapshot>(
              stream: authService.getUserPostsInGroup(userId, groupId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.blueAccent));
                }
                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Center(
                      child: Text(
                        "Lỗi khi tải bài đăng: ${snapshot.error}",
                        style: const TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    ),
                  );
                }

                List<Widget> postsWidgets = [];
                if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                  postsWidgets = snapshot.data!.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    if (!data.containsKey('userId') || !data.containsKey('timestamp')) {
                      print("Tài liệu thiếu userId hoặc timestamp: ${doc.id}");
                      return const SizedBox.shrink();
                    }
                    try {
                      return AnimatedOpacity(
                        opacity: 1.0,
                        duration: const Duration(milliseconds: 300),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          child: GroupPostCard(
                            post: Posting.fromMap(data),
                            postService: postService,
                          ),
                        ),
                      );
                    } catch (e) {
                      print("Lỗi khi ánh xạ bài đăng ${doc.id}: $e");
                      return const SizedBox.shrink();
                    }
                  }).toList();
                } else {
                  postsWidgets.add(
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.post_add,
                            size: 80,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "Chưa có bài đăng nào trong nhóm này",
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 18,
                              fontStyle: FontStyle.italic,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (isOwnProfile) ...[
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () {
                                // Navigate to post creation screen (placeholder)
                              },
                              icon: const Icon(Icons.add),
                              label: const Text("Tạo bài đăng"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueAccent,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                      child: Text(
                        'Bài đăng trong nhóm',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Container(
                      height: 1,
                      margin: const EdgeInsets.symmetric(horizontal: 16.0),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.grey[600]!, Colors.transparent],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...postsWidgets,
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[400],
          ),
        ),
      ],
    );
  }
}
import 'package:flutter/material.dart';
import 'package:my_app/components/group/homepage/groupPostCard.dart';
import 'package:my_app/model/group/posting.dart';
import 'package:my_app/services/auth/authService.dart';
import 'package:my_app/services/group/groupPostingService.dart';

class SavedPostsScreen extends StatelessWidget {
  final GroupPostingService _postService = GroupPostingService();
  final Authservice _authService = Authservice();

  SavedPostsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      appBar: AppBar(
        backgroundColor: Colors.black87,
        title: const Text(
          'Bài đăng đã lưu',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<List<String>>(
        future: _authService.getSavedPosts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'Chưa có bài đăng nào được lưu!',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
            );
          }
          return StreamBuilder<List<Posting>>(
            stream: _postService.getSavedPostDetails(snapshot.data!),
            builder: (context, postSnapshot) {
              if (postSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!postSnapshot.hasData || postSnapshot.data!.isEmpty) {
                return const Center(
                  child: Text(
                    'Không tìm thấy bài đăng đã lưu!',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                );
              }
              return ListView.builder(
                itemCount: postSnapshot.data!.length,
                itemBuilder: (context, index) {
                  return GroupPostCard(
                    post: postSnapshot.data![index],
                    postService: _postService,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
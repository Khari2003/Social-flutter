import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:my_app/model/group/posting.dart';
import 'package:my_app/services/auth/authService.dart';
import 'package:my_app/services/group/groupPostingService.dart';
import 'package:my_app/components/group/post/groupPostDetail.dart';
import 'package:my_app/components/group/post/postWidget.dart'; // Import để sử dụng buildVideoPreview

class SavedPostsScreen extends StatelessWidget {
  final GroupPostingService _postService = GroupPostingService();
  final Authservice _authService = Authservice();
  final currentUserId = FirebaseAuth.instance.currentUser!.uid;

  SavedPostsScreen({Key? key}) : super(key: key);

  // Hàm định dạng thời gian
  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inHours < 24) {
      return "Cách đây ${difference.inHours} giờ";
    } else if (difference.inDays < 7) {
      return "Cách đây ${difference.inDays} ngày";
    } else if (difference.inDays < 30) {
      return "Cách đây ${difference.inDays ~/ 7} tuần";
    } else {
      return DateFormat("dd 'tháng' MM yyyy").format(timestamp);
    }
  }

  // Hàm rút ngắn nội dung bài đăng
  String _truncateContent(String content, int maxLength) {
    if (content.length <= maxLength) return content;
    return '${content.substring(0, maxLength)}...';
  }

  // Widget hiển thị thumbnail hoặc preview video
  Widget _buildThumbnail(BuildContext context, Posting post) {
    String thumbnailUrl = '';
    // ignore: unused_local_variable
    String postType = '';

    // Xác định loại bài đăng và lấy thumbnail
    if (post.imageUrls != null && post.imageUrls!.isNotEmpty) {
      thumbnailUrl = post.imageUrls!.first;
      postType = 'Thư viện';
    } else if (post.videoUrl != null && post.videoUrl!.isNotEmpty) {
      thumbnailUrl =
          ''; // Nếu có thumbnail cho video, bạn có thể thay thế ở đây
      postType = 'Video';
    } else {
      thumbnailUrl = ''; // Nếu không có hình ảnh hoặc video, để trống
      postType = 'Thư viện';
    }

    if (post.videoUrl != null && post.videoUrl!.isNotEmpty) {
      // Sử dụng buildVideoPreview để hiển thị preview video
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 100,
          height: 100,
          child: buildVideoPreview(context, post.videoUrl!, limitHeight: true),
        ),
      );
    }

    // Trường hợp không phải video (hình ảnh hoặc không có media)
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey[800],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: thumbnailUrl.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: thumbnailUrl,
                width: 100,
                height: 100,
                fit: BoxFit.cover,
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(color: Colors.blueAccent),
                ),
                errorWidget: (context, url, error) => const Center(
                  child: Icon(Icons.error, color: Colors.redAccent),
                ),
              )
            : const Center(
                child: Icon(
                  Icons.image_not_supported,
                  color: Colors.grey,
                  size: 40,
                ),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      appBar: AppBar(
        backgroundColor: Colors.black87,
        title: const Text(
          'Đã lưu',
          style: TextStyle(
              color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
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
            return const Center(
                child: CircularProgressIndicator(color: Colors.blueAccent));
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
                return const Center(
                    child: CircularProgressIndicator(color: Colors.blueAccent));
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

              final posts = postSnapshot.data!;

              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: posts.length,
                itemBuilder: (context, index) {
                  final post = posts[index];
                  String postType = '';

                  // Xác định loại bài đăng
                  if (post.imageUrls != null && post.imageUrls!.isNotEmpty) {
                    postType = 'Thư viện';
                  } else if (post.videoUrl != null &&
                      post.videoUrl!.isNotEmpty) {
                    postType = 'Video';
                  } else {
                    postType = 'Thư viện';
                  }

                  return GestureDetector(
                    onTap: () async {

                      List<String> likes = post.likes;
                         
                      bool isLiked =
                          likes.contains(FirebaseAuth.instance.currentUser!.uid);
                      int likeCount = likes.length;
                      
                      // Chuyển đến PostDetailScreen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PostDetailScreen(
                            post: post,
                            isLiked: isLiked,
                            likeCount: likeCount,
                            isSaved: true,
                            postService: _postService,
                            toggleLike: () {
                              _postService.likePost(post.groupId, post.postId);
                            },
                            toggleSave: () async {
                              try {
                                List<String> savedPosts =
                                    await _authService.getSavedPosts();
                                bool isSaved = savedPosts.contains(post.postId);
                                if (isSaved) {
                                  await _authService.unsavePost(post.postId);
                                } else {
                                  await _authService.savePost(post.postId);
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Lỗi khi lưu bài đăng: $e'),
                                    backgroundColor: Colors.redAccent,
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Thumbnail hoặc preview video
                          _buildThumbnail(context, post),
                          const SizedBox(width: 12),
                          // Nội dung bài đăng
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Tiêu đề
                                Text(
                                  _truncateContent(post.content, 50),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                // Loại bài đăng và nguồn
                                Text(
                                  '$postType • Đã lưu 5 ngày trước', // Thay đổi thời gian theo dữ liệu thực tế
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                // Thời gian
                                Text(
                                  _formatTimestamp(post.timestamp.toDate()),
                                  style: TextStyle(
                                    color: Colors.blueAccent.shade100,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
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

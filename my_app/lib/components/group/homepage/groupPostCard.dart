import 'package:flutter/material.dart';
import 'package:my_app/components/group/post/groupPostDetail.dart';
import 'package:my_app/components/group/post/postWidget.dart';
import 'package:my_app/services/group/groupPostingService.dart';
import 'package:intl/intl.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:my_app/model/group/posting.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GroupPostCard extends StatelessWidget {
  final Posting post;
  final GroupPostingService postService;

  GroupPostCard({Key? key, required this.post, required this.postService})
      : super(key: key);
  final TextEditingController _commentController = TextEditingController();
  final ValueNotifier<bool> isCommenting = ValueNotifier(false);
  void toggleLike() {
    postService.likePost(post.groupId, post.postId);
  }

  void addComment() async {
    if (_commentController.text.isNotEmpty && !isCommenting.value) {
      isCommenting.value = true; // Bắt đầu gửi bình luận

      try {
        await postService.addComment(
          post.groupId,
          post.postId,
          _commentController.text,
        );
        post.comments.add(_commentController.text);
        _commentController.clear();
      } catch (e) {
        print("Lỗi khi gửi bình luận: $e");
      } finally {
        isCommenting.value = false;
      }
    }
  }

  String formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inHours < 24) {
      return "Cách đây ${difference.inHours} giờ";
    } else if (difference.inDays < 6) {
      return "Cách đây ${difference.inDays} ngày";
    } else if (difference.inDays < 365) {
      return DateFormat("dd 'tháng' MM").format(timestamp);
    } else {
      return DateFormat("dd 'tháng' MM yyyy").format(timestamp);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('groups')
          .doc(post.groupId)
          .collection('posts')
          .doc(post.postId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const SizedBox.shrink();
        }

        var postData = snapshot.data!;
        List<String> likes = List<String>.from(postData['likes'] ?? []);
        bool isLiked = likes.contains(FirebaseAuth.instance.currentUser!.uid);
        int likeCount = likes.length;
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PostDetailScreen(
                  post: post,
                  isLiked: isLiked,
                  likeCount: likeCount,
                  postService: postService,
                  toggleLike: toggleLike,
                ),
              ),
            );
          },
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.zero,
            ),
            clipBehavior: Clip.none,
            color: const Color.fromARGB(255, 31, 34, 34),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.content,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 226, 229, 233),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),

                // Hiển thị hình ảnh (
                if (post.imageUrls != null && post.imageUrls!.isNotEmpty)
                  Center(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: post.imageUrls!.map((imageUrl) {
                        return buildImagePreview(context, imageUrl);
                      }).toList(),
                    ),
                  ),

                // Hiển thị video
                if (post.videoUrl != null)
                  buildVideoPreview(context, post.videoUrl!),

                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16),
                  child: Column(
                    children: [
                      // Hiển thị âm thanh (nếu có)
                      if (post.voiceChatUrl != null)
                        _buildAudioPreview(post.voiceChatUrl!),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            formatTimestamp(post.timestamp.toDate()),
                            style: const TextStyle(
                                fontSize: 14, color: Colors.grey),
                          ),

                          // Like Section
                          InkWell(
                            onTap: toggleLike,
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.transparent,
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    "$likeCount",
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Color.fromARGB(255, 226, 229, 233),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Icon(
                                    isLiked
                                        ? Icons.thumb_up
                                        : Icons.thumb_up_off_alt,
                                    color: isLiked ? Colors.blue : Colors.grey,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 6),
                                  const Text(
                                    "Thích",
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Color.fromARGB(255, 226, 229, 233),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Comment Section
                          InkWell(
                            onTap: () => showModalBottomSheet(
                              backgroundColor: Color.fromARGB(255, 37, 39, 40),
                              context: context,
                              isScrollControlled: true,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.zero,
                              ),
                              builder: (context) => StatefulBuilder(
                                builder: (context, setModalState) {
                                  return DraggableScrollableSheet(
                                    initialChildSize: 1,
                                    minChildSize: 0.4,
                                    maxChildSize: 1,
                                    expand: false,
                                    builder: (context, scrollController) {
                                      return buildCommentSection(
                                        post,
                                        context,
                                        isCommenting: isCommenting.value,
                                        controller: _commentController,
                                        isLiked: isLiked,
                                        likeCount: likeCount,
                                        addComment: addComment,
                                        scrollController: scrollController,
                                        toggleLike: () {
                                          toggleLike();
                                          setModalState(() {}); //
                                        },
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.transparent,
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.comment,
                                      color: Color.fromARGB(214, 226, 229, 233),
                                      size: 20),
                                  const SizedBox(width: 6),
                                  const Text(
                                    "Bình luận",
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Color.fromARGB(255, 226, 229, 233),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
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
  }

  /// Widget hiển thị âm thanh từ URL
  Widget _buildAudioPreview(String audioUrl) {
    return AudioPlayerWidget(audioUrl: audioUrl);
  }
}

/// Widget để phát âm thanh từ URL
class AudioPlayerWidget extends StatefulWidget {
  final String audioUrl;
  const AudioPlayerWidget({Key? key, required this.audioUrl}) : super(key: key);

  @override
  _AudioPlayerWidgetState createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool isPlaying = false;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.audiotrack, size: 30),
        const SizedBox(width: 8),
        Text(
          "Tệp âm thanh",
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        IconButton(
          icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
          onPressed: () async {
            if (isPlaying) {
              await _audioPlayer.pause();
            } else {
              await _audioPlayer.play(UrlSource(widget.audioUrl));
            }
            setState(() {
              isPlaying = !isPlaying;
            });
          },
        ),
      ],
    );
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}

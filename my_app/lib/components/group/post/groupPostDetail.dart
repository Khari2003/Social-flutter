import 'package:flutter/material.dart';
import 'package:my_app/components/group/post/postWidget.dart';
import 'package:my_app/model/group/posting.dart';
import 'package:my_app/services/auth/authService.dart';
import 'package:my_app/services/group/groupPostingService.dart';

class PostDetailScreen extends StatefulWidget {
  final Posting post;
  final bool isLiked;
  final int likeCount;
  final GroupPostingService postService;
  final VoidCallback? toggleLike;

  const PostDetailScreen(
      {Key? key,
      required this.post,
      required this.isLiked,
      required this.likeCount,
      required this.postService,
      required this.toggleLike})
      : super(key: key);

  @override
  _PostDetailScreenState createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  late bool isLiked;
  late int likeCount;
  final Authservice auth = Authservice();
  final TextEditingController _commentController = TextEditingController();
  bool isCommenting = false;
  String? email;

  @override
  void initState() {
    super.initState();
    isLiked = widget.isLiked; // Gán giá trị ban đầu
    likeCount = widget.likeCount;
    _fetchEmail();
  }

  Future<void> _fetchEmail() async {
    String? fetchedEmail = await auth.getEmailById(widget.post.userId);
    setState(() {
      email = fetchedEmail;
      email = email!.contains('@') ? email!.split('@')[0] : email;
    });
  }

  void toggleLike() {
    widget.toggleLike?.call(); // Gọi toggleLike từ GroupPostCard

    setState(() {
      isLiked = !isLiked;
      likeCount += isLiked ? 1 : -1;
    });
  }

  void addComment() async {
    if (_commentController.text.isNotEmpty && !isCommenting) {
      setState(() {
        isCommenting = true; // Bắt đầu gửi bình luận
      });

      try {
        await widget.postService.addComment(
          widget.post.groupId,
          widget.post.postId,
          _commentController.text,
        );
        setState(() {
          widget.post.comments.add(_commentController.text);
        });
        _commentController.clear();
      } catch (e) {
        print("Lỗi khi gửi bình luận: $e");
      } finally {
        setState(() {
          isCommenting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 37, 39, 40),
      appBar: AppBar(
        title: Text("$email"),
        backgroundColor: Color.fromARGB(255, 37, 39, 40),
        titleTextStyle: const TextStyle(
            fontSize: 22, color: Color.fromARGB(255, 226, 229, 233)),
        iconTheme: const IconThemeData(
          color: Color.fromARGB(255, 226, 229, 233),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nội dung bài viết
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nội dung bài viết
                  Text(
                    widget.post.content,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 226, 229, 233)),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),

            // Hiển thị hình ảnh
            if (widget.post.imageUrls != null &&
                widget.post.imageUrls!.isNotEmpty)
              Center(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: widget.post.imageUrls!.map((imageUrl) {
                    return buildImagePreview(context, imageUrl);
                  }).toList(),
                ),
              ),

            // Hiển thị video nếu có
            if (widget.post.videoUrl != null)
              buildVideoPreview(
                context,
                widget.post.videoUrl!,
              ),

            const SizedBox(height: 8),

            // Hiển thị âm thanh nếu có
            if (widget.post.voiceChatUrl != null)
              buildAudioPreview(widget.post.voiceChatUrl!),

            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ngày đăng
                  Text(
                    "Đăng vào: ${widget.post.timestamp.toDate()}",
                    style: const TextStyle(
                        fontSize: 12,
                        color: Color.fromARGB(255, 226, 229, 233)),
                  ),

                  const SizedBox(height: 16),
                  const Divider(color: Color.fromARGB(255, 74, 74, 76)),
                  // Nút like + số lượt like
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(
                          isLiked ? Icons.thumb_up : Icons.thumb_up_off_alt,
                          color: isLiked ? Colors.blue : Colors.grey,
                        ),
                        onPressed: toggleLike,
                      ),
                      // Share Button
                      IconButton(
                        icon: Icon(Icons.share, color: Colors.grey[500], size: 22),
                        onPressed: null,
                      ),
                      // Save Button
                      IconButton(
                        icon: Icon(Icons.bookmark_border, color: Colors.grey[500], size: 22),
                        onPressed: null,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Bình luận
            buildCommentSection(widget.post, context,
                isComment: false, isfullheight: false),
          ],
        ),
      ),
      bottomNavigationBar: buildCommentInput(
          controller: _commentController,
          isCommenting: isCommenting,
          addComment: addComment),
    );
  }
}

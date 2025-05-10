import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:my_app/components/group/post/postWidget.dart';
import 'package:my_app/model/group/posting.dart';
import 'package:my_app/services/auth/authService.dart';
import 'package:my_app/services/group/groupPostingService.dart';
import 'package:my_app/components/group/post/ImageGalleryScreen.dart';

class PostDetailScreen extends StatefulWidget {
  final Posting post;
  final bool isLiked;
  final int likeCount;
  final bool isSaved;
  final GroupPostingService postService;
  final VoidCallback? toggleLike;
  final VoidCallback? toggleSave;

  const PostDetailScreen({
    Key? key,
    required this.post,
    required this.isLiked,
    required this.likeCount,
    required this.isSaved,
    required this.postService,
    required this.toggleLike,
    required this.toggleSave,
  }) : super(key: key);

  @override
  _PostDetailScreenState createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  late bool isLiked;
  late bool isSaved;
  late int likeCount;
  final Authservice auth = Authservice();
  final TextEditingController _commentController = TextEditingController();
  bool isCommenting = false;
  String? email;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    isLiked = widget.isLiked;
    isSaved = widget.isSaved;
    likeCount = widget.likeCount;
    _fetchEmail();
    // Log để kiểm tra imageUrls nhận được
    print("PostDetailScreen received imageUrls: ${widget.post.imageUrls}");
  }

  Future<void> _fetchEmail() async {
    String? fetchedEmail = await auth.getEmailById(widget.post.userId);
    setState(() {
      email = fetchedEmail;
      email = email != null && email!.contains('@') ? email!.split('@')[0] : email;
    });
  }

  void toggleLike() {
    widget.toggleLike?.call();
    setState(() {
      isLiked = !isLiked;
      likeCount += isLiked ? 1 : -1;
    });
  }

  void toggleSave() {
    widget.toggleSave?.call();
    setState(() {
      isSaved = !isSaved;
    });
  }

  void addComment() async {
    if (_commentController.text.isNotEmpty && !isCommenting) {
      setState(() {
        isCommenting = true;
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi gửi bình luận: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      } finally {
        setState(() {
          isCommenting = false;
        });
      }
    }
  }

  void _showImageGallery(BuildContext context, List<String> imageUrls, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImageGalleryScreen(
          imageUrls: imageUrls,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF252728),
      appBar: AppBar(
        title: Text(email ?? 'Ẩn danh'),
        backgroundColor: const Color(0xFF252728),
        titleTextStyle: const TextStyle(
          fontSize: 22,
          color: Color(0xFFE2E5E9),
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(
          color: Color(0xFFE2E5E9),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nội dung bài viết
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.post.content,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFFE2E5E9),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),

            // Hiển thị hình ảnh
            if (widget.post.imageUrls != null && widget.post.imageUrls!.isNotEmpty)
              Container(
                height: 300, // Fixed height for the gallery
                margin: const EdgeInsets.symmetric(horizontal: 8),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PageView.builder(
                      itemCount: widget.post.imageUrls!.length,
                      onPageChanged: (index) {
                        setState(() {
                          _currentImageIndex = index;
                        });
                      },
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () => _showImageGallery(
                            context,
                            widget.post.imageUrls!,
                            index,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: CachedNetworkImage(
                                  imageUrl: widget.post.imageUrls![index],
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    color: Colors.grey[800],
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                        color: Colors.blueAccent,
                                        strokeWidth: 3,
                                      ),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) => Container(
                                    color: Colors.grey[800],
                                    child: const Center(
                                      child: Icon(
                                        Icons.error_outline,
                                        color: Colors.redAccent,
                                        size: 50,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    if (widget.post.imageUrls!.length > 1)
                      Positioned(
                        bottom: 10,
                        child: DotsIndicator(
                          currentIndex: _currentImageIndex,
                          itemCount: widget.post.imageUrls!.length,
                        ),
                      ),
                  ],
                ),
              ),

            // Hiển thị video nếu có
            if (widget.post.videoUrl != null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: buildVideoPreview(context, widget.post.videoUrl!),
                ),
              ),

            // Hiển thị âm thanh nếu có
            if (widget.post.voiceChatUrl != null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: buildAudioPreview(widget.post.voiceChatUrl!),
              ),

            const SizedBox(height: 16),

            // Metadata và hành động
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Đăng vào: ${widget.post.timestamp.toDate()}",
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFFE2E5E9),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Color(0xFF4A4A4C)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              isLiked ? Icons.thumb_up : Icons.thumb_up_off_alt,
                              color: isLiked ? Colors.blueAccent : Colors.grey[500],
                              size: 24,
                            ),
                            onPressed: toggleLike,
                          ),
                          if (likeCount > 0)
                            Text(
                              '$likeCount',
                              style: TextStyle(
                                color: isLiked ? Colors.blueAccent : Colors.grey[500],
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.share, color: Colors.grey, size: 24),
                        onPressed: null, // Implement share logic if needed
                      ),
                      IconButton(
                        icon: Icon(
                          isSaved ? Icons.bookmark : Icons.bookmark_border,
                          color: isSaved ? Colors.yellow : Colors.grey[500],
                          size: 24,
                        ),
                        onPressed: toggleSave,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Bình luận
            buildCommentSection(widget.post, context, isComment: false, isfullheight: false),
          ],
        ),
      ),
      bottomNavigationBar: buildCommentInput(
        controller: _commentController,
        isCommenting: isCommenting,
        addComment: addComment,
      ),
    );
  }
}

// DotsIndicator from ImageGalleryScreen
class DotsIndicator extends StatelessWidget {
  final int currentIndex;
  final int itemCount;

  const DotsIndicator({
    Key? key,
    required this.currentIndex,
    required this.itemCount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(itemCount, (index) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: currentIndex == index ? 12 : 8,
          height: currentIndex == index ? 12 : 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: currentIndex == index ? Colors.blueAccent : Colors.grey.withOpacity(0.5),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
          ),
        );
      }),
    );
  }
}
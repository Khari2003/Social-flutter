import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:my_app/components/group/homepage/share_post_dialog.dart';
import 'package:my_app/components/group/menu/ProfileScreen.dart';
import 'package:my_app/components/group/post/groupPostDetail.dart';
import 'package:my_app/components/group/post/postWidget.dart';
import 'package:my_app/services/auth/authService.dart';
import 'package:my_app/services/group/groupPostingService.dart';
import 'package:intl/intl.dart';
import 'package:my_app/model/group/posting.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:my_app/components/group/post/ImageGalleryScreen.dart';

class GroupPostCard extends StatefulWidget {
  final Posting post;
  final GroupPostingService postService;

  const GroupPostCard({
    Key? key,
    required this.post,
    required this.postService,
  }) : super(key: key);

  @override
  _GroupPostCardState createState() => _GroupPostCardState();
}

class _GroupPostCardState extends State<GroupPostCard>  with AutomaticKeepAliveClientMixin {
  final TextEditingController _commentController = TextEditingController();
  final ValueNotifier<bool> isCommenting = ValueNotifier(false);
  final Authservice auth = Authservice();
  String? name;
  String? email;
  String? avatarUrl;
  bool isSaved = false;
  bool isLoadingAvatar = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _checkSavedStatus();
  }

  Future<void> _fetchUserData() async {
    try {
      print("Fetching user data for userId: ${widget.post.userId}");
      final user = await auth.getUserById(widget.post.userId);
      print("User data fetched: $user");
      setState(() {
        email = user?.userEmail;
        email = email != null && email!.contains('@')
            ? email!.split('@')[0]
            : user?.fullName ?? 'Ẩn danh';
        name = user?.fullName;
        avatarUrl = user?.avatarUrl;
        isLoadingAvatar = false;
        print("Avatar URL: $avatarUrl");
      });
    } catch (e) {
      print("Error fetching user data: $e");
      setState(() {
        email = 'Ẩn danh';
        avatarUrl = null;
        isLoadingAvatar = false;
      });
    }
  }

  Future<void> _checkSavedStatus() async {
    try {
      List<String> savedPosts = await auth.getSavedPosts();
      setState(() {
        isSaved = savedPosts.contains(widget.post.postId);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text('Lỗi khi kiểm tra trạng thái lưu: $e',
              style: const TextStyle(color: Colors.white)),
        ),
      );
    }
  }

  void toggleLike() {
    widget.postService.likePost(widget.post.groupId, widget.post.postId);
  }

  void deletePost() async {
    try {
      await widget.postService
          .deletePost(widget.post.groupId, widget.post.postId);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text('Lỗi khi xóa bài đăng: $e',
              style: const TextStyle(color: Colors.white)),
        ),
      );
    }
  }

  void toggleSave() async {
    try {
      if (isSaved) {
        await auth.unsavePost(widget.post.postId);
      } else {
        await auth.savePost(widget.post.postId);
      }
      setState(() {
        isSaved = !isSaved;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text('Lỗi khi lưu bài đăng: $e',
              style: const TextStyle(color: Colors.white)),
        ),
      );
    }
  }

  void addComment() async {
    if (_commentController.text.isNotEmpty && !isCommenting.value) {
      isCommenting.value = true;
      try {
        await widget.postService.addComment(
          widget.post.groupId,
          widget.post.postId,
          _commentController.text,
        );
        widget.post.comments.add(_commentController.text);
        _commentController.clear();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text('Lỗi khi gửi bình luận: $e',
                style: const TextStyle(color: Colors.white)),
          ),
        );
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

  void _showImageGallery(
      BuildContext context, List<String> imageUrls, int initialIndex) {
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

  Widget _buildImageWidget(String imageUrl, double width, double height) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        width: width,
        height: height,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          width: width,
          height: height,
          color: Colors.grey[800],
          child: const Center(
              child: CircularProgressIndicator(color: Colors.blueAccent)),
        ),
        errorWidget: (context, url, error) => Container(
          width: width,
          height: height,
          color: Colors.grey[800],
          child: const Icon(Icons.error, color: Colors.redAccent),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    if (isLoadingAvatar) {
      return CircleAvatar(
        radius: 20,
        backgroundColor: Colors.grey[800],
        child: const CircularProgressIndicator(
          color: Colors.blueAccent,
          strokeWidth: 2,
        ),
      );
    }
    return CircleAvatar(
      radius: 20,
      backgroundColor: Colors.grey[800],
      child: avatarUrl != null
          ? ClipOval(
              child: CachedNetworkImage(
                imageUrl: avatarUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) => const CircularProgressIndicator(
                  color: Colors.blueAccent,
                  strokeWidth: 2,
                ),
                errorWidget: (context, url, error) => const Icon(
                  Icons.person_outline,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            )
          : const Icon(
              Icons.person_outline,
              color: Colors.white,
              size: 24,
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.post.groupId)
          .collection('posts')
          .doc(widget.post.postId)
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
                  post: widget.post,
                  isLiked: isLiked,
                  likeCount: likeCount,
                  isSaved: isSaved,
                  postService: widget.postService,
                  toggleLike: toggleLike,
                  toggleSave: toggleSave,
                ),
              ),
            );
          },
          child: Card(
            color: const Color(0xFF2A2A2A),
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProfileScreen(
                                userId: widget.post.userId,
                                groupId: widget.post.groupId,
                              ),
                            ),
                          );
                        },
                        child: _buildAvatar(),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name ?? 'Ẩn danh',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontSize: 15,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              formatTimestamp(widget.post.timestamp.toDate()),
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_horiz,
                            color: Colors.white, size: 22),
                        color: const Color(0xFF3A3A3A),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        onSelected: (value) {
                          if (value == 'delete' &&
                              widget.post.userId ==
                                  FirebaseAuth.instance.currentUser!.uid) {
                            deletePost();
                          }
                        },
                        itemBuilder: (context) => [
                          if (widget.post.userId ==
                              FirebaseAuth.instance.currentUser!.uid)
                            PopupMenuItem<String>(
                              value: 'delete',
                              child: Text('Xóa bài đăng',
                                  style: TextStyle(color: Colors.white)),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: Text(
                    widget.post.content,
                    style: const TextStyle(
                        fontSize: 15, color: Colors.white, height: 1.4),
                  ),
                ),
                if (widget.post.imageUrls != null &&
                    widget.post.imageUrls!.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.fromLTRB(0, 4, 0, 4),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final imageCount = widget.post.imageUrls!.length;
                        // final totalWidth = constraints.maxWidth;
                        if (imageCount == 1) {
                          return GestureDetector(
                            onTap: () => _showImageGallery(
                                context, widget.post.imageUrls!, 0),
                            child: FutureBuilder<Size>(
                              future:
                                  _getImageSize(widget.post.imageUrls!.first),
                              builder: (context, snapshot) {
                                if (snapshot.hasData) {
                                  final size = snapshot.data!;
                                  final aspectRatio = size.height / size.width;
                                  final height =
                                      aspectRatio > 1.2 ? 500.0 : 300.0;
                                  return _buildImageWidget(
                                      widget.post.imageUrls!.first,
                                      double.infinity,
                                      height);
                                }
                                return _buildImageWidget(
                                    widget.post.imageUrls!.first,
                                    double.infinity,
                                    300);
                              },
                            ),
                          );
                        } else if (imageCount == 2) {
                          return Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => _showImageGallery(
                                      context, widget.post.imageUrls!, 0),
                                  child: _buildImageWidget(
                                      widget.post.imageUrls![0],
                                      double.infinity,
                                      200),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => _showImageGallery(
                                      context, widget.post.imageUrls!, 1),
                                  child: _buildImageWidget(
                                      widget.post.imageUrls![1],
                                      double.infinity,
                                      200),
                                ),
                              ),
                            ],
                          );
                        } else {
                          final remainingImages = imageCount - 2;
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 2,
                                child: GestureDetector(
                                  onTap: () => _showImageGallery(
                                      context, widget.post.imageUrls!, 0),
                                  child: _buildImageWidget(
                                      widget.post.imageUrls![0],
                                      double.infinity,
                                      300),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                flex: 1,
                                child: Column(
                                  children: [
                                    GestureDetector(
                                      onTap: () => _showImageGallery(
                                          context, widget.post.imageUrls!, 1),
                                      child: _buildImageWidget(
                                          widget.post.imageUrls![1],
                                          double.infinity,
                                          148),
                                    ),
                                    const SizedBox(height: 4),
                                    Stack(
                                      children: [
                                        GestureDetector(
                                          onTap: () => _showImageGallery(
                                              context,
                                              widget.post.imageUrls!,
                                              2),
                                          child: _buildImageWidget(
                                              widget.post.imageUrls!.length > 2
                                                  ? widget.post.imageUrls![2]
                                                  : widget.post.imageUrls![1],
                                              double.infinity,
                                              148),
                                        ),
                                        if (remainingImages > 1)
                                          Positioned.fill(
                                            child: GestureDetector(
                                              onTap: () => _showImageGallery(
                                                  context,
                                                  widget.post.imageUrls!,
                                                  2),
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: Colors.black
                                                      .withOpacity(0.5),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: const Center(
                                                  child: Text(
                                                    'Xem thêm',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }
                      },
                    ),
                  ),
                if (widget.post.videoUrl != null)
                  Container(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: buildVideoPreview(context, widget.post.videoUrl!,
                          limitHeight: true),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      InkWell(
                        onTap: toggleLike,
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 6),
                          child: Row(
                            children: [
                              Icon(
                                isLiked
                                    ? Icons.thumb_up
                                    : Icons.thumb_up_off_alt,
                                color: isLiked
                                    ? Colors.blueAccent
                                    : Colors.grey[500],
                                size: 22,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                likeCount > 0 ? '$likeCount' : '',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isLiked
                                      ? Colors.blueAccent
                                      : Colors.grey[400],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () => showModalBottomSheet(
                          backgroundColor: const Color(0xFF2A2A2A),
                          context: context,
                          isScrollControlled: true,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(16))),
                          builder: (context) => StatefulBuilder(
                            builder: (context, setModalState) {
                              return DraggableScrollableSheet(
                                initialChildSize: 0.7,
                                minChildSize: 0.4,
                                maxChildSize: 0.9,
                                expand: false,
                                builder: (context, scrollController) {
                                  return buildCommentSection(
                                    widget.post,
                                    context,
                                    isCommenting: isCommenting.value,
                                    controller: _commentController,
                                    isLiked: isLiked,
                                    likeCount: likeCount,
                                    addComment: addComment,
                                    scrollController: scrollController,
                                    toggleLike: () {
                                      toggleLike();
                                      setModalState(() {});
                                    },
                                  );
                                },
                              );
                            },
                          ),
                        ),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 6),
                          child: Row(
                            children: [
                              Icon(Icons.comment,
                                  color: Colors.grey[500], size: 22),
                              const SizedBox(width: 6),
                              Text(
                                'Bình luận',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[400],
                                    fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.share,
                            color: Colors.grey[500], size: 22),
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) => SharePostWidget(
                              post: widget.post,
                              postOwnerName: email ?? 'Ẩn danh',
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: Icon(
                          isSaved ? Icons.bookmark : Icons.bookmark_border,
                          color: isSaved ? Colors.yellow : Colors.grey[500],
                          size: 22,
                        ),
                        onPressed: toggleSave,
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

  Future<Size> _getImageSize(String url) async {
    final image = Image.network(url);
    final completer = Completer<Size>();
    image.image.resolve(const ImageConfiguration()).addListener(
          ImageStreamListener(
            (ImageInfo info, bool synchronousCall) {
              completer.complete(Size(
                  info.image.width.toDouble(), info.image.height.toDouble()));
            },
            onError: (exception, stackTrace) {
              completer.complete(const Size(1, 1));
            },
          ),
        );
    return completer.future;
  }
}

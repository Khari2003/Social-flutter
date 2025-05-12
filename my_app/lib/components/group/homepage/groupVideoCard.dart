import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_app/components/group/post/postWidget.dart';
import 'package:my_app/model/group/posting.dart';
import 'package:my_app/services/auth/authService.dart';
import 'package:my_app/services/group/groupPostingService.dart';
import 'package:video_player/video_player.dart';
import 'package:my_app/components/group/homepage/share_post_dialog.dart'; // Import SharePostWidget

class GroupVideoCard extends StatefulWidget {
  final Posting post;
  final GroupPostingService postService;

  const GroupVideoCard({
    Key? key,
    required this.post,
    required this.postService,
  }) : super(key: key);

  @override
  _GroupVideoCardState createState() => _GroupVideoCardState();
}

class _GroupVideoCardState extends State<GroupVideoCard>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _commentController = TextEditingController();
  final ValueNotifier<bool> isCommenting = ValueNotifier(false);
  final Authservice auth = Authservice();
  String? email;
  late VideoPlayerController _controller;
  bool _isSeeking = false;
  double _videoPosition = 0;
  bool isSaved = false;
  bool isLiked = false;
  int likeCount = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _fetchEmail();
    _checkSavedStatus();
    _controller = VideoPlayerController.network(widget.post.videoUrl!)
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
        _controller.addListener(() {
          if (!_isSeeking && _controller.value.isInitialized) {
            setState(() {
              _videoPosition =
                  _controller.value.position.inMilliseconds.toDouble();
            });
          }
        });
      });
  }

  Future<void> _fetchEmail() async {
    String? fetchedEmail = await auth.getEmailById(widget.post.userId);
    setState(() {
      email = fetchedEmail;
      email = email != null && email!.contains('@')
          ? email!.split('@')[0]
          : email ?? 'Ẩn danh';
    });
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
          content: Text('Lỗi khi kiểm tra trạng thái lưu: $e'),
        ),
      );
    }
  }

  void toggleLike() {
    widget.postService.likePost(widget.post.groupId, widget.post.postId);
    setState(() {
      isLiked = !isLiked;
      likeCount += isLiked ? 1 : -1;
    });
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
          content: Text('Lỗi khi lưu bài đăng: $e'),
        ),
      );
    }
  }

  void _sharePost() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SharePostWidget( // Thay SharePostDialog bằng SharePostWidget
        post: widget.post,
        postOwnerName: email ?? 'Ẩn danh',
      ),
    );
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

  void _seekTo(double value) {
    final position = Duration(milliseconds: value.toInt());
    _controller.seekTo(position);
    _controller.play();
  }

  @override
  void dispose() {
    _controller.dispose();
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
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
        isLiked = likes.contains(FirebaseAuth.instance.currentUser!.uid);
        likeCount = likes.length;

        final screenSize = MediaQuery.of(context).size;
        final buttonSize = screenSize.width * 0.08;

        return GestureDetector(
          child: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            clipBehavior: Clip.none,
            color: const Color(0xFF2A2A2A),
            child: SizedBox.expand(
              child: Stack(
                children: [
                  Center(
                    child: buildVideoPreview(
                      context,
                      widget.post.videoUrl!,
                      controller: _controller,
                    ),
                  ),
                  Positioned(
                    right: 8,
                    bottom: 40,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: toggleLike,
                          icon: Icon(
                            isLiked ? Icons.thumb_up : Icons.thumb_up_off_alt,
                            color: isLiked ? Colors.blueAccent : Colors.grey[500],
                            size: buttonSize,
                          ),
                        ),
                        Text(
                          likeCount > 0 ? '$likeCount' : '0',
                          style: TextStyle(color: Colors.grey[400], fontSize: 12),
                        ),
                        const SizedBox(height: 12),
                        IconButton(
                          onPressed: () => showModalBottomSheet(
                            backgroundColor: const Color(0xFF2A2A2A),
                            context: context,
                            isScrollControlled: true,
                            shape: const RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.vertical(top: Radius.circular(16)),
                            ),
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
                                      isfullheight: false,
                                      addComment: addComment,
                                      scrollController: scrollController,
                                      toggleLike: () {
                                        toggleLike();
                                        setModalState(() {});
                                      },
                                      commentStream: widget.postService.getComments(
                                        widget.post.groupId,
                                        widget.post.postId),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                          icon: Icon(
                            Icons.mode_comment_outlined,
                            color: Colors.grey[500],
                            size: buttonSize,
                          ),
                        ),
                        Text(
                          widget.post.comments.isNotEmpty
                              ? '${widget.post.comments.length}'
                              : '0',
                          style: TextStyle(color: Colors.grey[400], fontSize: 12),
                        ),
                        const SizedBox(height: 12),
                        IconButton(
                          icon: Icon(
                            Icons.share,
                            color: Colors.grey[500],
                            size: buttonSize,
                          ),
                          onPressed: _sharePost,
                        ),
                        const SizedBox(height: 12),
                        IconButton(
                          icon: Icon(
                            isSaved ? Icons.bookmark : Icons.bookmark_border,
                            color: isSaved ? Colors.yellow : Colors.grey[500],
                            size: buttonSize,
                          ),
                          onPressed: toggleSave,
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 16,
                    left: 12,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          email ?? 'Ẩn danh',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          width: screenSize.width * 0.7,
                          child: Text(
                            widget.post.content,
                            style: TextStyle(
                              color: Colors.grey[300],
                              fontSize: 14,
                              overflow: TextOverflow.ellipsis,
                            ),
                            maxLines: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    left: 12,
                    right: 12,
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        thumbShape: RoundSliderThumbShape(
                          enabledThumbRadius: _isSeeking ? 6 : 0,
                        ),
                        trackHeight: 2,
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                      ),
                      child: Slider(
                        min: 0.0,
                        max: _controller.value.duration.inMilliseconds.toDouble(),
                        value: _isSeeking
                            ? _videoPosition
                            : _controller.value.position.inMilliseconds.toDouble(),
                        onChanged: (value) {
                          setState(() {
                            _isSeeking = true;
                            _videoPosition = value;
                          });
                        },
                        onChangeEnd: (value) {
                          _seekTo(value);
                          setState(() {
                            _isSeeking = false;
                          });
                        },
                        activeColor: Colors.blueAccent,
                        inactiveColor: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
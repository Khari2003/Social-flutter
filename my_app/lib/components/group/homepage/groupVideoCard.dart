import 'package:flutter/material.dart';
import 'package:my_app/components/group/post/postWidget.dart';
import 'package:my_app/services/auth/authService.dart';
import 'package:my_app/services/group/groupPostingService.dart';
import 'package:my_app/model/group/posting.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:video_player/video_player.dart';

class GroupVideoCard extends StatefulWidget {
  final Posting post;
  final GroupPostingService postService;

  const GroupVideoCard(
      {Key? key, required this.post, required this.postService})
      : super(key: key);

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

  @override
  bool get wantKeepAlive => true;

  void initState() {
    super.initState();
    _fetchEmail();
    _controller = VideoPlayerController.network(widget.post.videoUrl!)
      ..initialize().then((_) {
        setState(() {});
        _controller.play();

        // Lắng nghe thời gian chạy
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

  void _seekTo(double value) {
    final position = Duration(milliseconds: value.toInt());
    _controller.seekTo(position);
    _controller.play();
  }

  void toggleLike() {
    widget.postService.likePost(widget.post.groupId, widget.post.postId);
  }

  void addComment() async {
    if (_commentController.text.isNotEmpty && !isCommenting.value) {
      isCommenting.value = true; // Bắt đầu gửi bình luận
      try {
        await widget.postService.addComment(
          widget.post.groupId,
          widget.post.postId,
          _commentController.text,
        );
        widget.post.comments.add(_commentController.text);
        _commentController.clear();
      } catch (e) {
        print("Lỗi khi gửi bình luận: $e");
      } finally {
        isCommenting.value = false;
      }
    }
  }

  Future<void> _fetchEmail() async {
    String? fetchedEmail = await auth.getEmailById(widget.post.userId);
    setState(() {
      email = fetchedEmail;
      email = email!.contains('@') ? email!.split('@')[0] : email;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
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
        bool isLiked = likes.contains(FirebaseAuth.instance.currentUser!.uid);
        int likeCount = likes.length;

        final screenSize = MediaQuery.of(context).size;
        final buttonSize = screenSize.width * 0.08;

        return GestureDetector(
          child: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            clipBehavior: Clip.none,
            color: Colors.black87,
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
                    bottom: screenSize.height * 0.2,
                    right: screenSize.width * 0.01,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () => toggleLike(),
                          icon: Icon(
                            isLiked ? Icons.thumb_up : Icons.favorite_border,
                            color: isLiked ? Colors.blue : Colors.white,
                          ),
                          iconSize: buttonSize,
                        ),
                        Text(
                          likeCount.toString(),
                          style: const TextStyle(color: Colors.white),
                        ),
                        const SizedBox(height: 20),
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
                                  initialChildSize: 0.8,
                                  minChildSize: 0.4,
                                  maxChildSize: 0.8,
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
                                Icon(
                                  Icons.mode_comment_outlined,
                                  color: Colors.white,
                                  size: buttonSize,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    left: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          email ?? '...',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(
                          width: screenSize.width,
                          child: Text(
                            widget.post.content,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: -20,
                    left: 0,
                    right: 0,
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        thumbShape:
                            const RoundSliderThumbShape(enabledThumbRadius: 3),
                      ),
                      child: Slider(
                        min: 0.0,
                        max: _controller.value.duration.inMilliseconds
                            .toDouble(),
                        value: _isSeeking
                            ? _videoPosition
                            : _controller.value.position.inMilliseconds
                                .toDouble(),
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
                        activeColor: Colors.white,
                        inactiveColor: Colors.grey,
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

import 'package:flutter/material.dart';
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
import 'package:my_app/services/group/groupChatService.dart';
import 'package:my_app/services/group/groupService.dart';

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

class _GroupPostCardState extends State<GroupPostCard> {
  final TextEditingController _commentController = TextEditingController();
  final ValueNotifier<bool> isCommenting = ValueNotifier(false);
  final Authservice auth = Authservice();
  String? email;
  bool isSaved = false;

  @override
  void initState() {
    super.initState();
    _fetchEmail();
    _checkSavedStatus();
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
          content: Text('Lỗi khi kiểm tra trạng thái lưu: $e',
              style: const TextStyle(color: Colors.white)),
        ),
      );
    }
  }

  void toggleLike() {
    widget.postService.likePost(widget.post.groupId, widget.post.postId);
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

  void _sharePost() async {
    final GroupService groupService = GroupService();
    final GroupChatService chatService = GroupChatService();
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    // Lấy danh sách nhóm của người dùng
    final userGroupsStream = groupService.getUserGroups();
    final userGroups =
        await userGroupsStream.first.then((snapshot) => snapshot.docs);

    // Lấy danh sách người dùng đã nhắn tin (từ collection private chats)
    final privateChatsSnapshot = await FirebaseFirestore.instance
        .collection('private_chats')
        .where('users', arrayContains: currentUserId)
        .get();
    final privateChatUsers = privateChatsSnapshot.docs.map((doc) {
      final data = doc.data();
      final otherUserId = (data['users'] as List)
          .firstWhere((id) => id != currentUserId) as String;
      return otherUserId;
    }).toList();

    if (userGroups.isEmpty && privateChatUsers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Không có nhóm hoặc người để chia sẻ!")),
      );
      return;
    }

    // Hiển thị danh sách nhóm và người dùng
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Chia sẻ bài đăng"),
        content: Container(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              // Danh sách nhóm
              if (userGroups.isNotEmpty) ...[
                const Text("Nhóm",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                ...userGroups.map((doc) {
                  final groupData = doc.data() as Map<String, dynamic>;
                  final groupId = doc.id;
                  final groupName = groupData['groupName'] as String;
                  return ListTile(
                    title: Text(groupName),
                    onTap: () async {
                      try {
                        String shareContent = widget.post.content;
                        String? shareImage =
                            widget.post.imageUrls?.isNotEmpty == true
                                ? widget.post.imageUrls!.first
                                : null;
                        String? shareVideo = widget.post.videoUrl;
                        // print("videoURL${shareVideo}");
                        await chatService.sendSharePostMessage(
                          groupId,
                          widget.post.postId,
                          widget.post.groupId,
                          shareContent,
                          shareVideo ,
                          shareImage,
                          postOwnerName: email ?? 'Ẩn danh',
                        );
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Đã chia sẻ bài đăng!")),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Lỗi khi chia sẻ: $e")),
                        );
                      }
                    },
                  );
                }).toList(),
                const Divider(),
              ],
              // Danh sách người dùng
              if (privateChatUsers.isNotEmpty) ...[
                const Text("Người dùng",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                ...privateChatUsers.map((userId) {
                  return FutureBuilder<String?>(
                    future: auth.getEmailById(userId),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const SizedBox.shrink();
                      final userEmail = snapshot.data!.split('@')[0];
                      return ListTile(
                        title: Text(userEmail),
                        onTap: () async {
                          try {
                            String shareContent = widget.post.content;
                            String? shareImage =
                                widget.post.imageUrls?.isNotEmpty == true
                                    ? widget.post.imageUrls!.first
                                    : null;
                            String? shareVideo = widget.post.videoUrl;
                            await chatService.sendPrivateMessage(
                              widget.post.groupId,
                              userId,
                              shareContent,
                              sharedImages:
                                  shareImage != null ? [shareImage] : null,
                              videoUrl:
                                  shareVideo, // Pass videoUrl for shared post
                              postOwnerName: email ?? 'Ẩn danh',
                              type: 'share_post',
                              postId: widget.post.postId,
                              originalGroupId: widget.post.groupId,
                            );
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text("Đã chia sẻ bài đăng!")),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Lỗi khi chia sẻ: $e")),
                            );
                          }
                        },
                      );
                    },
                  );
                }).toList(),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Hủy"),
          ),
        ],
      ),
    );
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
                // Header
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
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.grey[800],
                          child: const Icon(Icons.person_outline,
                              color: Colors.white, size: 24),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              email ?? 'Ẩn danh',
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
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                backgroundColor: Colors.redAccent,
                                content: Text(
                                    'Chức năng xóa bài đăng chưa được triển khai',
                                    style: TextStyle(color: Colors.white)),
                              ),
                            );
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
                // Content
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: Text(
                    widget.post.content,
                    style: const TextStyle(
                        fontSize: 15, color: Colors.white, height: 1.4),
                  ),
                ),
                // Media
                if (widget.post.imageUrls != null &&
                    widget.post.imageUrls!.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.fromLTRB(0, 4, 0, 4),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(0),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return Image.network(
                            widget.post.imageUrls!.first,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) {
                                return FutureBuilder<Size>(
                                  future: _getImageSize(
                                      widget.post.imageUrls!.first),
                                  builder: (context, snapshot) {
                                    if (snapshot.hasData) {
                                      final size = snapshot.data!;
                                      final aspectRatio =
                                          size.height / size.width;
                                      final height =
                                          aspectRatio > 1.2 ? 500.0 : 300.0;
                                      return Container(
                                          height: height, child: child);
                                    }
                                    return Container(
                                      height: 300,
                                      color: Colors.grey[800],
                                      child: const Center(
                                          child: CircularProgressIndicator(
                                              color: Colors.blueAccent)),
                                    );
                                  },
                                );
                              }
                              return Container(
                                height: 300,
                                color: Colors.grey[800],
                                child: const Center(
                                    child: CircularProgressIndicator(
                                        color: Colors.blueAccent)),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 300,
                                color: Colors.grey[800],
                                child: const Icon(Icons.error,
                                    color: Colors.redAccent),
                              );
                            },
                          );
                        },
                      ),
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
                // Actions
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Like Button
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
                      // Comment Button
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
                      // Share Button
                      IconButton(
                        icon: Icon(Icons.share,
                            color: Colors.grey[500], size: 22),
                        onPressed: _sharePost,
                      ),
                      // Save Button
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

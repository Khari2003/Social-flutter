import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_app/model/group/posting.dart';
import 'package:my_app/services/auth/authService.dart';
import 'package:my_app/services/group/groupChatService.dart';
import 'package:my_app/services/group/groupService.dart';
import 'package:cached_network_image/cached_network_image.dart';

class SharePostWidget extends StatefulWidget {
  final Posting post;
  final String postOwnerName;
  final VoidCallback? onShareSuccess;

  const SharePostWidget({
    Key? key,
    required this.post,
    required this.postOwnerName,
    this.onShareSuccess,
  }) : super(key: key);

  @override
  _SharePostWidgetState createState() => _SharePostWidgetState();
}

class _SharePostWidgetState extends State<SharePostWidget> {
  final Authservice auth = Authservice();
  final GroupService groupService = GroupService();
  final GroupChatService chatService = GroupChatService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _shareToGroup(String groupId, String groupName) async {
    setState(() {
      _isLoading = true;
    });
    try {
      await chatService.sendSharePostMessage(
        groupId,
        widget.post.postId,
        widget.post.groupId,
        widget.post.content,
        widget.post.videoUrl,
        widget.post.imageUrls,
        postOwnerName: widget.postOwnerName,
      );
      widget.onShareSuccess?.call();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã chia sẻ bài đăng đến $groupName!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi chia sẻ: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _shareToUser(String userId, String userEmail) async {
    setState(() {
      _isLoading = true;
    });
    try {
      await chatService.sendPrivateMessage(
        widget.post.groupId,
        userId,
        widget.post.content,
        sharedImages: widget.post.imageUrls,
        videoUrl: widget.post.videoUrl,
        postOwnerName: widget.postOwnerName,
        type: 'share_post',
        postId: widget.post.postId,
        originalGroupId: widget.post.groupId,
      );
      widget.onShareSuccess?.call();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã chia sẻ bài đăng đến $userEmail!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi chia sẻ: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildAvatar(String? avatarUrl) {
    return CircleAvatar(
      radius: 20,
      backgroundColor: Colors.grey[800],
      child: avatarUrl != null
          ? ClipOval(
              child: CachedNetworkImage(
                imageUrl: avatarUrl,
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
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Color(0xFF2A2A2A),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Stack(
              children: [
                Column(
                  children: [
                    // Thanh kéo
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[600],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    // Tiêu đề
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text(
                        'Chia sẻ bài đăng',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    // Thanh tìm kiếm
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Tìm nhóm hoặc người dùng...',
                          hintStyle: TextStyle(color: Colors.grey[500]),
                          filled: true,
                          fillColor: Colors.grey[900],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.clear, color: Colors.grey[500]),
                                  onPressed: () {
                                    _searchController.clear();
                                  },
                                )
                              : null,
                        ),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: groupService.getUserGroups(),
                        builder: (context, groupSnapshot) {
                          return FutureBuilder<QuerySnapshot>(
                            future: FirebaseFirestore.instance
                                .collection('private_chats')
                                .where('users', arrayContains: currentUserId)
                                .get(),
                            builder: (context, chatSnapshot) {
                              if (groupSnapshot.connectionState ==
                                      ConnectionState.waiting ||
                                  !chatSnapshot.hasData) {
                                return const Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.blueAccent,
                                  ),
                                );
                              }

                              final userGroups = groupSnapshot.data?.docs ?? [];
                              final privateChatUsers = chatSnapshot.data!.docs
                                  .map((doc) {
                                    final data = doc.data() as Map<String, dynamic>;
                                    final otherUserId = (data['users'] as List)
                                        .firstWhere((id) => id != currentUserId)
                                        as String;
                                    return otherUserId;
                                  })
                                  .toList();

                              // Fetch user emails and avatars for filtering
                              return FutureBuilder<List<Map<String, dynamic>>>(
                                future: Future.wait(
                                  privateChatUsers.map((userId) async {
                                    final email = await auth.getEmailById(userId);
                                    final user = await auth.getUserById(userId);
                                    return {
                                      'userId': userId,
                                      'email': email?.split('@')[0] ?? 'Unknown',
                                      'avatarUrl': user?.avatarUrl,
                                    };
                                  }),
                                ),
                                builder: (context, userSnapshot) {
                                  if (!userSnapshot.hasData) {
                                    return const Center(
                                      child: CircularProgressIndicator(
                                        color: Colors.blueAccent,
                                      ),
                                    );
                                  }

                                  final userData = userSnapshot.data!;
                                  final filteredGroups = userGroups.where((doc) {
                                    final groupData =
                                        doc.data() as Map<String, dynamic>;
                                    final groupName = groupData['groupName']
                                        .toString()
                                        .toLowerCase();
                                    return groupName.contains(_searchQuery);
                                  }).toList();

                                  final filteredUsers = userData.where((user) {
                                    final email = user['email'].toLowerCase();
                                    return email.contains(_searchQuery);
                                  }).toList();

                                  if (filteredGroups.isEmpty &&
                                      filteredUsers.isEmpty) {
                                    return Center(
                                      child: Text(
                                        'Không tìm thấy nhóm hoặc người dùng',
                                        style: TextStyle(
                                          color: Colors.grey[500],
                                          fontSize: 16,
                                        ),
                                      ),
                                    );
                                  }

                                  return ListView(
                                    controller: scrollController,
                                    children: [
                                      if (filteredGroups.isNotEmpty) ...[
                                        Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                              16, 16, 16, 8),
                                          child: Text(
                                            'Nhóm',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                        ...filteredGroups.map((doc) {
                                          final groupData =
                                              doc.data() as Map<String, dynamic>;
                                          final groupId = doc.id;
                                          final groupName =
                                              groupData['groupName'] as String;
                                          final groupAvatar =
                                              groupData['avatarUrl'] as String?;
                                          return ListTile(
                                            leading: _buildAvatar(groupAvatar),
                                            title: Text(
                                              groupName,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            onTap: _isLoading
                                                ? null
                                                : () =>
                                                    _shareToGroup(groupId, groupName),
                                          );
                                        }).toList(),
                                      ],
                                      if (filteredUsers.isNotEmpty) ...[
                                        Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                              16, 16, 16, 8),
                                          child: Text(
                                            'Người dùng',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                        ...filteredUsers.map((user) {
                                          final userId = user['userId'] as String;
                                          final userEmail = user['email'] as String;
                                          final avatarUrl =
                                              user['avatarUrl'] as String?;
                                          return ListTile(
                                            leading: _buildAvatar(avatarUrl),
                                            title: Text(
                                              userEmail,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            onTap: _isLoading
                                                ? null
                                                : () =>
                                                    _shareToUser(userId, userEmail),
                                          );
                                        }).toList(),
                                      ],
                                    ],
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
                if (_isLoading)
                  Container(
                    color: Colors.black.withOpacity(0.3),
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.blueAccent),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
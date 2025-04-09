import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_app/components/group/homepage/groupSelectionWidget.dart';
import 'package:my_app/components/group/homepage/groupVideoCard.dart';
import 'package:my_app/services/group/groupPostingService.dart';
import 'package:my_app/services/group/groupService.dart';
import 'package:my_app/model/group/posting.dart';
import 'package:provider/provider.dart';
import 'package:my_app/services/auth/authService.dart';
import 'dart:io';

class ReelScreen extends StatefulWidget {
  final ValueNotifier<String?> selectedGroupId;
  final Stream<List<DocumentSnapshot>> postStream;
  final ValueNotifier<List<Map<String, dynamic>>> userGroups;

  const ReelScreen({
    Key? key,
    required this.selectedGroupId,
    required this.postStream,
    required this.userGroups,
  }) : super(key: key);

  @override
  _ReelScreenState createState() => _ReelScreenState();
}

class _ReelScreenState extends State<ReelScreen>
    with AutomaticKeepAliveClientMixin {
  final GroupService _groupService = GroupService();
  final GroupPostingService _groupPostingService = GroupPostingService();
  List<File> selectedImages = [];
  List<File> selectedVideos = [];
  List<File> selectedVoices = [];

  @override
  bool get wantKeepAlive => true;
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void signOut() {
    final authService = Provider.of<Authservice>(context, listen: false);

    authService.signOut();
  }

  // Hiển thị popup tạo nhóm
  void _createGroup() {
    TextEditingController groupNameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Tạo Nhóm"),
        content: TextField(
          controller: groupNameController,
          decoration: const InputDecoration(labelText: "Tên nhóm"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            onPressed: () async {
              String groupName = groupNameController.text.trim();
              if (groupName.isNotEmpty) {
                try {
                  String joinLink = await _groupService.createGroup(groupName);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content:
                            Text("Nhóm đã tạo thành công! Link: $joinLink")),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Lỗi: $e")),
                  );
                }
              }
            },
            child: const Text("Tạo"),
          ),
        ],
      ),
    );
  }

  // Hiển thị popup tham gia nhóm
  void _joinGroup() {
    TextEditingController joinLinkController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Tham Gia Nhóm"),
        content: TextField(
          controller: joinLinkController,
          decoration: const InputDecoration(labelText: "Nhập mã nhóm"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            onPressed: () async {
              String joinLink = joinLinkController.text.trim();
              if (joinLink.isNotEmpty) {
                try {
                  await _groupService.joinGroup(joinLink);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Tham gia nhóm thành công!")),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Lỗi: $e")),
                  );
                }
              }
            },
            child: const Text("Tham Gia"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 0, 0, 0),
      body: Stack(
        children: [
          // Nội dung chính của posts
          Positioned.fill(
            child: Column(
              children: [
                // Nội dung chính
                Expanded(
                  child: widget.userGroups.value.isEmpty
                      ? GroupSelectionWidget(
                          onCreateGroup: _createGroup,
                          onJoinGroup: _joinGroup,
                        )
                      : StreamBuilder<List<DocumentSnapshot>>(
                          stream: widget.postStream,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            }

                            if (!snapshot.hasData || snapshot.data!.isEmpty) {
                              return const Center(
                                child: Text(
                                  "Không có bài đăng nào!",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color.fromARGB(255, 226, 229, 233),
                                  ),
                                ),
                              );
                            }

                            final posts = snapshot.data!
                                .map((doc) => Posting.fromMap(
                                    doc.data() as Map<String, dynamic>))
                                .where((post) =>
                                    post.videoUrl != null &&
                                    post.videoUrl!.isNotEmpty)
                                .map((post) => GroupVideoCard(
                                      post: post,
                                      postService: _groupPostingService,
                                    ))
                                .toList();

                            return PageView.builder(
                              scrollDirection: Axis.vertical,
                              itemCount: posts.length,
                              itemBuilder: (context, index) {
                                return Container(
                                  width: MediaQuery.of(context).size.width,
                                  height: MediaQuery.of(context).size.height,
                                  color: Colors.black, 
                                  child: Center(
                                    child: posts[index],
                                  ),
                                );
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

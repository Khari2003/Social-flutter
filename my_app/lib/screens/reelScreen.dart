import 'package:firebase_auth/firebase_auth.dart';
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
  final ValueNotifier<int> currentIndex;

  const ReelScreen({
    Key? key,
    required this.selectedGroupId,
    required this.postStream,
    required this.userGroups,
    required this.currentIndex,
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
  late PageController _pageController;
  int _currentPage = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _pageController.addListener(() {
      final newPage = _pageController.page?.round() ?? 0;
      if (newPage != _currentPage) {
        setState(() {
          _currentPage = newPage;
        });
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  void signOut() {
    final authService = Provider.of<Authservice>(context, listen: false);
    authService.signOut();
  }

  void _createGroup() {
    TextEditingController groupNameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text("Tạo Nhóm", style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: groupNameController,
          decoration: InputDecoration(
            labelText: "Tên nhóm",
            labelStyle: TextStyle(color: Colors.grey[500]),
            filled: true,
            fillColor: Colors.grey[800],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Hủy", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
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
                  // Refresh group list
                  final snapshot = await FirebaseFirestore.instance
                      .collection('groups')
                      .where('members',
                          arrayContains: FirebaseAuth.instance.currentUser!.uid)
                      .get();
                  widget.userGroups.value = snapshot.docs
                      .map((doc) => {"id": doc.id, "name": doc['groupName']})
                      .toList();
                  if (widget.userGroups.value.isNotEmpty) {
                    widget.selectedGroupId.value =
                        widget.userGroups.value.first['id'];
                  }
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

  void _joinGroup() {
    TextEditingController joinLinkController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title:
            const Text("Tham Gia Nhóm", style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: joinLinkController,
          decoration: InputDecoration(
            labelText: "Nhập mã nhóm",
            labelStyle: TextStyle(color: Colors.grey[500]),
            filled: true,
            fillColor: Colors.grey[800],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Hủy", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              String joinLink = joinLinkController.text.trim();
              if (joinLink.isNotEmpty) {
                try {
                  await _groupService.joinGroup(joinLink);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Tham gia nhóm thành công!")),
                  );
                  // Refresh group list
                  final snapshot = await FirebaseFirestore.instance
                      .collection('groups')
                      .where('members',
                          arrayContains: FirebaseAuth.instance.currentUser!.uid)
                      .get();
                  widget.userGroups.value = snapshot.docs
                      .map((doc) => {"id": doc.id, "name": doc['groupName']})
                      .toList();
                  if (widget.userGroups.value.isNotEmpty) {
                    widget.selectedGroupId.value =
                        widget.userGroups.value.first['id'];
                  }
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
          Positioned.fill(
              child: ValueListenableBuilder<int>(
                  valueListenable: widget.currentIndex,
                  builder: (context, index, child) {
                    final bool isScreenVisible = index == 1;
                    return Column(
                      children: [
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

                                    if (!snapshot.hasData ||
                                        snapshot.data!.isEmpty) {
                                      return const Center(
                                        child: Text(
                                          "Không có bài đăng nào!",
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Color.fromARGB(
                                                255, 226, 229, 233),
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
                                        .toList();

                                    return PageView.builder(
                                      controller: _pageController,
                                      scrollDirection: Axis.vertical,
                                      itemCount: posts.length,
                                      itemBuilder: (context, index) {
                                        return Container(
                                          width:
                                              MediaQuery.of(context).size.width,
                                          height: MediaQuery.of(context)
                                              .size
                                              .height,
                                          color: Colors.black,
                                          child: Center(
                                            child: GroupVideoCard(
                                              post: posts[index],
                                              postService: _groupPostingService,
                                              isVisible: isScreenVisible &&
                                                  _currentPage == index,
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                        ),
                      ],
                    );
                  })),
        ],
      ),
    );
  }
}

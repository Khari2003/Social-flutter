import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_app/components/group/homepage/groupPostCard.dart';
import 'package:my_app/components/group/homepage/groupSelectionWidget.dart';
import 'package:my_app/components/group/homepage/inputArea.dart';
import 'package:my_app/screens/creatPostScreen.dart';
import 'package:my_app/services/group/groupPostingService.dart';
import 'package:my_app/services/group/groupService.dart';
import 'package:my_app/model/group/posting.dart';
import 'package:provider/provider.dart';
import 'package:my_app/services/auth/authService.dart';
import 'dart:io';

class HomePage extends StatefulWidget {
  final ValueNotifier<String?> selectedGroupId;
  final Stream<List<DocumentSnapshot>> postStream;
  final ValueNotifier<List<Map<String, dynamic>>> userGroups;
  final ScrollController scrollController;
  final ValueNotifier<bool> showNavBar;
  final VoidCallback? onGroupChanged;

  const HomePage({
    Key? key,
    required this.selectedGroupId,
    required this.postStream,
    required this.userGroups,
    required this.scrollController,
    required this.showNavBar,
    this.onGroupChanged,
  }) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with AutomaticKeepAliveClientMixin {
  final GroupService _groupService = GroupService();
  final GroupPostingService _groupPostingService = GroupPostingService();
  List<File> selectedImages = [];
  List<File> selectedVideos = [];
  List<File> selectedVoices = [];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearchVisible = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSearchBar() {
    setState(() {
      _isSearchVisible = !_isSearchVisible;
      if (!_isSearchVisible) {
        _searchController.clear();
        _searchQuery = '';
      }
    });
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              String groupName = groupNameController.text.trim();
              if (groupName.isNotEmpty) {
                try {
                  String joinLink = await _groupService.createGroup(groupName);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Nhóm đã tạo thành công! Link: $joinLink")),
                  );
                  widget.onGroupChanged?.call();
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
        title: const Text("Tham Gia Nhóm", style: TextStyle(color: Colors.white)),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                  widget.onGroupChanged?.call();
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

  void _openCreatePostScreen() async {
    bool? result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreatePostScreen(
          onCreatePost: (String content, List<File> images, List<File> videos) async {
            await _groupPostingService.createPost(
              widget.selectedGroupId.value!,
              content,
              images: images,
              videos: videos,
              voices: selectedVoices,
            );
          },
        ),
      ),
    );

    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Bài đăng đã được tạo thành công!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: Colors.black87,
      body: Stack(
        children: [
          Positioned.fill(
            child: Column(
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
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }

                            if (snapshot.hasError) {
                              return const Center(
                                child: Text(
                                  "Lỗi tải bài đăng!",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color.fromARGB(255, 226, 229, 233),
                                  ),
                                ),
                              );
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
                                .map((doc) {
                                  try {
                                    return Posting.fromMap(doc.data() as Map<String, dynamic>);
                                  } catch (e) {
                                    return null;
                                  }
                                })
                                .where((post) => post != null)
                                .cast<Posting>()
                                .toList();

                            final filteredPosts = _searchQuery.isEmpty
                                ? posts
                                : posts.where((post) {
                                    final content = post.content.toLowerCase();
                                    return content.contains(_searchQuery);
                                  }).toList();

                            return ListView(
                              controller: widget.scrollController,
                              cacheExtent: 10000,
                              children: [
                                ValueListenableBuilder<bool>(
                                  valueListenable: widget.showNavBar,
                                  builder: (context, showNavBarValue, child) {
                                    return AnimatedPadding(
                                      duration: const Duration(milliseconds: 200),
                                      padding: EdgeInsets.only(
                                        top: showNavBarValue ? 65 : 0,
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: InputAreaWidget(onTap: _openCreatePostScreen),
                                          ),
                                          const SizedBox(width: 8),
                                          GestureDetector(
                                            onTap: _toggleSearchBar,
                                            child: Container(
                                              width: 48,
                                              height: 48,
                                              decoration: BoxDecoration(
                                                color: Colors.grey[900],
                                                borderRadius: BorderRadius.circular(16),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black.withOpacity(0.2),
                                                    blurRadius: 4,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              child: Icon(
                                                _isSearchVisible ? Icons.search_off : Icons.search,
                                                color: Colors.grey[500],
                                                size: 24,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  height: _isSearchVisible ? 60 : 0,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  child: _isSearchVisible
                                      ? TextField(
                                          controller: _searchController,
                                          onChanged: (value) {
                                            setState(() {
                                              _searchQuery = value.toLowerCase();
                                            });
                                          },
                                          decoration: InputDecoration(
                                            hintText: 'Tìm kiếm bài đăng...',
                                            hintStyle: TextStyle(color: Colors.grey[500]),
                                            filled: true,
                                            fillColor: Colors.grey[900],
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(16),
                                              borderSide: BorderSide.none,
                                            ),
                                            prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
                                            suffixIcon: _searchQuery.isNotEmpty
                                                ? IconButton(
                                                    icon: Icon(Icons.clear, color: Colors.grey[500]),
                                                    onPressed: () {
                                                      _searchController.clear();
                                                      setState(() {
                                                        _searchQuery = '';
                                                      });
                                                    },
                                                  )
                                                : null,
                                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                                          ),
                                          style: const TextStyle(color: Colors.white),
                                        )
                                      : const SizedBox.shrink(),
                                ),
                                if (filteredPosts.isEmpty && _searchQuery.isNotEmpty)
                                  const Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Center(
                                      child: Text(
                                        "Không tìm thấy bài đăng!",
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Color.fromARGB(255, 226, 229, 233),
                                        ),
                                      ),
                                    ),
                                  )
                                else
                                  ...filteredPosts.map((post) => Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                                        child: GroupPostCard(
                                          post: post,
                                          postService: _groupPostingService,
                                        ),
                                      )),
                              ],
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          ValueListenableBuilder<bool>(
            valueListenable: widget.showNavBar,
            builder: (context, show, child) {
              return AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                bottom: show ? 100 : -100,
                right: 20,
                child: GestureDetector(
                  onTap: _openCreatePostScreen,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.add,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
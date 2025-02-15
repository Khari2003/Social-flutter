import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_app/components/group/homepage/groupPostCard.dart';
import 'package:my_app/components/group/homepage/groupSelectionWidget.dart';
import 'package:my_app/screens/chatScreen.dart';
import 'package:my_app/services/group/groupPostingService.dart';
import 'package:my_app/services/group/groupService.dart';
import 'package:my_app/model/group/posting.dart';
import 'package:provider/provider.dart';
import 'package:my_app/services/auth/authService.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _fireStore = FirebaseFirestore.instance;
  final GroupService _groupService = GroupService();
  final GroupPostingService _groupPostingService = GroupPostingService();
  String? selectedGroupId;
  bool _isMinibarOpen = false;
  bool _isMemberSidebarOpen = false;
  List<Map<String, dynamic>> userGroups = [];
  List<Map<String, dynamic>> groupMembers = [];
  List<File> selectedImages = [];
  List<File> selectedVideos = [];
  List<File> selectedVoices = [];


  @override
  void initState() {
    super.initState();
    _fetchUserGroups();
  }

  // Lấy danh sách nhóm mà người dùng tham gia
  Future<void> _fetchUserGroups() async {
    final String userId = _auth.currentUser!.uid;
    final snapshot = await _fireStore
        .collection('groups')
        .where('members', arrayContains: userId)
        .get();

    setState(() {
      userGroups = snapshot.docs
          .map((doc) => {
                "id": doc.id,
                "name": doc['groupName'],
              })
          .toList();
    });

    if (selectedGroupId == null && userGroups.isNotEmpty) {
        selectedGroupId = userGroups.first["id"];
        _fetchGroupMembers(userGroups.first["id"]);
      }
  }

  // Lấy danh sách thành viên của nhóm
  Future<void> _fetchGroupMembers(String groupId) async {
    final DocumentSnapshot groupSnapshot = await _fireStore.collection('groups').doc(groupId).get();
    List<String> memberIds = List<String>.from(groupSnapshot['members']);

    List<Map<String, dynamic>> membersData = [];
    for (String userId in memberIds) {
      DocumentSnapshot userSnapshot = await _fireStore.collection('users').doc(userId).get();
      if (userSnapshot.exists) {
        membersData.add({
          "id": userId,
          "email": userSnapshot["email"] ?? "Người dùng",
          "avatar":  "",
        });
      }
    }

    setState(() {
      groupMembers = membersData;
    });
  }

  void signOut(){
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
                  _fetchUserGroups(); // Cập nhật lại danh sách nhóm
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Nhóm đã tạo thành công! Link: $joinLink")),
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
                  _fetchUserGroups(); // Cập nhật lại danh sách nhóm
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


  //Lấy bài đăng của nhóm đang chọn
  Stream<List<DocumentSnapshot>> _getPostsStream() {
    if (selectedGroupId == null) {
      return const Stream.empty();
    }

    return _fireStore
        .collection('groups')
        .doc(selectedGroupId)
        .collection('posts')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs);
  }

  // Khi nhấn vào nhóm trong minibar
  void _selectGroup(String groupId) {
    setState(() {
      selectedGroupId = groupId;
      _isMinibarOpen = false;
      _fetchGroupMembers(groupId);
    });
  }

  Future<void> _pickMedia(ImageSource source, String type) async {
    final picker = ImagePicker();
    XFile? pickedFile;

    if (type == 'image') {
      pickedFile = await picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() => selectedImages.add(File(pickedFile!.path)));
      }
    } else if (type == 'video') {
      pickedFile = await picker.pickVideo(source: source);
      if (pickedFile != null) {
        setState(() => selectedVideos.add(File(pickedFile!.path)));
      }
    }
  }

  void _createPost() {
  TextEditingController postContentController = TextEditingController();
  bool isPosting = false; // Thêm biến trạng thái

  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: const Text("Tạo bài đăng"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: postContentController,
              decoration: const InputDecoration(labelText: "Nội dung bài đăng"),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.image),
                  onPressed: () async {
                    await _pickMedia(ImageSource.gallery, 'image');
                    setDialogState(() {});
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.video_library),
                  onPressed: () async {
                    await _pickMedia(ImageSource.gallery, 'video');
                    setDialogState(() {});
                  },
                ),
              ],
            ),
            if (selectedImages.isNotEmpty)
              Wrap(
                children: selectedImages.map((image) {
                  return Stack(
                    children: [
                      Image.file(image, width: 80, height: 80, fit: BoxFit.cover),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: IconButton(
                          icon: Icon(Icons.cancel, color: Colors.red),
                          onPressed: () {
                            setState(() => selectedImages.remove(image));
                            setDialogState(() {});
                          },
                        ),
                      )
                    ],
                  );
                }).toList(),
              ),
            if (selectedVideos.isNotEmpty)
              Wrap(
                children: selectedVideos.map((video) {
                  return Stack(
                    children: [
                      Icon(Icons.video_file, size: 80, color: Colors.blue),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: IconButton(
                          icon: Icon(Icons.cancel, color: Colors.red),
                          onPressed: () {
                            setState(() => selectedVideos.remove(video));
                            setDialogState(() {});
                          },
                        ),
                      )
                    ],
                  );
                }).toList(),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            onPressed: isPosting ? null : () async {  // Chặn bấm liên tục
              String content = postContentController.text.trim();
              if (content.isNotEmpty && selectedGroupId != null) {
                setDialogState(() => isPosting = true);  // Bắt đầu gửi bài

                try {
                  await _groupPostingService.createPost(
                    selectedGroupId!,
                    content,
                    images: selectedImages,
                    videos: selectedVideos,
                    voices: selectedVoices,
                  );
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Bài đăng đã được tạo thành công!")),
                  );
                  setState(() {
                    selectedImages.clear();
                    selectedVideos.clear();
                    selectedVoices.clear();
                  });
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Lỗi: $e")),
                  );
                } finally {
                  setDialogState(() => isPosting = false);  // Reset trạng thái dù thành công hay lỗi
                }
              }
            },
            child: isPosting
                ? const SizedBox( // Hiển thị vòng tròn loading
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text("Đăng bài"),
          ),
        ],
      ),
    ),
  );
}


  // Hiển thị minibar danh sách nhóm
  Widget _buildMinibar() {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      right: _isMinibarOpen ? 0 : -200, // Ẩn khi đóng
      top: 0,
      bottom: 0,
      child: Container(
        width: 200,
        color: Colors.white,
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Nhóm của bạn",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _isMinibarOpen = false; // Đóng minibar
                    });
                  },
                  icon: const Icon(Icons.close),
                  tooltip: "Đóng",
                ),
              ],
            ),
            const SizedBox(height: 10),

            Expanded(
              child: ListView.builder(
                itemCount: userGroups.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () => _selectGroup(userGroups[index]["id"]!),
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: selectedGroupId == userGroups[index]["id"]
                            ? Colors.blue
                            : Colors.grey,
                      ),
                      padding: const EdgeInsets.all(15),
                      alignment: Alignment.center,
                      child: Text(
                        userGroups[index]["name"]![0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }


  // Sidebar danh sách thành viên nhóm
  Widget _buildMemberSidebar() {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      left: _isMemberSidebarOpen ? 0 : -250, // Ẩn khi đóng
      top: 0,
      bottom: 0,
      child: Container(
        width: 250,
        color: Colors.white,
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Thành viên nhóm",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _isMemberSidebarOpen = false; // Đóng sidebar
                    });
                  },
                  icon: const Icon(Icons.close),
                  tooltip: "Đóng",
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Group Tổng (Chat chung)
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.blue,
                child: Icon(Icons.group, color: Colors.white),
              ),
              title: const Text("Group Tổng"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(
                      GroupId: selectedGroupId!,
                      type: "group",
                      receiverUserEmail: "Group Tổng",
                      receiverUserID: "",
                    ),
                  ),
                );
              },
            ),

            const Divider(),

            // Danh sách thành viên
            Expanded(
              child: ListView.builder(
                itemCount: groupMembers.length,
                itemBuilder: (context, index) {
                  final member = groupMembers[index];
                  if (member["id"] == _auth.currentUser!.uid) return Container();
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: member["avatar"]!.isNotEmpty
                          ? NetworkImage(member["avatar"]!)
                          : null,
                      child: member["avatar"]!.isEmpty
                          ? const Icon(Icons.person)
                          : null,
                    ),
                    title: Text(member["email"]!),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(
                            GroupId: selectedGroupId!,
                            type: "private",
                            receiverUserEmail: member["email"]!,
                            receiverUserID: member["id"]!,
                          ),
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
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text("Trang Chủ"),
          actions: [
            if (userGroups.isNotEmpty) // Chỉ hiển thị khi có nhóm
              IconButton(
                onPressed: _createGroup,
                icon: const Icon(Icons.add_circle_outline),
                tooltip: "Tạo nhóm",
              ),
            if (userGroups.isNotEmpty) // Chỉ hiển thị khi có nhóm
              IconButton(
                onPressed: _joinGroup,
                icon: const Icon(Icons.group_add),
                tooltip: "Tham gia nhóm",
              ),
            IconButton(
              onPressed: () {
                setState(() {
                  _isMinibarOpen = !_isMinibarOpen;
                });
              },
              icon: const Icon(Icons.group),
              tooltip: "Danh sách nhóm",
            ),
            IconButton(
              onPressed: signOut,
              icon: const Icon(Icons.logout),
              tooltip: "Thoát",
            ),
          ]),
       body: Stack(
        children: [
          // Nội dung chính
          Positioned.fill(
            child: userGroups.isEmpty
                ? GroupSelectionWidget(
                    onCreateGroup: _createGroup,
                    onJoinGroup: _joinGroup,
                  )
                : StreamBuilder<List<DocumentSnapshot>>(
                    stream: _getPostsStream(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(child: Text("Không có bài đăng nào!"));
                      }

                      final posts = snapshot.data!
                          .map((doc) => GroupPostCard(
                                post: Posting.fromMap(doc.data() as Map<String, dynamic>),
                                postService: _groupPostingService,
                              ))
                          .toList();

                      return ListView(children: posts);
                    },
                  ),
          ),

          // Sidebar danh sách thành viên (bên trái)
          _buildMemberSidebar(),

          // Minibar danh sách nhóm (bên phải)
          _buildMinibar(),

          // Nút mở member sidebar (cố định bên trái màn hình)
          Positioned(
            top: 10,
            right: MediaQuery.of(context).size.width * 0.03,
            child: FloatingActionButton(
              onPressed: () {
                setState(() {
                  _isMemberSidebarOpen = !_isMemberSidebarOpen; // Toggle sidebar
                });
              },
              mini: true,
              child: const Icon(Icons.menu),
            ),
          ),
         Positioned(
            bottom: MediaQuery.of(context).size.height * 0.1,
            right: MediaQuery.of(context).size.width * 0.03,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.15, 
              height: MediaQuery.of(context).size.width * 0.15, 
              decoration: BoxDecoration(
                shape: BoxShape.circle, // Hình dạng tròn
              ),
              child: FloatingActionButton(
                onPressed: _createPost,
                mini: false, 
                child: const Icon(Icons.post_add, size: 30), 
              ),
            ),
          ),
        ],
      ),
    );
  }
}

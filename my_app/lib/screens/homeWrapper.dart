import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:my_app/components/group/homepage/groupBar.dart';
import 'package:my_app/components/group/homepage/memberBar.dart';
import 'package:my_app/components/group/homepage/topBar.dart';
import 'package:my_app/screens/chatScreen.dart';
import 'package:my_app/screens/homeScreen.dart';
import 'package:my_app/screens/reelScreen.dart';
import 'package:my_app/screens/MenuScreen.dart';
import 'package:my_app/components/group/menu/savePostScreen.dart';
import 'package:my_app/map/screens/mapScreen.dart';
import 'package:my_app/services/group/groupService.dart';
import 'package:my_app/services/auth/authService.dart';

class HomeWrapper extends StatefulWidget {
  const HomeWrapper({super.key});

  @override
  State<HomeWrapper> createState() => _HomeWrapperState();
}

class _HomeWrapperState extends State<HomeWrapper> {
  final GroupService _groupService = GroupService();
  late PageController _pageController;
  ValueNotifier<int> _currentIndex = ValueNotifier(0);
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _fireStore = FirebaseFirestore.instance;
  bool _isSidebarOpen = false;
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<List<Map<String, dynamic>>> userGroups = ValueNotifier([]);
  final ValueNotifier<String?> selectedGroupId = ValueNotifier(null);
  final ValueNotifier<List<Map<String, dynamic>>> groupMembers = ValueNotifier([]);
  late Stream<List<DocumentSnapshot>> postStream;
  late Stream<List<DocumentSnapshot>> videoStream;
  late List<Widget> _pages;
  late Widget _mapScreen;
  final ValueNotifier<bool> _showNavBar = ValueNotifier(true);
  double _lastOffset = 100;

  @override
  void initState() {
    super.initState();
    _mapScreen = MapScreen();
    _pages = [];
    _scrollController.addListener(_onScroll);
    _fetchUserGroups();
    _pageController = PageController(initialPage: _currentIndex.value);
  }

  void _onScroll() {
    if (_scrollController.offset > _lastOffset && _scrollController.offset > 50) {
      if (_showNavBar.value) {
        setState(() {
          _showNavBar.value = false;
        });
      }
    } else if (_scrollController.offset < _lastOffset) {
      if (!_showNavBar.value) {
        setState(() {
          _showNavBar.value = true;
        });
      }
    }
    _lastOffset = _scrollController.offset;
  }

  void _onNavTap(int index) {
    setState(() {
      _currentIndex.value = index;
    });
    _pageController.jumpToPage(index);
  }

  void _toggleSidebar() {
    setState(() {
      _isSidebarOpen = !_isSidebarOpen;
    });
  }

  void _selectGroup(String groupId) {
    selectedGroupId.value = groupId;
    setState(() {
      _isSidebarOpen = false;
    });
    _fetchGroupMembers(groupId).then((members) {
      groupMembers.value = members;
    });
    postStream = _getPostsStream();
    videoStream = _getPostsStream();

    setState(() {
      _pages = [
        HomePage(
          selectedGroupId: selectedGroupId,
          postStream: postStream,
          userGroups: userGroups,
          scrollController: _scrollController,
          showNavBar: _showNavBar,
          onGroupChanged: _fetchUserGroups,
        ),
        ReelScreen(
          selectedGroupId: selectedGroupId,
          postStream: videoStream,
          userGroups: userGroups,
          currentIndex: _currentIndex
        ),
        MenuScreen(
          onSavedPostsSelected: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SavedPostsScreen()),
            );
          },
        ),
        _mapScreen,
      ];
    });
  }

  Stream<List<DocumentSnapshot>> _getPostsStream() {
    if (selectedGroupId.value == null) {
      return const Stream.empty();
    }
    return _fireStore
        .collection('groups')
        .doc(selectedGroupId.value)
        .collection('posts')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs);
  }

  Future<List<Map<String, dynamic>>> _fetchGroupMembers(String groupId) async {
    final groupSnapshot = await _fireStore.collection('groups').doc(groupId).get();
    List<String> memberIds = List<String>.from(groupSnapshot['members']);

    final userDocs = await _fireStore
        .collection('users')
        .where(FieldPath.documentId, whereIn: memberIds)
        .get();
    return userDocs.docs
        .map((doc) => {"id": doc.id, "email": doc["email"], "fullName": doc["fullName"] ,"avatar": doc['avatarUrl']??""})
        .toList();
  }

  Future<void> _fetchUserGroups() async {
    final String userId = _auth.currentUser!.uid;
    final snapshot = await _fireStore
        .collection('groups')
        .where('members', arrayContains: userId)
        .get();

    userGroups.value = snapshot.docs
        .map((doc) => {"id": doc.id, "name": doc['groupName']})
        .toList();
    if (userGroups.value.isNotEmpty) {
      _selectGroup(userGroups.value.first["id"]);
    } else {
      selectedGroupId.value = null;
      setState(() {
        _pages = [
          HomePage(
            selectedGroupId: selectedGroupId,
            postStream: const Stream.empty(),
            userGroups: userGroups,
            scrollController: _scrollController,
            showNavBar: _showNavBar,
            onGroupChanged: _fetchUserGroups,
          ),
          ReelScreen(
            selectedGroupId: selectedGroupId,
            postStream: const Stream.empty(),
            userGroups: userGroups,
            currentIndex: _currentIndex
          ),
          MenuScreen(
            onSavedPostsSelected: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SavedPostsScreen()),
              );
            },
          ),
          _mapScreen,
        ];
      });
    }
  }

  void _openGroupChat() {
    if (selectedGroupId.value == null) return;
    setState(() {
      _isSidebarOpen = !_isSidebarOpen;
    });
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          GroupId: selectedGroupId.value!,
          type: "group",
          receiverUserEmail: "Group Tổng",
          receiverUserID: "",
        ),
      ),
    );
  }

  void _openPrivateChat(String userId, String userEmail) {
    if (selectedGroupId.value == null) return;
    setState(() {
      _isSidebarOpen = !_isSidebarOpen; // Fixed typo: threeisSidebarOpen -> _isSidebarOpen
    });
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          GroupId: selectedGroupId.value!,
          type: "private",
          receiverUserEmail: userEmail,
          receiverUserID: userId,
        ),
      ),
    );
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
                  await _fetchUserGroups();
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
                  await _fetchUserGroups();
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

  void signOut() {
    final authService = Provider.of<Authservice>(context, listen: false);
    authService.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            physics: const BouncingScrollPhysics(),
            children: _pages,
            onPageChanged: (index) {
              setState(() {
                _currentIndex.value = index;
                if (_currentIndex.value != 0) {
                  _showNavBar.value = false;
                }
                else{
                  _showNavBar.value = true;
                }
              });
            },
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            bottom: _showNavBar.value ? 0 : -70,
            left: 0,
            right: 0,
            child: Container(
              height: 70,
              decoration: BoxDecoration(
                color: Colors.black,
                border: const Border(
                  top: BorderSide(
                    color: Color.fromARGB(255, 39, 41, 42),
                    width: 1.0,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavItem(icon: Icons.home, index: 0),
                  _buildNavItem(icon: Icons.play_circle, index: 1),
                  _buildNavItem(icon: Icons.menu, index: 2),
                  _buildNavItem(icon: Icons.map, index: 3),
                ],
              ),
            ),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 400),
            left: _isSidebarOpen ? 0 : -MediaQuery.of(context).size.width * 0.8,
            top: 0,
            bottom: 0,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.8,
              color: Colors.black87,
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Bảng điều khiển",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 226, 229, 233),
                        ),
                      ),
                      IconButton(
                        onPressed: _toggleSidebar,
                        icon: const Icon(Icons.close),
                        color: const Color.fromARGB(255, 226, 229, 233),
                      ),
                    ],
                  ),
                  const Divider(),
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          flex: 2,
                          child: GroupbarWidget(
                            isOpen: _isSidebarOpen,
                            userGroups: userGroups.value,
                            selectedGroupId: selectedGroupId.value,
                            onGroupSelected: _selectGroup,
                          ),
                        ),
                        const VerticalDivider(),
                        Flexible(
                          flex: 7,
                          child: MemberSidebarWidget(
                            isOpen: _isSidebarOpen,
                            groupMembers: groupMembers.value,
                            selectedGroupId: selectedGroupId.value,
                            onPrivateChat: _openPrivateChat,
                            onGroupChat: _openGroupChat,
                            onClose: _toggleSidebar,
                            userGroups: userGroups,
                            selectedGroupIdNotifier: selectedGroupId,
                            onGroupChanged: _fetchUserGroups,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            top: _showNavBar.value ? 0 : -70,
            left: 0,
            right: 0,
            child: TopAppBarWidget(
              onCreateGroup: _createGroup,
              onJoinGroup: _joinGroup,
              signOut: signOut,
              userGroupsIsNotEmpty: userGroups.value.isNotEmpty,
            ),
          ),
          if (_currentIndex.value != 2)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 400),
              left: _isSidebarOpen ? MediaQuery.of(context).size.width * 0.8 : 0,
              top: MediaQuery.of(context).size.height * 0.4,
              child: GestureDetector(
                onTap: _toggleSidebar,
                child: Container(
                  width: 20,
                  height: 70,
                  decoration: const BoxDecoration(
                    color: Color.fromARGB(255, 218, 231, 243),
                    borderRadius: BorderRadius.horizontal(right: Radius.circular(50)),
                  ),
                ),
              ),
            ),
          ValueListenableBuilder<int>(
            valueListenable: _currentIndex,
            builder: (context, pageIndex, child) {
              if (pageIndex != 3) return const SizedBox.shrink();
              return Positioned(
                top: 16,
                left: 16,
                child: FloatingActionButton.small(
                  backgroundColor: Colors.white,
                  onPressed: () {
                    _pageController.jumpToPage(1);
                  },
                  child: const Icon(Icons.arrow_back, color: Colors.black),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({required IconData icon, required int index}) {
    final bool isSelected = _currentIndex.value == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _onNavTap(index);
            if (_currentIndex.value != 0 && _currentIndex.value != 3) {
              _showNavBar.value = false;
            } else {
              _showNavBar.value = true;
            }
          });
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: const Color.fromARGB(255, 226, 229, 233),
            ),
            if (isSelected)
              Container(
                height: 2,
                width: 20,
                margin: const EdgeInsets.only(top: 4),
                color: const Color.fromARGB(255, 226, 229, 233),
              ),
          ],
        ),
      ),
    );
  }
}
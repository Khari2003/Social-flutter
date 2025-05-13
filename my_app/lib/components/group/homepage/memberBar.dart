import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_app/services/group/groupService.dart';

class MemberSidebarWidget extends StatelessWidget {
  final bool isOpen;
  final List<Map<String, dynamic>> groupMembers;
  final String? selectedGroupId;
  final Function(String, String) onPrivateChat;
  final VoidCallback onClose;
  final VoidCallback onGroupChat;
  final ValueNotifier<List<Map<String, dynamic>>> userGroups; // Add userGroups
  final ValueNotifier<String?> selectedGroupIdNotifier; // Add selectedGroupId
  final VoidCallback onGroupChanged; // Add callback to refresh groups

  const MemberSidebarWidget({
    Key? key,
    required this.isOpen,
    required this.groupMembers,
    required this.selectedGroupId,
    required this.onPrivateChat,
    required this.onClose,
    required this.onGroupChat,
    required this.userGroups,
    required this.selectedGroupIdNotifier,
    required this.onGroupChanged,
  }) : super(key: key);

  // Show dialog with copyable join link
  void _showJoinLinkDialog(BuildContext context, String joinLink) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Mã mời nhóm', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Chia sẻ mã này để mời thành viên mới:',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            SelectableText(
              joinLink,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: joinLink));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã sao chép mã mời!')),
              );
            },
            child: const Text('Sao chép', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  // Show dialog to select new admin (for admin leaving)
  void _showSelectNewAdminDialog(BuildContext context, String groupId, String currentUserId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Chọn quản trị viên mới', style: TextStyle(color: Colors.white)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: groupMembers.length,
            itemBuilder: (context, index) {
              final member = groupMembers[index];
              if (member['id'] == currentUserId) return const SizedBox.shrink();
              final displayName = member["email"]!.contains('@')
                  ? member["email"]!.split('@')[0]
                  : member["email"]!;
              return ListTile(
                title: Text(displayName, style: const TextStyle(color: Colors.white)),
                onTap: () async {
                  try {
                    final groupService = GroupService();
                    await groupService.changeAdminAndLeave(groupId, member['id']);
                    Navigator.pop(context);
                    await _updateGroupList(context, currentUserId);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã chuyển quyền quản trị và rời nhóm!')),
                    );
                    onClose();
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Lỗi: $e')),
                    );
                  }
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  // Update group list after leaving
  Future<void> _updateGroupList(BuildContext context, String userId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('groups')
          .where('members', arrayContains: userId)
          .get();
      final newGroups = snapshot.docs
          .map((doc) => {"id": doc.id, "name": doc['groupName']})
          .toList();
      userGroups.value = newGroups;
      if (newGroups.isEmpty) {
        selectedGroupIdNotifier.value = null;
      } else if (!newGroups.any((group) => group['id'] == selectedGroupIdNotifier.value)) {
        selectedGroupIdNotifier.value = newGroups.first['id'];
      }
      onGroupChanged();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi cập nhật danh sách nhóm: $e')),
      );
    }
  }

  // Handle leave group action
  void _leaveGroup(BuildContext context, String groupId, String currentUserId) async {
    final groupService = GroupService();
    try {
      // Check if user is admin
      final groupSnapshot = await FirebaseFirestore.instance.collection('groups').doc(groupId).get();
      final isAdmin = groupSnapshot['adminId'] == currentUserId;

      if (isAdmin) {
        // If admin, check if there are other members
        if (groupMembers.length > 1) {
          _showSelectNewAdminDialog(context, groupId, currentUserId);
        } else {
          // If admin is the only member, delete the group
          await groupService.deleteGroup(groupId);
          await _updateGroupList(context, currentUserId);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Nhóm đã bị xóa vì bạn là thành viên duy nhất!')),
          );
          onClose();
        }
      } else {
        // Non-admin: leave group and delete posts
        await groupService.leaveGroup(groupId, currentUserId);
        await _updateGroupList(context, currentUserId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã rời nhóm!')),
        );
        onClose();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;
    return Container(
      width: MediaQuery.of(context).size.width * 0.65,
      color: Colors.black87,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 16, bottom: 12),
            child: Text(
              'Thành viên',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          InkWell(
            onTap: onGroupChat,
            splashColor: Colors.blueAccent.withOpacity(0.3),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.black87,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.blueAccent,
                    child: const Icon(Icons.group, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Group Tổng',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(color: Colors.grey, height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: groupMembers.length,
              itemBuilder: (context, index) {
                final member = groupMembers[index];
                final name = member['fullName'];
                final displayName = member["email"]!.contains('@')
                    ? member["email"]!.split('@')[0]
                    : member["email"]!;
                return InkWell(
                  onTap: () => onPrivateChat(member["id"]!, member["email"]!),
                  splashColor: Colors.blueAccent.withOpacity(0.3),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundImage: member["avatar"]!.isNotEmpty
                              ? NetworkImage(member["avatar"]!)
                              : null,
                          child: member["avatar"]!.isEmpty
                              ? const Icon(Icons.person, color: Colors.white, size: 28)
                              : null,
                          backgroundColor: Colors.grey[600],
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name ?? displayName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'Online',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(color: Colors.grey, height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                InkWell(
                  onTap: selectedGroupId != null
                      ? () async {
                          try {
                            final groupSnapshot = await FirebaseFirestore.instance
                                .collection('groups')
                                .doc(selectedGroupId)
                                .get();
                            final joinLink = groupSnapshot['joinLink'];
                            _showJoinLinkDialog(context, joinLink);
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Lỗi: $e')),
                            );
                          }
                        }
                      : null,
                  splashColor: Colors.blueAccent.withOpacity(0.3),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        Icon(Icons.person_add, color: Colors.grey[500], size: 24),
                        const SizedBox(width: 12),
                        Text(
                          'Thêm thành viên',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                InkWell(
                  onTap: selectedGroupId != null
                      ? () => _leaveGroup(context, selectedGroupId!, currentUserId)
                      : null,
                  splashColor: Colors.redAccent.withOpacity(0.3),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        Icon(Icons.exit_to_app, color: Colors.grey[500], size: 24),
                        const SizedBox(width: 12),
                        Text(
                          'Rời nhóm',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
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
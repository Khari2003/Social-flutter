import 'package:flutter/material.dart';

class MemberSidebarWidget extends StatelessWidget {
  final bool isOpen;
  final List<Map<String, dynamic>> groupMembers;
  final String? selectedGroupId;
  final Function(String, String) onPrivateChat;
  final VoidCallback onClose;
  final VoidCallback onGroupChat;

  const MemberSidebarWidget({
    Key? key,
    required this.isOpen,
    required this.groupMembers,
    required this.selectedGroupId,
    required this.onPrivateChat,
    required this.onClose,
    required this.onGroupChat,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.65,
      color:  Colors.black87,
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
          // Group Tổng
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
          // Danh sách thành viên
          Expanded(
            child: ListView.builder(
              itemCount: groupMembers.length,
              itemBuilder: (context, index) {
                final member = groupMembers[index];
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
                                displayName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'Online', // Giả lập trạng thái
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
          // Nút hành động
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                InkWell(
                  onTap: null, // Có thể thêm logic sau
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
                  onTap: null, // Có thể thêm logic sau
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
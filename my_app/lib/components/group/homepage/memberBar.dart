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
      width: MediaQuery.of(context).size.width * 0.7,
      color: const Color.fromARGB(47, 0, 0, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),

          // Group Tổng (Chat chung)
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.blue,
              child: Icon(Icons.group, color: Colors.white),
            ),
            title: const Text(
              "Group Tổng",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 226, 229, 233),
              ),
            ),
            onTap: onGroupChat,
          ),

          const Divider(),

          // Danh sách thành viên
          Expanded(
            child: ListView.builder(
              itemCount: groupMembers.length,
              itemBuilder: (context, index) {
                final member = groupMembers[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: member["avatar"]!.isNotEmpty
                        ? NetworkImage(member["avatar"]!)
                        : null,
                    child: member["avatar"]!.isEmpty
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  title: Text(
                    member["email"]!.contains('@')
                        ? member["email"]!.split('@')[0] // Lấy phần trước @
                        : member["email"]!,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 226, 229, 233),
                    ),
                  ),
                  onTap: () => onPrivateChat(member["id"]!, member["email"]!),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

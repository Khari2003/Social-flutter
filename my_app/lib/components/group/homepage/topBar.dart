import 'package:flutter/material.dart';

class TopAppBarWidget extends StatelessWidget {
  final VoidCallback onCreateGroup;
  final VoidCallback onJoinGroup;
  final VoidCallback signOut;
  final bool userGroupsIsNotEmpty;

  const TopAppBarWidget({
    Key? key,
    required this.onCreateGroup,
    required this.onJoinGroup,
    required this.signOut,
    required this.userGroupsIsNotEmpty,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        height: 90,
        decoration: BoxDecoration(
          color: Colors.black87,
          border: Border(
            bottom: BorderSide(
              color: const Color.fromARGB(255, 39, 41, 42),
              width: 1.0,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 40, 8, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Trang Chủ",
                style: TextStyle(
                    color: Color.fromARGB(255, 226, 229, 233), fontSize: 20),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: onCreateGroup,
                    icon: const Icon(Icons.add_circle_outline),
                    color: Color.fromARGB(255, 226, 229, 233),
                    tooltip: "Tạo nhóm",
                  ),
                  IconButton(
                    onPressed: onJoinGroup,
                    icon: const Icon(Icons.group_add),
                    color: Color.fromARGB(255, 226, 229, 233),
                    tooltip: "Tham gia nhóm",
                  ),
                  IconButton(
                    onPressed: signOut,
                    icon: const Icon(Icons.logout),
                    color: Color.fromARGB(255, 226, 229, 233),
                    tooltip: "Thoát",
                  ),
                ],
              ),
            ],
          ),
        ));
  }
}

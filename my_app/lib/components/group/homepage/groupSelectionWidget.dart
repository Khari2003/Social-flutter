import 'package:flutter/material.dart';

class GroupSelectionWidget extends StatelessWidget {
  final VoidCallback onCreateGroup;
  final VoidCallback onJoinGroup;

  const GroupSelectionWidget({
    Key? key,
    required this.onCreateGroup,
    required this.onJoinGroup,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            "Bạn chưa tham gia nhóm nào!",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: onCreateGroup,
            child: const Text("Tạo Nhóm"),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: onJoinGroup,
            child: const Text("Tham Gia Nhóm"),
          ),
        ],
      ),
    );
  }
}

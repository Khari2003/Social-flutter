import 'package:flutter/material.dart';
import 'package:my_app/components/group/menu/editProfileScreen.dart';
import 'package:provider/provider.dart';
import 'package:my_app/services/auth/authService.dart';

class MenuScreen extends StatelessWidget {
  final VoidCallback onSavedPostsSelected;

  const MenuScreen({Key? key, required this.onSavedPostsSelected})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),
            const Text(
              'Menu',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 226, 229, 233),
              ),
            ),
            const Divider(color: Colors.grey),
            ListTile(
              leading: const Icon(Icons.bookmark, color: Colors.white),
              title: const Text(
                'Bài đăng đã lưu',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              onTap: onSavedPostsSelected,
            ),
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.white),
              title: const Text(
                'Chỉnh sửa hồ sơ',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const EditProfileScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings, color: Colors.white),
              title: const Text(
                'Cài đặt',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              onTap: () {
                // Thêm logic cho cài đặt nếu cần
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.white),
              title: const Text(
                'Đăng xuất',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              onTap: () {
                Provider.of<Authservice>(context, listen: false).signOut();
              },
            ),
          ],
        ),
      ),
    );
  }
}

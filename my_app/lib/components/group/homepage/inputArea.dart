import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_app/services/auth/authService.dart';

class InputAreaWidget extends StatefulWidget {
  final VoidCallback? onTap;

  const InputAreaWidget({Key? key, this.onTap}) : super(key: key);

  @override
  _InputAreaWidgetState createState() => _InputAreaWidgetState();
}

class _InputAreaWidgetState extends State<InputAreaWidget> {
  final Authservice _auth = Authservice();
  String? avatarUrl;
  bool isLoadingAvatar = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception("No user logged in");
      }
      final user = await _auth.getUserById(currentUser.uid);
      setState(() {
        avatarUrl = user?.avatarUrl;
        isLoadingAvatar = false;
      });
    } catch (e) {
      print("Error fetching user data: $e");
      setState(() {
        avatarUrl = null;
        isLoadingAvatar = false;
      });
    }
  }

  Widget _buildAvatar() {
    if (isLoadingAvatar) {
      return CircleAvatar(
        radius: 21,
        backgroundColor: Colors.grey[800],
        child: const CircularProgressIndicator(
          color: Colors.blueAccent,
          strokeWidth: 2,
        ),
      );
    }
    return CircleAvatar(
      radius: 21,
      backgroundColor: Colors.grey[800],
      child: avatarUrl != null
          ? ClipOval(
              child: CachedNetworkImage(
                imageUrl: avatarUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) => const CircularProgressIndicator(
                  color: Colors.blueAccent,
                  strokeWidth: 2,
                ),
                errorWidget: (context, url, error) => const Icon(
                  Icons.person_outline,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            )
          : const Icon(
              Icons.person_outline,
              color: Colors.white,
              size: 24,
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
      clipBehavior: Clip.none,
      color: const Color.fromARGB(255, 19, 20, 20),
      child: InkWell(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 19, 20, 20),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              _buildAvatar(), // Sử dụng hàm _buildAvatar giống GroupPostCard
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 40, 42, 44),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: const Color.fromARGB(255, 80, 79, 79),
                        width: 2),
                  ),
                  child: Center(
                    child: Text(
                      "Bạn đang nghĩ gì...",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
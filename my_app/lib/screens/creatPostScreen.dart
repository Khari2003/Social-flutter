import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:my_app/services/auth/authService.dart';

class CreatePostScreen extends StatefulWidget {
  final Future<void> Function(
      String content, List<File> images, List<File> videos) onCreatePost;

  const CreatePostScreen({Key? key, required this.onCreatePost})
      : super(key: key);

  @override
  _CreatePostScreenState createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _postContentController = TextEditingController();
  final List<File> _selectedImages = [];
  final List<File> _selectedVideos = [];
  final Authservice auth = Authservice();
  bool _isPosting = false;
  String? email;

  @override
  void initState() {
    super.initState();
    _fetchEmail();
    _postContentController.addListener(() {
      setState(() {});
    });
  }

  Future<void> _fetchEmail() async {
    String? fetchedEmail =
        await auth.getEmailById(FirebaseAuth.instance.currentUser!.uid);
    setState(() {
      email = fetchedEmail;
      email = email!.contains('@') ? email!.split('@')[0] : email;
    });
  }

  Future<void> _pickMedia(ImageSource source, String type) async {
    final picker = ImagePicker();
    XFile? pickedFile;
    if (type == 'image') {
      pickedFile = await picker.pickImage(source: source);
      if (pickedFile != null)
        setState(() => _selectedImages.add(File(pickedFile!.path)));
    } else if (type == 'video') {
      pickedFile = await picker.pickVideo(source: source);
      if (pickedFile != null)
        setState(() => _selectedVideos.add(File(pickedFile!.path)));
    }
  }

  void _submitPost() async {
    String content = _postContentController.text.trim();
    if (content.isNotEmpty && !_isPosting) {
      setState(() => _isPosting = true);
      try {
        await widget.onCreatePost(content, _selectedImages, _selectedVideos);
        Navigator.pop(context, true); 
      } catch (e) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Lỗi: $e")));
      } finally {
        setState(() => _isPosting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool canPost = _postContentController.text.trim().isNotEmpty ||
        _selectedImages.isNotEmpty ||
        _selectedVideos.isNotEmpty;

    return Scaffold(
      backgroundColor: Color.fromARGB(255, 37, 39, 40),
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 37, 39, 40),
        title: Text(
          "Tạo bài viết",
          style: TextStyle(
            color: Color.fromARGB(255, 226, 229, 233),
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Color.fromARGB(255, 226, 229, 233),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: canPost ? _submitPost : null,
            style: TextButton.styleFrom(
              side: BorderSide(
                color:
                    canPost ? Colors.blue : Color.fromARGB(255, 226, 229, 233),
                width: 1.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              backgroundColor: Colors.white,
            ),
            child: Text(
              "ĐĂNG",
              style: TextStyle(
                color:
                    canPost ? Colors.blue : Color.fromARGB(255, 226, 229, 233),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.grey,
                  child: Icon(Icons.person, color: Colors.white),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(email ?? "User",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 226, 229, 233),
                            fontSize: 18)),
                    Row(
                      children: [
                        _privacyButton("Chỉ mình tôi"),
                        const SizedBox(width: 5),
                        _privacyButton("+ Album"),
                        const SizedBox(width: 5),
                        _privacyButton("Đang tắt"),
                        const SizedBox(width: 5),
                        _privacyButton("+ Nhãn AI"),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _postContentController,
              style: TextStyle(
                color: Color.fromARGB(255, 226, 229, 233),
              ),
              maxLines: null,
              decoration: const InputDecoration(
                hintText: "Bạn đang nghĩ gì?",
                hintStyle: TextStyle(
                  color: Colors.grey,
                ),
                border: InputBorder.none,
              ),
            ),
            if (_selectedImages.isNotEmpty || _selectedVideos.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ..._selectedImages
                      .map((image) => _mediaPreview(image, 'image')),
                  ..._selectedVideos
                      .map((video) => _mediaPreview(video, 'video')),
                ],
              ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _actionButton(
                    Icons.image,
                    "Ảnh",
                    () => _pickMedia(ImageSource.gallery, 'image'),
                    Colors.greenAccent),
                _actionButton(
                    Icons.video_collection,
                    "Video",
                    () => _pickMedia(ImageSource.gallery, 'video'),
                    Colors.blueAccent),
                _actionButton(Icons.emoji_emotions, "Cảm xúc", () {},
                    Colors.yellowAccent),
                _actionButton(
                    Icons.location_on, "Vị trí", () {}, Colors.redAccent),
                _actionButton(Icons.more_horiz, "Khác", () {}, Colors.white),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _privacyButton(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.shade800,
        borderRadius: BorderRadius.circular(8),
      ),
      child:
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 12)),
    );
  }

  Widget _mediaPreview(File file, String type) {
    return Stack(
      children: [
        type == 'image'
            ? Image.file(file, width: 80, height: 80, fit: BoxFit.cover)
            : Container(
                width: 80,
                height: 80,
                color: Colors.blue,
                child: const Icon(Icons.video_file,
                    color: Colors.white, size: 40)),
        Positioned(
          top: 0,
          right: 0,
          child: IconButton(
            icon: const Icon(Icons.cancel, color: Colors.red, size: 20),
            onPressed: () {
              setState(() {
                if (type == 'image')
                  _selectedImages.remove(file);
                else
                  _selectedVideos.remove(file);
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _actionButton(
      IconData icon, String label, VoidCallback onPressed, Color color) {
    return Column(
      children: [
        IconButton(icon: Icon(icon, color: color), onPressed: onPressed),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

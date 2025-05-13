import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:convert';
import 'package:my_app/services/auth/authService.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_app/model/user/user.dart' as model;

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _bioController = TextEditingController();
  String? _avatarUrl;
  String? _coverPhotoUrl;
  File? _selectedAvatarImage;
  File? _selectedCoverImage;
  bool _isEditing = false;
  bool _isLoading = false;
  model.User? _user;

  final String apiEndpoint = "http://192.168.30.53:5000/upload";

  @override
  void initState() {
    super.initState();
    _loadUserDataAndInitialize();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneNumberController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _loadUserDataAndInitialize() async {
    try {
      final authService = Provider.of<Authservice>(context, listen: false);
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        throw Exception("Người dùng chưa đăng nhập");
      }
      final user = await authService.getUserById(userId);
      setState(() {
        _user = user;
        _fullNameController.text = user?.fullName ?? '';
        _phoneNumberController.text = user?.phoneNumber ?? '';
        _bioController.text = user?.bio ?? '';
        _avatarUrl = user?.avatarUrl;
        _coverPhotoUrl = user?.coverPhotoUrl;
      });
    } catch (e) {
      print("Error loading user data: $e");
    }
  }

  Future<void> _pickAvatarImage() async {
    if (!_isEditing) return;
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedAvatarImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _pickCoverImage() async {
    if (!_isEditing) return;
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedCoverImage = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImage(File image) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse(apiEndpoint));
      request.fields['type'] = 'image';
      request.files.add(await http.MultipartFile.fromPath('file', image.path));

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();
      var jsonData = json.decode(responseBody);

      if (response.statusCode == 200 && jsonData['url'] != null) {
        return jsonData['url'];
      } else {
        throw Exception("Upload failed: ${jsonData['error']}");
      }
    } catch (e) {
      throw Exception("Failed to upload image: $e");
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<Authservice>(context, listen: false);
      final userId = FirebaseAuth.instance.currentUser!.uid;

      String? avatarUrl = _avatarUrl;
      String? coverPhotoUrl = _coverPhotoUrl;

      if (_selectedAvatarImage != null) {
        avatarUrl = await _uploadImage(_selectedAvatarImage!);
      }
      if (_selectedCoverImage != null) {
        coverPhotoUrl = await _uploadImage(_selectedCoverImage!);
      }

      await authService.updateUser(
        userId: userId,
        fullName: _fullNameController.text.trim().isEmpty
            ? null
            : _fullNameController.text.trim(),
        avatarUrl: avatarUrl,
        coverPhotoUrl: coverPhotoUrl,
        phoneNumber: _phoneNumberController.text.trim().isEmpty
            ? null
            : _phoneNumberController.text.trim(),
        bio: _bioController.text.trim().isEmpty
            ? null
            : _bioController.text.trim(),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cập nhật hồ sơ thành công")),
      );
      setState(() {
        _isEditing = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi: $e")),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Chỉnh sửa hồ sơ"),
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
        elevation: 4,
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            ),
        ],
      ),
      backgroundColor: Colors.black87,
      body: _user == null
          ? const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Cover photo
                    GestureDetector(
                      onTap: _pickCoverImage,
                      child: Container(
                        height: 150,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white12, width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          image: _selectedCoverImage != null
                              ? DecorationImage(
                                  image: FileImage(_selectedCoverImage!),
                                  fit: BoxFit.cover,
                                )
                              : (_coverPhotoUrl != null
                                  ? DecorationImage(
                                      image: NetworkImage(_coverPhotoUrl!),
                                      fit: BoxFit.cover,
                                    )
                                  : null),
                        ),
                        child: _selectedCoverImage == null && _coverPhotoUrl == null
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_a_photo,
                                      size: 40,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      "Thêm ảnh bìa",
                                      style: TextStyle(
                                        color: Colors.grey[400],
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : (_isEditing
                                ? Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        Icons.edit,
                                        color: Colors.white,
                                        size: 30,
                                      ),
                                    ),
                                  )
                                : null),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Avatar
                    GestureDetector(
                      onTap: _pickAvatarImage,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Colors.blueAccent, Colors.tealAccent],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.4),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(3),
                            child: CircleAvatar(
                              radius: 60,
                              backgroundImage: _selectedAvatarImage != null
                                  ? FileImage(_selectedAvatarImage!)
                                  : (_avatarUrl != null
                                      ? NetworkImage(_avatarUrl!)
                                      : null) as ImageProvider?,
                              backgroundColor: Colors.grey[800],
                              child: _selectedAvatarImage == null && _avatarUrl == null
                                  ? const Icon(
                                      Icons.person,
                                      size: 60,
                                      color: Colors.white70,
                                    )
                                  : null,
                            ),
                          ),
                          if (_isEditing)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.blueAccent,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _fullNameController,
                      readOnly: !_isEditing,
                      decoration: InputDecoration(
                        labelText: "Họ và tên",
                        labelStyle: TextStyle(color: Colors.grey[400]),
                        filled: true,
                        fillColor: Colors.grey[900],
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.white12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.blueAccent),
                        ),
                        disabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.white12),
                        ),
                      ),
                      style: const TextStyle(color: Colors.white),
                      validator: (value) {
                        if (_isEditing && (value == null || value.trim().isEmpty)) {
                          return "Vui lòng nhập họ và tên";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneNumberController,
                      readOnly: !_isEditing,
                      decoration: InputDecoration(
                        labelText: "Số điện thoại",
                        labelStyle: TextStyle(color: Colors.grey[400]),
                        filled: true,
                        fillColor: Colors.grey[900],
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.white12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.blueAccent),
                        ),
                        disabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.white12),
                        ),
                      ),
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value != null && value.isNotEmpty && _isEditing) {
                          if (!RegExp(r'^\+?[0-9]\d{1,14}$').hasMatch(value)) {
                            return "Vui lòng nhập số điện thoại hợp lệ";
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _bioController,
                      readOnly: !_isEditing,
                      decoration: InputDecoration(
                        labelText: "Tiểu sử",
                        labelStyle: TextStyle(color: Colors.grey[400]),
                        filled: true,
                        fillColor: Colors.grey[900],
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.white12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.blueAccent),
                        ),
                        disabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.white12),
                        ),
                      ),
                      style: const TextStyle(color: Colors.white),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),
                    if (_isEditing)
                      _isLoading
                          ? const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
                          : ElevatedButton(
                              onPressed: _saveProfile,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueAccent,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 4,
                              ),
                              child: const Text(
                                "Lưu",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
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
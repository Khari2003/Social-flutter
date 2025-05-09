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
  File? _selectedImage;
  bool _isEditing = false;
  bool _isLoading = false;

  final String apiEndpoint = "http://192.168.215.200:5000/upload";

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneNumberController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<model.User?> _loadUserData() async {
    try {
      final authService = Provider.of<Authservice>(context, listen: false);
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        throw Exception("Người dùng chưa đăng nhập");
      }
      return await authService.getUserById(userId);
    } catch (e) {
      throw Exception("Lỗi khi tải dữ liệu: $e");
    }
  }

  Future<void> _pickImage() async {
    if (!_isEditing) return;
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
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
      if (_selectedImage != null) {
        avatarUrl = await _uploadImage(_selectedImage!);
      }

      await authService.updateUser(
        userId: userId,
        fullName: _fullNameController.text.trim().isEmpty
            ? null
            : _fullNameController.text.trim(),
        avatarUrl: avatarUrl,
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
        title: const Text("Hồ sơ"),
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
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
      body: FutureBuilder<model.User?>(
        future: _loadUserData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Lỗi: ${snapshot.error}",
                    style: const TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {}); // Tải lại dữ liệu
                    },
                    child: const Text("Thử lại"),
                  ),
                ],
              ),
            );
          } else if (!snapshot.hasData || snapshot.data == null) {
            return const Center(
              child: Text(
                "Không tìm thấy thông tin người dùng",
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          // Dữ liệu người dùng đã tải thành công
          final user = snapshot.data!;
          _fullNameController.text = user.fullName ?? '';
          _phoneNumberController.text = user.phoneNumber ?? '';
          _bioController.text = user.bio ?? '';
          _avatarUrl = user.avatarUrl;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 50,
                      backgroundImage: _selectedImage != null
                          ? FileImage(_selectedImage!)
                          : (_avatarUrl != null
                              ? NetworkImage(_avatarUrl!)
                              : null) as ImageProvider?,
                      child: _selectedImage == null && _avatarUrl == null
                          ? const Icon(Icons.person,
                              size: 50, color: Colors.white)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _fullNameController,
                    readOnly: !_isEditing,
                    decoration: InputDecoration(
                      labelText: "Họ và tên",
                      labelStyle: const TextStyle(color: Colors.white),
                      enabledBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                      disabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: _isEditing ? Colors.grey : Colors.grey),
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneNumberController,
                    readOnly: !_isEditing,
                    decoration: InputDecoration(
                      labelText: "Số điện thoại",
                      labelStyle: const TextStyle(color: Colors.white),
                      enabledBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                      disabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: _isEditing ? Colors.grey : Colors.grey),
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
                      labelStyle: const TextStyle(color: Colors.white),
                      enabledBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                      disabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: _isEditing ? Colors.grey : Colors.grey),
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),
                  if (_isEditing)
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                            onPressed: _saveProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                            ),
                            child: const Text("Lưu"),
                          ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
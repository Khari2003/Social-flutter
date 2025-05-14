import 'package:flutter/material.dart';
import 'package:my_app/services/auth/authService.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../components/textField.dart';
import '../../components/button.dart';
import '../../map/services/locationService.dart';
import 'package:latlong2/latlong.dart';

class RegisterScreen extends StatefulWidget {
  final void Function()? onTap;
  const RegisterScreen({super.key, required this.onTap});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  bool isAllowedLocation = false;
  GeoPoint? userLocation;

  Future<void> _fetchUserLocation() async {
    try {
      LatLng? location = await LocationService.fetchCurrentLocation();
      if (location != null) {
        setState(() {
          userLocation = GeoPoint(location.latitude, location.longitude);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            content: const Text(
              'Không thể lấy vị trí, sử dụng vị trí mặc định',
              style: TextStyle(color: Colors.white),
            ),
          ),
        );
        setState(() {
          userLocation = GeoPoint(21.0278, 105.8342); // Fallback
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text(
            'Không thể lấy vị trí: $e',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
      setState(() {
        userLocation = GeoPoint(21.0278, 105.8342); // Fallback
      });
    }
  }

  void signUp() async {
    if (passwordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.redAccent,
          content: const Text(
            'Mật khẩu không khớp!',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
      return;
    }
    final authService = Provider.of<Authservice>(context, listen: false);
    try {
      await authService.signUpWithEmailAndPassword(
        emailController.text,
        passwordController.text,
        isAllowedLocation,
        userLocation,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text(
            e.toString(),
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 48),
                const Text(
                  'Tạo Tài Khoản',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Đăng ký để bắt đầu',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[400],
                  ),
                ),
                const SizedBox(height: 48),
                MyTextField(
                  controller: emailController,
                  hintText: 'Email',
                  obscureText: false,
                ),
                const SizedBox(height: 16),
                MyTextField(
                  controller: passwordController,
                  hintText: 'Mật khẩu',
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                MyTextField(
                  controller: confirmPasswordController,
                  hintText: 'Xác nhận mật khẩu',
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Checkbox(
                      value: isAllowedLocation,
                      activeColor: Colors.blueAccent,
                      checkColor: Colors.white,
                      side: BorderSide(color: Colors.grey[600]!),
                      onChanged: (bool? value) async {
                        setState(() {
                          isAllowedLocation = value ?? false;
                        });
                        if (isAllowedLocation) {
                          await _fetchUserLocation();
                        } else {
                          setState(() {
                            userLocation = null;
                          });
                        }
                      },
                    ),
                    Text(
                      'Cho phép lưu vị trí của tôi',
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                CustomButton(onTap: signUp, text: 'Đăng ký'),
                const SizedBox(height: 48),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Đã có tài khoản?',
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: widget.onTap,
                      child: const Text(
                        'Đăng nhập ngay!',
                        style: TextStyle(
                          color: Colors.blueAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
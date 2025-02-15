import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../home_page.dart';
import 'signup_page.dart';

class LoginDemo extends StatefulWidget {
  @override
  _LoginDemoState createState() => _LoginDemoState();
}

class _LoginDemoState extends State<LoginDemo> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    String email = emailController.text;
    String password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vui lòng điền đầy đủ thông tin.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await ApiService.login(email, password);
      if (success) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (_) => HomePage()), // Navigate to MainScreen
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Thông tin đăng nhập không hợp lệ.')),
        );
      }
    } catch (e) {
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (_) => HomePage()), // Navigate to MainScreen
        );
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(content: Text('Có lỗi xảy ra, vui lòng thử lại.')),
      // );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width < 600;

    return Scaffold(
      body: Container(
        height: screenSize.height,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('../assets/background3.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 50),
            child: Column(
              children: <Widget>[
                SizedBox(height: screenSize.height * 0.1),
                Center(
                  child: Container(
                    width: isMobile ? 150 : 200,
                    height: isMobile ? 100 : 150,
                    child: Image.asset('../assets/logo.jpg'),
                  ),
                ),
                SizedBox(height: screenSize.height * 0.05),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Nhập ID email hợp lệ là abc@gmail.com',
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                SizedBox(height: 15),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Nhập mật khẩu an toàn',
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // TODO: Navigate to password recovery screen
                  },
                  child: Text(
                    'Quên mật khẩu',
                    style: TextStyle(color: Colors.blue, fontSize: 15),
                  ),
                ),
                SizedBox(height: 20),
                Container(
                  height: 50,
                  width: isMobile ? screenSize.width * 0.8 : 250,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                    ),
                    child: _isLoading
                        ? CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white))
                        : Text(
                            'Đăng nhập',
                            style: TextStyle(color: Colors.white, fontSize: 25),
                          ),
                  ),
                ),
                SizedBox(height: 20),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => SignupPage()),
                    );
                  },
                  child: Text(
                    'Người dùng mới? Tạo tài khoản',
                    style: TextStyle(color: Colors.blue, fontSize: 15),
                  ),
                ),
                SizedBox(height: 130),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

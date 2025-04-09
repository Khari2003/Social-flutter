
import 'package:flutter/material.dart';
import 'package:my_app/services/auth/authService.dart';
import 'package:provider/provider.dart';
import '../../components/textField.dart';
import '../../components/button.dart';
class LoginScreen extends StatefulWidget {
    final void Function()? onTap;
    const LoginScreen({super.key, required this.onTap});
    @override
    State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    //sign in user
    void signIn () async {
      final authService = Provider.of<Authservice>(context, listen: false);
      try{
        await authService.signInWithEmailAndPassword(emailController.text, passwordController.text);
      } catch (e){
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString(),
            ),
          ),
        );
      }
    }
    @override
    Widget build(BuildContext context) {
        return Scaffold(
            backgroundColor: Colors.grey.shade200,
            body: SafeArea(
                child: Center(
                    child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 25.0),
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children:[
                                const SizedBox(height: 50),
                                //logo
                                // Icon(
                                //     Icons.message,
                                //     size: 80
                                // ),
                                //message
                                Text(
                                    'Đăng nhặp',
                                    style: TextStyle(
                                        fontSize: 16
                                    ),
                                ),
                                const SizedBox(height: 50),
                                //email
                                MyTextField(controller: emailController, hintText: 'Email', obscureText: false),
                                const SizedBox(height: 25),
                                //password
                                MyTextField(controller: passwordController, hintText: 'Password', obscureText: true),
                                const SizedBox(height: 50),
                                //signin button
                                CustomButton(onTap:signIn, text: 'Đăng nhập'),
                                const SizedBox(height: 50),
                                //register
                                Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                        const Text('Không có tài khoản?'),
                                        const SizedBox(width: 4),
                                        GestureDetector(
                                            onTap: widget.onTap,
                                            child : const Text(
                                                'Đăng ký ngay!',
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold
                                                )
                                            ),
                                        ),
                                    ]
                                ),
                            ],
                        ),
                    ),
                ),
            ),
        );
    }
}
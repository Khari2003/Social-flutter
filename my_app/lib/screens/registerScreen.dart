
import 'package:flutter/material.dart';
import 'package:my_app/services/auth/authService.dart';
import 'package:provider/provider.dart';
import '../components/textField.dart';
import '../components/button.dart';
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

    //sign up user
    void signUp () async{
      if (passwordController.text != confirmPasswordController.text){
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Mật khẩu không giống nhau!'),),);
        return;
      }
      final authService = Provider.of<Authservice>(context, listen: false);
      try{
        await authService.signUpWithEmailAndPassword(emailController.text, passwordController.text);
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
                                const SizedBox(height: 50),
                                //message
                                Text(
                                    'Tạo tài khoản',
                                    style: TextStyle(
                                        fontSize: 16
                                    ),
                                ),
                                const SizedBox(height: 50),
                                //email
                                MyTextField(controller: emailController, hintText: 'Email', obscureText: false),
                                const SizedBox(height: 10),
                                //password
                                MyTextField(controller: passwordController, hintText: 'Password', obscureText: true),
                                const SizedBox(height: 10),
                                //repassword
                                MyTextField(controller: confirmPasswordController, hintText: 'Comfirm Password', obscureText: true),
                                const SizedBox(height: 50),
                                //signin button
                                CustomButton(onTap:signUp, text: 'Đăng ký'),
                                const SizedBox(height: 50),
                                //register
                                Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                        const Text('Đã có tài khoản?'),
                                        const SizedBox(width: 4),
                                        GestureDetector(
                                            onTap: widget.onTap,
                                            child : const Text(
                                                'Đăng nhập ngay!',
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
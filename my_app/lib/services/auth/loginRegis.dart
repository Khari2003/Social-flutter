import 'package:flutter/material.dart';
import 'package:my_app/screens/loginScreen.dart';
import 'package:my_app/screens/registerScreen.dart';



class LoginOrRegister extends StatefulWidget {
  const LoginOrRegister({super.key});

  @override
  State<LoginOrRegister> createState() => _LoginOrRegisterState();
}

class _LoginOrRegisterState extends State<LoginOrRegister> {
  //initial show Login Screen
  bool showLoginPage = true;

  //toggle between login and register
  void toggleScreen(){
    setState( () {
        showLoginPage = !showLoginPage;
    });
  }
  @override
  Widget build(BuildContext context) {
    if (showLoginPage) {
        return LoginScreen(onTap: toggleScreen);
    } else {
        return RegisterScreen(onTap: toggleScreen);
    }
  }
}


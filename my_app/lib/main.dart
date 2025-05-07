import 'package:flutter/material.dart';
import 'package:my_app/firebase_options.dart';
import 'package:my_app/services/auth/authService.dart';
import 'package:my_app/services/auth/auth_gate.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(
    ChangeNotifierProvider(
      create: (context) => Authservice(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return  MaterialApp(
      title: 'Flutter Map Demo',
      home: AuthGate(), // Ensures AuthGate is used for authentication flow
    );
  }
}

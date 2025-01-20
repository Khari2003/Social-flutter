import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:my_app/screens/chatScreen.dart';
import 'package:provider/provider.dart';
import 'package:my_app/services/auth/authService.dart';
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  //instance
  final FirebaseAuth _auth = FirebaseAuth.instance;
  void signOut(){
    final authService = Provider.of<Authservice>(context, listen: false);

    authService.signOut();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat List'),
        actions:[
          IconButton(onPressed: signOut, 
          icon: const Icon(Icons.logout)
          ,)
        ]
      ),
      body: _buildUserList(),
    );
  }

  Widget _buildUserList(){
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text('Error');
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Text('loading...');
        }
        return ListView(
          children: snapshot.data!.docs.map<Widget>((doc) =>_buildUserListItem(doc)).toList(),
        );
      },
    );
  }
  Widget _buildUserListItem(DocumentSnapshot document){
    Map<String, dynamic> data = document.data()! as Map<String, dynamic>;
    if (_auth.currentUser!.email != data['email']){
      return ListTile(
            title: Text(data['email']),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder:(context) => ChatScreen(receiverUserEmail: data['email'], receiverUserID: data['uid']),),);
            }, 
          );
    } else {
      return Container();
    }
  }
}
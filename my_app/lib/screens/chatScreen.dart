import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:my_app/components/chatbubble.dart';
import 'package:my_app/components/textField.dart';
//import 'package:my_app/services/chat/chatService.dart';
import 'package:my_app/services/group/groupChatService.dart';

class ChatScreen extends StatefulWidget {
  final String GroupId;
  final String receiverUserEmail;
  final String receiverUserID;
  final String type;

  const ChatScreen({
    super.key,
    required this.GroupId,
    required this.type,
    required this.receiverUserEmail,
    required this.receiverUserID,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final GroupChatService _chatService = GroupChatService();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  void sendMessage() async {
    if (_messageController.text.isNotEmpty) {
      if (widget.type == "group") {
        await _chatService.sendGroupMessage(widget.GroupId, _messageController.text);
      } else if (widget.type == "private") {
        await _chatService.sendPrivateMessage(widget.GroupId, widget.receiverUserID, _messageController.text);
      }
      _messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.receiverUserEmail)),
      body: Column(
        children: [
          Expanded(
            child: _buildMessageList(),
          ),
          _buildMessageInput(),
          const SizedBox(height: 25),
        ],
      ),
    );
  }

  // message list
  Widget _buildMessageList() {
    Stream<QuerySnapshot> messageStream;

    if (widget.type == "group") {
      messageStream = _chatService.getGroupMessages(widget.GroupId);
    } else {
      messageStream = _chatService.getPrivateMessages(widget.GroupId, _firebaseAuth.currentUser!.uid, widget.receiverUserID);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: messageStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Text('Loading...');
        }
        return ListView(
          children: snapshot.data!.docs.map((doc) => _buildMessageItem(doc)).toList(),
        );
      },
    );
  }

  // message item
  Widget _buildMessageItem(DocumentSnapshot document) {
    Map<String, dynamic> data = document.data() as Map<String, dynamic>;
    var alignment = (data['senderId'] == _firebaseAuth.currentUser!.uid)
        ? Alignment.centerRight
        : Alignment.centerLeft;
    return Container(
      alignment: alignment,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: (data['senderId'] == _firebaseAuth.currentUser!.uid)
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          mainAxisAlignment: (data['senderId'] == _firebaseAuth.currentUser!.uid)
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          children: [
            Text(data['senderEmail']),
            ChatBubble(message: data['message']),
          ],
        ),
      ),
    );
  }

  // message input
  Widget _buildMessageInput() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25.0),
      child: Row(children: [
        Expanded(
          child: MyTextField(
            controller: _messageController,
            hintText: "Nhập tin nhắn...",
            obscureText: false,
          ),
        ),
        IconButton(
          onPressed: sendMessage,
          icon: const Icon(Icons.arrow_upward, size: 40),
        ),
      ]),
    );
  }
}
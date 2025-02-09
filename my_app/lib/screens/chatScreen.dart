import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:my_app/components/chatbubble.dart';
import 'package:my_app/components/textField.dart';
import 'package:my_app/services/group/groupChatService.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:permission_handler/permission_handler.dart';

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
  final ImagePicker _picker = ImagePicker();
  final AudioPlayer _audioPlayer = AudioPlayer();
  FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  List<File> _selectedImages = [];
  List<File> _voiceFiles = [];
  bool isRecording = false;
  String? _audioPath;


  void sendMessage() async {
    if (_messageController.text.isNotEmpty || _selectedImages.isNotEmpty || _voiceFiles.isNotEmpty) {
      if (widget.type == "group") {
        await _chatService.sendGroupMessage(widget.GroupId, _messageController.text, images: _selectedImages, voices: _voiceFiles);
      } else if (widget.type == "private") {
        await _chatService.sendPrivateMessage(widget.GroupId, widget.receiverUserID, _messageController.text, images: _selectedImages, voices: _voiceFiles);
      }
      _messageController.clear();
      setState(() {
        _selectedImages.clear();
        _voiceFiles.clear();
      });
    }
  }

  Future<void> pickImages() async {
    final List<XFile>? pickedFiles = await _picker.pickMultiImage();
    if (pickedFiles != null) {
      setState(() {
        _selectedImages = pickedFiles.map((file) => File(file.path)).toList();
      });
    }
  }

  void _toggleRecording() async {
    if (!isRecording) {
      var status = await Permission.microphone.request();
      if (status.isGranted) {
        await _recorder.openRecorder();
        setState(() => isRecording = true);
        final dir = await getApplicationDocumentsDirectory();
        _audioPath = '${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.aac';
        await _recorder.startRecorder(toFile: _audioPath);
      } else {
        print("❌ Quyền ghi âm bị từ chối!");
      }
    } else {
      await _recorder.stopRecorder();
      setState(() {
        isRecording = false;
        if (_audioPath != null) {
          _voiceFiles.add(File(_audioPath!));
          print(_voiceFiles);
        }
      });
    }
  }

  @override
  void dispose() {
    _recorder.closeRecorder();
    _audioPlayer.dispose();
    _messageController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.receiverUserEmail)),
      body: Column(
        children: [
          Expanded(child: _buildMessageList()),
          if (_selectedImages.isNotEmpty) _buildImagePreview(),
          if (_voiceFiles.isNotEmpty) _buildVoicePreview(),
          _buildMessageInput(),
          const SizedBox(height: 25),
        ],
      ),
    );
  }

  //Message List
  Widget _buildMessageList() {
    Stream<QuerySnapshot> messageStream = widget.type == "group"
        ? _chatService.getGroupMessages(widget.GroupId)
        : _chatService.getPrivateMessages(widget.GroupId, _firebaseAuth.currentUser!.uid, widget.receiverUserID);

    return StreamBuilder<QuerySnapshot>(
      stream: messageStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) return Text('Error: ${snapshot.error}');
        if (snapshot.connectionState == ConnectionState.waiting) return const Text('Loading...');
        return ListView(
          children: snapshot.data!.docs.map((doc) => _buildMessageItem(doc)).toList(),
        );
      },
    );
  }

  //Message Item
  Widget _buildMessageItem(DocumentSnapshot document) {
    Map<String, dynamic> data = document.data() as Map<String, dynamic>;
    var alignment = (data['senderId'] == _firebaseAuth.currentUser!.uid) ? Alignment.centerRight : Alignment.centerLeft;
    return Container(
      alignment: alignment,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: (data['senderId'] == _firebaseAuth.currentUser!.uid) ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(data['senderEmail']),
            if (data['voiceChatUrl'] != null) 
              IconButton(
                icon: Icon(Icons.play_arrow),
                onPressed: () async {
                  await _audioPlayer.play(UrlSource(data['voiceChatUrl']));
                },
              ),
            if (data['imageUrls'] != null) ...data['imageUrls'].map<Widget>((url) => 
              GestureDetector(
                  onTap: () {
                    _showFullScreenImage(context, url);
                  },
                  child: Image.network(
                    url,
                    width: MediaQuery.of(context).size.width * 0.8,
                    height: MediaQuery.of(context).size.height * 0.5,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(child: CircularProgressIndicator());
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.error, color: Colors.red);
                    },
                  ),
                )
              ),
            if (data['message'] != '') 
              ChatBubble(message: data['message']),
          ],
        ),
      ),
    );
  }

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: InteractiveViewer(
              panEnabled: true,
              boundaryMargin: const EdgeInsets.all(20),
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.network(imageUrl),
            ),
          ),
        );
      },
    );
  }

  Widget _buildImagePreview() {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _selectedImages.length,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.all(4.0),
          child: Stack(
            children: [
              Image.file(_selectedImages[index], width: 80, height: 80, fit: BoxFit.cover),
              Positioned(
                right: 0,
                top: 0,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedImages.removeAt(index);
                    });
                  },
                  child: Container(
                    color: Colors.red,
                    child: Icon(Icons.close, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVoicePreview() {
    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _voiceFiles.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.all(4.0),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.play_arrow, color: Colors.blue),
                  onPressed: () async {
                    await _audioPlayer.play(DeviceFileSource(_voiceFiles[index].path));
                  },
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    setState(() {
                      _voiceFiles.removeAt(index);
                    });
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }


  Widget _buildMessageInput() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15.0),
      child: Row(children: [
        IconButton(
          icon: Icon(Icons.image),
          onPressed: pickImages,
        ),
        IconButton(
          icon: Icon(isRecording ? Icons.mic : Icons.mic_none, color: isRecording ? Colors.red : Colors.grey),
          onPressed: _toggleRecording,
        ),
        Expanded(
          child: MyTextField(
            controller: _messageController,
            hintText: "Nhập tin nhắn...",
            obscureText: false,
          ),
        ),
        IconButton(
          onPressed: sendMessage,
          icon: const Icon(Icons.arrow_upward, size: 30),
        ),
      ]),
    );
  }
}

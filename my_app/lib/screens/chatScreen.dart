import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:my_app/components/chatbubble.dart';
import 'package:my_app/components/textField.dart';
import 'package:my_app/services/auth/authService.dart';
import 'package:my_app/services/group/groupChatService.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:my_app/services/group/groupPostingService.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:my_app/components/group/post/groupPostDetail.dart';
import 'package:my_app/model/group/posting.dart';
import 'package:my_app/components/group/post/ImageGalleryScreen.dart';

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
  final ScrollController _scrollController = ScrollController();
  List<File> _selectedImages = [];
  List<File> _voiceFiles = [];
  bool isRecording = false;
  String? _audioPath;

  void sendMessage() async {
    if (_messageController.text.isNotEmpty ||
        _selectedImages.isNotEmpty ||
        _voiceFiles.isNotEmpty) {
      if (widget.type == "group") {
        await _chatService.sendGroupMessage(
            widget.GroupId, _messageController.text,
            images: _selectedImages, voices: _voiceFiles);
      } else if (widget.type == "private") {
        await _chatService.sendPrivateMessage(
            widget.GroupId, widget.receiverUserID, _messageController.text,
            images: _selectedImages, voices: _voiceFiles);
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
        _audioPath =
            '${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.aac';
        await _recorder.startRecorder(toFile: _audioPath);
      } else {
        print("Quyền ghi âm bị từ chối!");
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
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2A2A2A),
        elevation: 0,
        title: Text(
          widget.receiverUserEmail,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(child: _buildMessageList()),
          if (_selectedImages.isNotEmpty) _buildImagePreview(),
          if (_voiceFiles.isNotEmpty) _buildVoicePreview(),
          _buildMessageInput(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    Stream<QuerySnapshot> messageStream = widget.type == "group"
        ? _chatService.getGroupMessages(widget.GroupId)
        : _chatService.getPrivateMessages(widget.GroupId,
            _firebaseAuth.currentUser!.uid, widget.receiverUserID);

    return StreamBuilder<QuerySnapshot>(
      stream: messageStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Text(
              'Error loading messages',
              style: TextStyle(color: Colors.redAccent),
            ),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.blueAccent),
          );
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            return _buildMessageItem(snapshot.data!.docs[index]);
          },
        );
      },
    );
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Widget _buildSharedPostImages(List<dynamic> imageUrls) {
    final urls = imageUrls.cast<String>();
    if (urls.isEmpty) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ImageGalleryScreen(
              imageUrls: urls,
              initialIndex: 0,
            ),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          urls[0], // Chỉ hiển thị ảnh đầu tiên
          width: double.infinity,
          height: 150,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              width: double.infinity,
              height: 150,
              color: Colors.grey[800],
              child: const Center(child: CircularProgressIndicator(color: Colors.blueAccent)),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: double.infinity,
              height: 150,
              color: Colors.grey[800],
              child: const Icon(Icons.error, color: Colors.redAccent),
            );
          },
        ),
      ),
    );
  }

  Future<Posting?> _fetchOriginalPost(String groupId, String postId) async {
    try {
      DocumentSnapshot postDoc = await FirebaseFirestore.instance
          .collection('groups')
          .doc(groupId)
          .collection('posts')
          .doc(postId)
          .get();

      if (!postDoc.exists) {
        print("Post not found for postId: $postId in groupId: $groupId");
        return null;
      }

      Map<String, dynamic> postData = postDoc.data() as Map<String, dynamic>;
      return Posting(
        postId: postId,
        groupId: groupId,
        userId: postData['userId'],
        content: postData['content'],
        videoUrl: postData['videoUrl'],
        voiceChatUrl: postData['voiceChatUrl'],
        imageUrls: postData['imageUrls'] != null
            ? List<String>.from(postData['imageUrls'])
            : null,
        timestamp: postData['timestamp'],
        comments: postData['comments'] != null
            ? List<String>.from(postData['comments'])
            : [],
        likes: postData['likes'] != null
            ? List<String>.from(postData['likes'])
            : [],
      );
    } catch (e) {
      print("Error fetching original post: $e");
      return null;
    }
  }

  Widget _buildMessageItem(DocumentSnapshot document) {
    Map<String, dynamic> data = document.data() as Map<String, dynamic>;
    var isSender = data['senderId'] == _firebaseAuth.currentUser!.uid;

    if (data['type'] == 'share_post') {
      return GestureDetector(
        onTap: () async {
          // Lấy bài đăng gốc từ Firestore
          Posting? originalPost = await _fetchOriginalPost(
            data['originalGroupId'],
            data['postId'],
          );

          if (originalPost == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Không thể tải bài đăng gốc!"),
                backgroundColor: Colors.redAccent,
              ),
            );
            return;
          }

          // Lấy trạng thái thích và số lượt thích từ Firestore
          DocumentSnapshot postDoc = await FirebaseFirestore.instance
              .collection('groups')
              .doc(originalPost.groupId)
              .collection('posts')
              .doc(originalPost.postId)
              .get();

          List<String> likes = List<String>.from(postDoc['likes'] ?? []);
          bool isLiked = likes.contains(_firebaseAuth.currentUser!.uid);
          int likeCount = likes.length;

          // Chuyển đến PostDetailScreen với bài đăng gốc
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PostDetailScreen(
                post: originalPost,
                isLiked: isLiked,
                likeCount: likeCount,
                isSaved: false, // Bạn có thể kiểm tra trạng thái saved nếu cần
                postService: GroupPostingService(),
                toggleLike: () {
                  GroupPostingService()
                      .likePost(originalPost.groupId, originalPost.postId);
                },
                toggleSave: () async {
                  try {
                    List<String> savedPosts = await Authservice().getSavedPosts();
                    bool isSaved = savedPosts.contains(originalPost.postId);
                    if (isSaved) {
                      await Authservice().unsavePost(originalPost.postId);
                    } else {
                      await Authservice().savePost(originalPost.postId);
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Lỗi khi lưu bài đăng: $e'),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                  }
                },
              ),
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blueGrey.shade800, Colors.blueGrey.shade900],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: isSender ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.share,
                    color: Colors.white70,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Bài đăng được chia sẻ',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                data['message'] ?? '',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.4,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              if (data['imageUrls'] != null && data['imageUrls'].isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: _buildSharedPostImages(data['imageUrls']),
                ),
              if (data['videoUrl'] != null && data['videoUrl'].isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.play_circle_filled,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              Text(
                'Nhấn để xem chi tiết',
                style: TextStyle(
                  color: Colors.blueAccent.shade100,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: isSender ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              data['senderEmail'],
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Row(
            mainAxisAlignment: isSender ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (!isSender) const SizedBox(width: 8),
              Flexible(
                child: Column(
                  crossAxisAlignment: isSender ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    if (data['voiceChatUrl'] != null)
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            await _audioPlayer.play(UrlSource(data['voiceChatUrl']));
                          },
                          icon: const Icon(Icons.play_arrow, size: 20),
                          label: const Text('Play Audio'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3A3A3A),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    if (data['imageUrls'] != null && data['imageUrls'].isNotEmpty)
                      ...data['imageUrls'].map<Widget>((url) => GestureDetector(
                            onTap: () {
                              _showFullScreenImage(context, url);
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey[800]!, width: 1),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  url,
                                  width: MediaQuery.of(context).size.width * 0.6,
                                  height: MediaQuery.of(context).size.height * 0.3,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return const Center(
                                        child: CircularProgressIndicator(color: Colors.blueAccent));
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      height: 100,
                                      color: Colors.grey[800],
                                      child: const Icon(Icons.error, color: Colors.redAccent),
                                    );
                                  },
                                ),
                              ),
                            ),
                          )),
                    if (data['message'] != '')
                      ChatBubble(message: data['message'], isSender: isSender),
                  ],
                ),
              ),
              if (isSender) const SizedBox(width: 8),
            ],
          ),
        ],
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
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(16),
              ),
              child: InteractiveViewer(
                panEnabled: true,
                boundaryMargin: const EdgeInsets.all(20),
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.network(imageUrl, fit: BoxFit.contain),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildImagePreview() {
    return Container(
      height: 100,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _selectedImages.length,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[800]!, width: 1),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    _selectedImages[index],
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
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
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, color: Colors.white, size: 18),
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
    return Container(
      height: 60,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _voiceFiles.length,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF3A3A3A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.play_arrow, color: Colors.blueAccent),
                  onPressed: () async {
                    await _audioPlayer.play(DeviceFileSource(_voiceFiles[index].path));
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
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
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.image, color: Colors.grey),
            onPressed: pickImages,
          ),
          IconButton(
            icon: Icon(
              isRecording ? Icons.mic : Icons.mic_none,
              color: isRecording ? Colors.redAccent : Colors.grey,
            ),
            onPressed: _toggleRecording,
          ),
          Expanded(
            child: MyTextField(
              controller: _messageController,
              hintText: "Type a message...",
              obscureText: false,
            ),
          ),
          IconButton(
            onPressed: sendMessage,
            icon: const Icon(Icons.send, color: Colors.blueAccent, size: 28),
          ),
        ],
      ),
    );
  }
}
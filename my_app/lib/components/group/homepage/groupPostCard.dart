import 'package:flutter/material.dart';
import 'package:my_app/services/group/groupPostingService.dart';
import 'package:video_player/video_player.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:my_app/model/group/posting.dart';
import 'package:firebase_auth/firebase_auth.dart';
//mport 'package:cloud_firestore/cloud_firestore.dart';

class GroupPostCard extends StatefulWidget {
  final Posting post;
  final GroupPostingService postService;
  
  const GroupPostCard({Key? key, required this.post, required this.postService}) : super(key: key);

  @override
  _GroupPostCardState createState() => _GroupPostCardState();
}

class _GroupPostCardState extends State<GroupPostCard> {
  bool isLiked = false;
  int likeCount = 0;
  final TextEditingController _commentController = TextEditingController();
  bool isCommenting = false;
  bool isCommentSectionOpen = false; 
  
  @override
  void initState() {
    super.initState();
    isLiked = widget.post.likes.contains(FirebaseAuth.instance.currentUser!.uid);
    likeCount = widget.post.likes.length;
  }

  

  void toggleLike() async {
    await widget.postService.likePost(widget.post.groupId, widget.post.postId);
    setState(() {
      isLiked = !isLiked;
      likeCount += isLiked ? 1 : -1;
    });
  }

 void addComment() async {
    if (_commentController.text.isNotEmpty && !isCommenting) {
      setState(() {
        isCommenting = true; // Bắt đầu gửi bình luận
        isCommentSectionOpen = !isCommentSectionOpen;
      });

      try {
        await widget.postService.addComment(
          widget.post.groupId,
          widget.post.postId,
          _commentController.text,
        );
        setState(() {
          widget.post.comments.add(_commentController.text);
        });
        _commentController.clear();
      } catch (e) {
        print("Lỗi khi gửi bình luận: $e");
      } finally {
        setState(() {
          isCommenting = false;
          isCommentSectionOpen = !isCommentSectionOpen;
        });
      }
    }
  }

  void toggleCommentSection() {
  setState(() {
    isCommentSectionOpen = !isCommentSectionOpen;
  });

  if (isCommentSectionOpen) {
    showModalBottomSheet(
      context: context,
      builder: (_) => _buildCommentSection(),
    ).then((_) {
      setState(() {
        isCommentSectionOpen = false; // Khi đóng lại thì cập nhật trạng thái
      });
    });
  }
}

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.post.content,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // Hiển thị hình ảnh từ URL
            if (widget.post.imageUrls != null && widget.post.imageUrls!.isNotEmpty)
              Center(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: widget.post.imageUrls!.map((imageUrl) {
                    return _buildImagePreview(context, imageUrl);
                  }).toList(),
                ),
              ),
            const SizedBox(height: 8),

            // Hiển thị video nếu có
            if (widget.post.videoUrl != null)
              _buildVideoPreview(widget.post.videoUrl!),

            const SizedBox(height: 8),

            // Hiển thị âm thanh nếu có
            if (widget.post.voiceChatUrl != null)
              _buildAudioPreview(widget.post.voiceChatUrl!),

            const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Posted on ${widget.post.timestamp.toDate()}",
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Row(
                    children: [
                      IconButton(
                        icon: Icon(isLiked ? Icons.thumb_up : Icons.thumb_up_off_alt, color: isLiked ? Colors.blue : Colors.grey),
                        onPressed: toggleLike,
                      ),
                      Text("$likeCount"),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.comment),
                    onPressed: () => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                       builder: (context) => Padding(
                        padding: EdgeInsets.only(
                          bottom: MediaQuery.of(context).viewInsets.bottom, // Đẩy UI lên khi bàn phím mở
                        ),
                        child: _buildCommentSection(),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Danh sách bình luận 
         widget.post.comments.isEmpty
            ? const Text("Chưa có bình luận nào.")
            : ListView(
                shrinkWrap: true,
                children: widget.post.comments.map((comment) {
                  List<String> parts = comment.split(': ');
                  String email = parts.isNotEmpty ? parts[0] : 'Ẩn danh';
                  String content = parts.length > 1 ? parts.sublist(1).join(': ') : '';

                  return ListTile(
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          email,
                          style: TextStyle(fontSize: 12), 
                        ),
                        Text(
                          content,
                          style: TextStyle(fontSize: 16), 
                        ),
                        Divider(),
                      ],
                    ),
                  );
                }).toList(),
              ),

          //Comment
          SingleChildScrollView(
            reverse: true,
            child: TextField(
              controller: _commentController,
              decoration: InputDecoration(
                labelText: "Viết bình luận...",
                suffixIcon: IconButton(
                  icon: isCommenting ? CircularProgressIndicator() : const Icon(Icons.send),
                  onPressed: isCommenting ? null : addComment, //ko cho nhấn lúc gửi
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Widget hiển thị ảnh từ URL
  Widget _buildImagePreview(BuildContext context, String imageUrl) {
    return GestureDetector(
      onTap: () {
        _showFullScreenImage(context, imageUrl);
      },
      child: Image.network(
        imageUrl,
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
    );
  }

  /// Hiển thị ảnh phóng to
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

  /// Widget hiển thị video từ URL
  Widget _buildVideoPreview(String videoUrl) {
    return Container(
      width: double.infinity, 
      constraints: const BoxConstraints(
        maxHeight: 250, 
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12), 
        child: VideoPlayerWidget(videoUrl: videoUrl),
      ),
    );
  }


  /// Widget hiển thị âm thanh từ URL
  Widget _buildAudioPreview(String audioUrl) {
    return AudioPlayerWidget(audioUrl: audioUrl);
  }
}

///Hiện thị video
class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  const VideoPlayerWidget({Key? key, required this.videoUrl}) : super(key: key);

  @override
  _VideoPlayerWidgetState createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.videoUrl)
      ..initialize().then((_) {
        setState(() {});
      });
  }

  @override
  Widget build(BuildContext context) {
    return _controller.value.isInitialized
        ? ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  VideoPlayer(_controller),
                  IconButton(
                    icon: Icon(
                      _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      setState(() {
                        _controller.value.isPlaying ? _controller.pause() : _controller.play();
                      });
                    },
                  ),
                ],
              ),
            ),
          )
        : const Center(child: CircularProgressIndicator());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}


/// Widget để phát âm thanh từ URL
class AudioPlayerWidget extends StatefulWidget {
  final String audioUrl;
  const AudioPlayerWidget({Key? key, required this.audioUrl}) : super(key: key);

  @override
  _AudioPlayerWidgetState createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool isPlaying = false;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.audiotrack, size: 30),
        const SizedBox(width: 8),
        Text(
          "🎵 Tệp âm thanh",
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        IconButton(
          icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
          onPressed: () async {
            if (isPlaying) {
              await _audioPlayer.pause();
            } else {
              await _audioPlayer.play(UrlSource(widget.audioUrl));
            }
            setState(() {
              isPlaying = !isPlaying;
            });
          },
        ),
      ],
    );
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}

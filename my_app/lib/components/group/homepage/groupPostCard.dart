import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:my_app/model/group/posting.dart';

class GroupPostCard extends StatelessWidget {
  final Posting post;

  const GroupPostCard({Key? key, required this.post}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              post.content,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // Hiển thị hình ảnh từ URL
            if (post.imageUrls != null && post.imageUrls!.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: post.imageUrls!.map((imageUrl) {
                  return _buildImagePreview(context, imageUrl);
                }).toList(),
              ),

            const SizedBox(height: 8),

            // Hiển thị video nếu có
            if (post.videoUrl != null)
              _buildVideoPreview(post.videoUrl!),

            const SizedBox(height: 8),

            // Hiển thị âm thanh nếu có
            if (post.voiceChatUrl != null)
              _buildAudioPreview(post.voiceChatUrl!),

            const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Posted on ${post.timestamp.toDate()}",
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                IconButton(
                  icon: const Icon(Icons.thumb_up),
                  onPressed: () {
                    // Xử lý like bài đăng
                  },
                ),
              ],
            ),
          ],
        ),
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
        height: MediaQuery.of(context).size.height * 0.3,
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
    return VideoPlayerWidget(videoUrl: videoUrl);
  }

  /// Widget hiển thị âm thanh từ URL
  Widget _buildAudioPreview(String audioUrl) {
    return AudioPlayerWidget(audioUrl: audioUrl);
  }
}

/// Widget để phát video từ URL
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
        ? AspectRatio(
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

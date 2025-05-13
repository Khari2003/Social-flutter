import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerWidget2 extends StatefulWidget {
  final String videoUrl;

  const VideoPlayerWidget2({Key? key, required this.videoUrl})
      : super(key: key);

  @override
  _VideoPlayerWidgetState2 createState() => _VideoPlayerWidgetState2();
}

class _VideoPlayerWidgetState2 extends State<VideoPlayerWidget2> {
  late VideoPlayerController _controller;
  bool _isPlaying = false;
  bool _isSeeking = false;
  // ignore: unused_field
  late double _videoPosition;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.videoUrl)
      ..initialize().then((_) {
        setState(() {});
      })
      ..addListener(() {
        if (!_isSeeking) {
          setState(() {
            _videoPosition =
                _controller.value.position.inMilliseconds.toDouble();
          });
        }
      });
  }

  void _togglePlayPause() {
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
        _isPlaying = false;
      } else {
        _controller.play();
        _isPlaying = true;
      }
    });
  }

  // void _seekTo(double value) {
  //   final position = Duration(milliseconds: value.toInt());
  //   _controller.seekTo(position);
  //   _controller.play();
  //   _isPlaying = true;
  // }

  @override
  Widget build(BuildContext context) {
    return _controller.value.isInitialized
        ? GestureDetector(
            onTap: _togglePlayPause,
            child: Stack(
              alignment: Alignment.center,
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: VideoPlayer(_controller),
                ),
                AnimatedOpacity(
                  opacity: _isPlaying ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 300),
                  child: const Icon(
                    Icons.play_circle_fill,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          )
        : const Center(child: CircularProgressIndicator());
  }

  // String _formatDuration(Duration duration) {
  //   String twoDigits(int n) => n.toString().padLeft(2, '0');
  //   String minutes = twoDigits(duration.inMinutes.remainder(60));
  //   String seconds = twoDigits(duration.inSeconds.remainder(60));
  //   return "$minutes:$seconds";
  // }

  // Widget _buildSliderAndTime() {
  //   return Column(
  //     mainAxisSize: MainAxisSize.min,
  //     children: [
  //       Slider(
  //         min: 0.0,
  //         max: _controller.value.duration.inMilliseconds.toDouble(),
  //         value: _isSeeking
  //             ? _videoPosition
  //             : _controller.value.position.inMilliseconds.toDouble(),
  //         onChanged: (value) {
  //           setState(() {
  //             _isSeeking = true;
  //             _videoPosition = value;
  //           });
  //         },
  //         onChangeEnd: (value) {
  //           _seekTo(value);
  //           setState(() {
  //             _isSeeking = false;
  //           });
  //         },
  //         activeColor: Colors.white,
  //         inactiveColor: Colors.white.withOpacity(0.5),
  //       ),
  //       Padding(
  //         padding: const EdgeInsets.symmetric(horizontal: 10),
  //         child: Row(
  //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //           children: [
  //             Text(
  //               _formatDuration(_controller.value.position),
  //               style: const TextStyle(color: Colors.white, fontSize: 12),
  //             ),
  //             Text(
  //               _formatDuration(_controller.value.duration),
  //               style: const TextStyle(color: Colors.white, fontSize: 12),
  //             ),
  //           ],
  //         ),
  //       ),
  //     ],
  //   );
  // }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

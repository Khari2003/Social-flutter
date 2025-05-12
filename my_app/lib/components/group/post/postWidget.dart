import 'package:flutter/material.dart';
import 'package:my_app/components/group/post/postMessBubble.dart';
import 'package:my_app/components/group/post/post_utils/videoPlayerWidget.dart';
import 'package:my_app/components/group/post/post_utils/videoPlayerWiget2.dart';
import 'package:my_app/model/group/posting.dart';
import 'package:video_player/video_player.dart';

/// Widget hiển thị danh sách bình luận
const Color defaultBackgroundColor = Colors.black87;

Widget buildCommentSection(
  Posting post,
  BuildContext context, {
  TextEditingController? controller,
  bool? isLiked,
  int? likeCount,
  bool? isCommenting,
  VoidCallback? addComment,
  VoidCallback? toggleLike,
  bool isComment = true,
  bool isfullheight = true,
  ScrollController? scrollController,
  required Stream<List<String>> commentStream,
}) {
  return Container(
    height: MediaQuery.of(context).size.height * 0.6,
    padding: const EdgeInsets.only(top: 12),
    child: Column(
      children: [
        if (isComment) buildLikeSection(post, isLiked!, likeCount!, toggleLike),
        // Danh sách bình luận
        Expanded(
          child: StreamBuilder<List<String>>(
            stream: commentStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                  child: Text(
                    "Chưa có bình luận nào.",
                    style: TextStyle(color: Colors.white),
                  ),
                );
              }
              final comments = snapshot.data!;
              return ListView.builder(
                controller: scrollController,
                itemCount: comments.length,
                itemBuilder: (context, index) {
                  String comment = comments[index].toString();
                  List<String> parts = comment.split(': ');
                  String email = parts.isNotEmpty ? parts[0] : 'Ẩn danh';
                  String name =
                      email.contains('@') ? email.split('@')[0] : email;
                  String content =
                      parts.length > 1 ? parts.sublist(1).join(': ') : '';

                  return Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    child: PostMessBubble(email: name, message: content),
                  );
                },
              );
            },
          ),
        ),
        if (isComment)
          buildCommentInput(
            context: context,
            controller: controller!,
            isCommenting: isCommenting!,
            addComment: addComment!,
          ),
      ],
    ),
  );
}

Widget buildLikeSection(
    Posting post, bool isLiked, int likeCount, VoidCallback? toggleLike) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(
              Icons.thumb_up,
              color: isLiked ? Colors.blue : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 4),
            Text(
              "$likeCount lượt thích",
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
              ),
            ),
          ],
        ),
        IconButton(
          icon: Icon(
            isLiked ? Icons.thumb_up : Icons.thumb_up_off_alt,
            color: isLiked ? Colors.blue : Colors.grey,
          ),
          onPressed: toggleLike,
        ),
      ],
    ),
  );
}

/// Widget nhập bình luận
Widget buildCommentInput({
  required BuildContext context,
  required TextEditingController controller,
  required bool isCommenting,
  required VoidCallback addComment,
}) {
  return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context)
            .viewInsets
            .bottom, 
        top: 8,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: const BoxDecoration(
          color: Color.fromARGB(255, 37, 39, 40),
          border: Border(top: BorderSide(color: Colors.grey)),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: "Viết bình luận...",
                  labelStyle: TextStyle(
                      color: Color.fromARGB(
                    255,
                    226,
                    229,
                    233,
                  )),
                  border: InputBorder.none,
                ),
              ),
            ),
            IconButton(
              icon: isCommenting
                  ? const CircularProgressIndicator()
                  : const Icon(Icons.send, color: Colors.blue),
              onPressed: isCommenting ? null : addComment,
            ),
          ],
        ),
      ));
}

/// Widget hiển thị hình ảnh
Widget buildImagePreview(BuildContext context, String imageUrl) {
  return GestureDetector(
    onTap: () {
      showFullScreenImage(context, imageUrl);
    },
    child: Center(
      child: Image.network(
        imageUrl,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(child: CircularProgressIndicator());
        },
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.error, color: Colors.red);
        },
      ),
    ),
  );
}

/// Hiển thị ảnh phóng to
void showFullScreenImage(BuildContext context, String imageUrl) {
  showDialog(
    context: context,
    builder: (context) {
      final size = MediaQuery.of(context).size;
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero, // loại bỏ padding mặc định
        child: SizedBox(
          width: size.width,
          height: size.height,
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
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

/// Widget hiển thị video
Widget buildVideoPreview(BuildContext context, String videoUrl,
    {VideoPlayerController? controller, bool limitHeight = true}) {
  return Container(
    child: ClipRRect(
      child: controller == null
          ? VideoPlayerWidget2(videoUrl: videoUrl)
          : VideoPlayerWidget(controller: controller),
    ),
  );
}

/// Widget hiển thị âm thanh (Placeholder)
Widget buildAudioPreview(String audioUrl) {
  return Container(
    height: 50,
    color: Colors.black12,
    alignment: Alignment.center,
    child: const Text("Audio Preview (Placeholder)"),
  );
}

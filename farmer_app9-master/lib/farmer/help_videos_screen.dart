import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class HelpVideoScreen extends StatelessWidget {
  const HelpVideoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Help & Demo Videos"),
        backgroundColor: Colors.green[800],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          VideoCard(
            title: "How to Add Product",
            assetPath: "assets/videos/ap1.mp4",
          ),
        ],
      ),
    );
  }
}

class VideoCard extends StatelessWidget {
  final String title;
  final String assetPath;

  const VideoCard({
    super.key,
    required this.title,
    required this.assetPath,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      elevation: 4,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: const Icon(
          Icons.play_circle_fill,
          color: Colors.green,
          size: 40,
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  VideoPlayerScreen(assetPath: assetPath),
            ),
          );
        },
      ),
    );
  }
}

class VideoPlayerScreen extends StatefulWidget {
  final String assetPath;

  const VideoPlayerScreen({
    super.key,
    required this.assetPath,
  });

  @override
  State<VideoPlayerScreen> createState() =>
      _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _controller;
  bool _showControls = true;
  bool _isLongPressing = false;

  @override
  void initState() {
    super.initState();

    _controller =
        VideoPlayerController.asset(widget.assetPath);

    _controller.initialize().then((_) {
      setState(() {});
      _controller.play();
    }).catchError((error) {
      print("Video load error: $error");
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
  }

  void _seekForward() async {
    final position = await _controller.position;
    if (position != null) {
      _controller.seekTo(position + const Duration(seconds: 10));
    }
  }

  void _seekBackward() async {
    final position = await _controller.position;
    if (position != null) {
      _controller.seekTo(position - const Duration(seconds: 10));
    }
  }

  String _formatDuration(Duration d) {
    final minutes =
    d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds =
    d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Demo Video"),
        backgroundColor: Colors.green[800],
      ),
      body: _controller.value.isInitialized
          ? GestureDetector(
        onTap: _toggleControls,

        // Long press → 2x speed
        onLongPressStart: (_) {
          _isLongPressing = true;
          _controller.setPlaybackSpeed(2.0);
        },
        onLongPressEnd: (_) {
          _isLongPressing = false;
          _controller.setPlaybackSpeed(1.0);
        },

        child: Stack(
          alignment: Alignment.center,
          children: [

            // VIDEO
            AspectRatio(
              aspectRatio:
              _controller.value.aspectRatio,
              child: VideoPlayer(_controller),
            ),

            // DOUBLE TAP AREAS
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onDoubleTap: _seekBackward,
                    child: Container(
                      color: Colors.transparent,
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onDoubleTap: _seekForward,
                    child: Container(
                      color: Colors.transparent,
                    ),
                  ),
                ),
              ],
            ),

            // CONTROLS
            if (_showControls)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  color: Colors.black54,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [

                      VideoProgressIndicator(
                        _controller,
                        allowScrubbing: true,
                        colors: const VideoProgressColors(
                          playedColor: Colors.green,
                          bufferedColor: Colors.white54,
                          backgroundColor: Colors.grey,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Row(
                        mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                        children: [

                          IconButton(
                            icon: Icon(
                              _controller.value.isPlaying
                                  ? Icons.pause
                                  : Icons.play_arrow,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              setState(() {
                                _controller.value.isPlaying
                                    ? _controller.pause()
                                    : _controller.play();
                              });
                            },
                          ),

                          Text(
                            _formatDuration(
                                _controller.value.position) +
                                " / " +
                                _formatDuration(
                                    _controller.value.duration),
                            style: const TextStyle(
                                color: Colors.white),
                          ),

                          Text(
                            _isLongPressing ? "2x" : "1x",
                            style: const TextStyle(
                                color: Colors.white),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      )
          : const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
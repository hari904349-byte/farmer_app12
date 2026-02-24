import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class VoicePlayerWidget extends StatefulWidget {
  final String url;

  const VoicePlayerWidget({super.key, required this.url});

  @override
  State<VoicePlayerWidget> createState() =>
      _VoicePlayerWidgetState();
}

class _VoicePlayerWidgetState
    extends State<VoicePlayerWidget> {

  final AudioPlayer _player = AudioPlayer();
  bool isPlaying = false;

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    if (isPlaying) {
      await _player.stop();
    } else {
      await _player.setUrl(widget.url);
      await _player.play();
    }

    setState(() {
      isPlaying = !isPlaying;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.green[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(
              isPlaying
                  ? Icons.stop
                  : Icons.play_arrow,
              color: Colors.green,
            ),
            onPressed: _togglePlay,
          ),
          const Text("Voice Message"),
        ],
      ),
    );
  }
}
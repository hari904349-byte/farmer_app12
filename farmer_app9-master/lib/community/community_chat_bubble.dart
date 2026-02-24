import 'package:flutter/material.dart';
import 'voice_player_widget.dart';

class CommunityChatBubble extends StatelessWidget {
  final Map<String, dynamic> message;
  final String currentUserId;

  const CommunityChatBubble({
    super.key,
    required this.message,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final isMe = message['sender_id'] == currentUserId;

    final text = message['message'];
    final imageUrl = message['image_url'];
    final voiceUrl = message['voice_url'];

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      child: Row(
        mainAxisAlignment:
        isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          if (!isMe) _profileImage(),

          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.25,
              ),
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isMe ? Colors.green[400] : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft:
                  isMe ? const Radius.circular(16) : Radius.zero,
                  bottomRight:
                  isMe ? Radius.zero : const Radius.circular(16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  if (text != null)
                    Text(
                      text,
                      style: const TextStyle(fontSize: 14),
                    ),

                  if (imageUrl != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          imageUrl,
                          height: 150,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),

                  if (voiceUrl != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: VoicePlayerWidget(url: voiceUrl),
                    ),

                  const SizedBox(height: 4),

                  Align(
                    alignment: Alignment.bottomRight,
                    child: Text(
                      _formatTime(message['created_at']),
                      style: const TextStyle(
                          fontSize: 10,
                          color: Colors.black54),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileImage() {
    final img = message['farmer_image'];

    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: CircleAvatar(
        radius: 16,
        backgroundImage:
        img != null ? NetworkImage(img) : null,
        child: img == null
            ? const Icon(Icons.person, size: 16)
            : null,
      ),
    );
  }

  String _formatTime(String? date) {
    if (date == null) return '';
    final dt = DateTime.parse(date).toLocal();
    return "${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
  }
}
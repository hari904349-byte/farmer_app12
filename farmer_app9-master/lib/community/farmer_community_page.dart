import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'community_chat_bubble.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class FarmerCommunityPage extends StatefulWidget {
  const FarmerCommunityPage({super.key});

  @override
  State<FarmerCommunityPage> createState() =>
      _FarmerCommunityPageState();
}

class _FarmerCommunityPageState
    extends State<FarmerCommunityPage> {

  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final supabase = Supabase.instance.client;
  final Record _record = Record();
  bool isRecording = false;
  String? audioPath;
  @override
  @override
  void dispose() {
    _record.dispose();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ================= SEND TEXT =================

  Future<void> sendMessage() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final text = _controller.text.trim();
    if (text.isEmpty) return;

    await supabase.from('community_messages').insert({
      'sender_id': user.id,
      'message': text,
    });

    _controller.clear();
    _scrollToBottom();
  }

  // ================= SEND IMAGE =================

  Future<void> sendImage() async {
    final picker = ImagePicker();
    final file =
    await picker.pickImage(source: ImageSource.gallery);

    if (file == null) return;

    final bytes = await file.readAsBytes();
    final fileName =
    DateTime.now().millisecondsSinceEpoch.toString();

    await supabase.storage
        .from('community-images')
        .uploadBinary(fileName, bytes);

    final imageUrl =
    supabase.storage.from('community-images')
        .getPublicUrl(fileName);

    await supabase.from('community_messages').insert({
      'sender_id': supabase.auth.currentUser!.id,
      'image_url': imageUrl,
    });

    _scrollToBottom();
  }

  // ================= VOICE =================

  Future<void> toggleRecording() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    if (!isRecording) {
      final hasPermission = await _record.hasPermission();
      if (!hasPermission) return;

      final dir = await getTemporaryDirectory();
      audioPath =
      '${dir.path}/${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _record.start(
        path: audioPath!,
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        samplingRate: 44100,
      );

      setState(() => isRecording = true);
    } else {
      final path = await _record.stop();
      setState(() => isRecording = false);

      if (path != null) {
        await uploadVoice(File(path));
      }
    }
  }

  Future<void> uploadVoice(File file) async {
    final fileName =
    DateTime.now().millisecondsSinceEpoch.toString();

    final bytes = await file.readAsBytes();

    await supabase.storage
        .from('community-voice')
        .uploadBinary(fileName, bytes);

    final voiceUrl =
    supabase.storage.from('community-voice')
        .getPublicUrl(fileName);

    await supabase.from('community_messages').insert({
      'sender_id': supabase.auth.currentUser!.id,
      'voice_url': voiceUrl,
    });

    _scrollToBottom();
  }

  // ================= CREATE POLL =================

  Future<void> createPoll(
      String product, double price) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    await supabase.from('price_polls').insert({
      'product_name': product,
      'suggested_price': price,
      'created_by': user.id,
    });
  }

  // ================= VOTE =================

  Future<void> votePoll(String pollId) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    // 🔍 Check if already voted
    final existing = await supabase
        .from('poll_votes')
        .select()
        .eq('poll_id', pollId)
        .eq('farmer_id', user.id);

    if (existing.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("You already voted"),
        ),
      );
      return;
    }

    // ✅ Insert vote
    await supabase.from('poll_votes').insert({
      'poll_id': pollId,
      'farmer_id': user.id,
    });
  }

  // ================= SCROLL =================

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration:
          const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    final currentUser =
        supabase.auth.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text("Farmer Community"),
        backgroundColor: Colors.green,
      ),
      body: Column(
        children: [

          // ================= POLLS =================

          StreamBuilder(
            stream: supabase
                .from('price_polls')
                .stream(primaryKey: ['id'])
                .order('created_at',
                ascending: false),
            builder: (context, snapshot) {

              if (!snapshot.hasData) {
                return const SizedBox();
              }

              final polls = snapshot.data!;

              if (polls.isEmpty) {
                return const SizedBox();
              }

              return Column(
                children: polls.map((poll) {
                  return Card(
                    margin:
                    const EdgeInsets.all(8),
                    child: ListTile(
                      title: Text(
                        "${poll['product_name']} - ₹${poll['suggested_price']}",
                        style:
                        const TextStyle(
                            fontWeight:
                            FontWeight.bold),
                      ),
                      subtitle:
                      VoteCountWidget(
                          pollId:
                          poll['id']),
                      trailing:
                      IconButton(
                        icon: const Icon(
                            Icons
                                .how_to_vote),
                        onPressed: () =>
                            votePoll(
                                poll['id']),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),

          // ================= CHAT =================

          Expanded(
            child: StreamBuilder(
              stream: supabase
                  .from(
                  'community_messages')
                  .stream(
                  primaryKey: ['id'])
                  .order('created_at'),
              builder: (context, snapshot) {

                if (!snapshot.hasData) {
                  return const Center(
                      child:
                      CircularProgressIndicator());
                }

                final messages =
                snapshot.data!;

                return ListView.builder(
                  controller:
                  _scrollController,
                  padding:
                  const EdgeInsets.all(
                      10),
                  itemCount:
                  messages.length,
                  itemBuilder:
                      (context, index) {

                    final msg =
                    messages[index];

                    return CommunityChatBubble(
                      message: msg,
                      currentUserId:
                      currentUser!
                          .id,
                    );
                  },
                );
              },
            ),
          ),

          // ================= INPUT =================

          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 6),
            color: Colors.white,
            child: Row(
              children: [

                IconButton(
                  icon: const Icon(
                      Icons.poll,
                      color: Colors.green),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder:
                          (context) {

                        final productController =
                        TextEditingController();
                        final priceController =
                        TextEditingController();

                        return AlertDialog(
                          title: const Text(
                              "Create Price Poll"),
                          content: Column(
                            mainAxisSize:
                            MainAxisSize
                                .min,
                            children: [
                              TextField(
                                controller:
                                productController,
                                decoration:
                                const InputDecoration(
                                    labelText:
                                    "Product Name"),
                              ),
                              TextField(
                                controller:
                                priceController,
                                keyboardType:
                                TextInputType
                                    .number,
                                decoration:
                                const InputDecoration(
                                    labelText:
                                    "Suggested Price"),
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed:
                                  () async {
                                await createPoll(
                                  productController
                                      .text,
                                  double.parse(
                                      priceController
                                          .text),
                                );
                                Navigator.pop(
                                    context);
                              },
                              child: const Text(
                                  "Create"),
                            )
                          ],
                        );
                      },
                    );
                  },
                ),

                IconButton(
                  icon: const Icon(
                      Icons.image,
                      color: Colors.green),
                  onPressed: sendImage,
                ),

                IconButton(
                  icon: Icon(
                    isRecording
                        ? Icons.stop
                        : Icons.mic,
                    color: isRecording
                        ? Colors.red
                        : Colors.green,
                  ),
                  onPressed:
                  toggleRecording,
                ),

                Expanded(
                  child: Container(
                    padding:
                    const EdgeInsets
                        .symmetric(
                        horizontal:
                        12),
                    decoration:
                    BoxDecoration(
                      color: Colors
                          .grey[200],
                      borderRadius:
                      BorderRadius
                          .circular(
                          25),
                    ),
                    child: TextField(
                      controller:
                      _controller,
                      decoration:
                      const InputDecoration(
                        hintText:
                        "Type a message",
                        border:
                        InputBorder
                            .none,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 5),

                CircleAvatar(
                  backgroundColor:
                  Colors.green,
                  child: IconButton(
                    icon: const Icon(
                        Icons.send,
                        color:
                        Colors.white),
                    onPressed:
                    sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ================= LIVE VOTE COUNT =================

class VoteCountWidget extends StatelessWidget {
  final String pollId;

  const VoteCountWidget(
      {super.key, required this.pollId});

  @override
  Widget build(BuildContext context) {
    final supabase =
        Supabase.instance.client;

    return StreamBuilder(
      stream: supabase
          .from('poll_votes')
          .stream(primaryKey: ['id']),
      builder: (context, snapshot) {

        if (!snapshot.hasData) {
          return const Text("0 votes");
        }

        final votes = snapshot.data!
            .where((v) =>
        v['poll_id'] ==
            pollId)
            .toList();

        return Text(
            "${votes.length} farmers voted");
      },
    );
  }
}
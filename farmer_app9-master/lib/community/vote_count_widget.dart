import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
class VoteCountWidget extends StatelessWidget {
  final String pollId;

  const VoteCountWidget({super.key, required this.pollId});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;

    return StreamBuilder(
      stream: supabase
          .from('poll_votes')
          .stream(primaryKey: ['id']),
      builder: (context, snapshot) {

        if (!snapshot.hasData) {
          return const Text("0 farmers voted");
        }

        final allVotes = snapshot.data as List;

        final pollVotes = allVotes
            .where((vote) => vote['poll_id'] == pollId)
            .toList();

        return Text("${pollVotes.length} farmers voted");
      },
    );
  }
}
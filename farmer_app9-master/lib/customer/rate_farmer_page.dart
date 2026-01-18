import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RateFarmerPage extends StatefulWidget {
  final String farmerId;
  final String orderId;

  const RateFarmerPage({
    super.key,
    required this.farmerId,
    required this.orderId,
  });

  @override
  State<RateFarmerPage> createState() => _RateFarmerPageState();
}

class _RateFarmerPageState extends State<RateFarmerPage> {
  final SupabaseClient supabase = Supabase.instance.client;

  int rating = 5;
  final TextEditingController commentController = TextEditingController();
  bool submitting = false;

  @override
  void dispose() {
    commentController.dispose();
    super.dispose();
  }

  Future<void> submitRating() async {
    if (submitting) return;

    final user = supabase.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please login to submit rating")),
      );
      return;
    }

    setState(() => submitting = true);

    try {
      await supabase.from('ratings').insert({
        'order_id': widget.orderId,
        'customer_id': user.id,
        'farmer_id': widget.farmerId,
        'rating': rating,
        'comment': commentController.text.trim().isEmpty
            ? null
            : commentController.text.trim(),
        'rating_type': 'farmer',
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Farmer rated successfully")),
      );

      Navigator.pop(context);
    } on PostgrestException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error submitting rating")),
      );
    } finally {
      if (mounted) {
        setState(() => submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Rate Farmer"),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "How was your experience?",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            // ⭐ STAR RATING
            Row(
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 32,
                  ),
                  onPressed: () {
                    setState(() => rating = index + 1);
                  },
                );
              }),
            ),

            const SizedBox(height: 20),

            // 💬 COMMENT
            TextField(
              controller: commentController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: "Comment (optional)",
                border: OutlineInputBorder(),
              ),
            ),

            const Spacer(),

            // ✅ SUBMIT BUTTON
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
                onPressed: submitting ? null : submitRating,
                child: submitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Submit Rating"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

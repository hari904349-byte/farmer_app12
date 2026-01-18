import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class ShowRating extends StatefulWidget {
  const ShowRating({super.key});

  @override
  State<ShowRating> createState() => _ShowRatingState();
}

class _ShowRatingState extends State<ShowRating> {
  final supabase = Supabase.instance.client;

  late Future<List<Map<String, dynamic>>> _ratingsFuture;

  @override
  void initState() {
    super.initState();
    _ratingsFuture = _fetchRatings();
  }

  // ================= FETCH RATINGS =================
  Future<List<Map<String, dynamic>>> _fetchRatings() async {
    final farmerId = supabase.auth.currentUser!.id;

    final data = await supabase
        .from('ratings')
        .select('''
          rating,
          comment,
          created_at,
          customer:customer_id (
            name,
            avatar_url
          )
        ''')
        .eq('farmer_id', farmerId)
        .eq('rating_type', 'farmer')
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(data);
  }

  // ================= IMAGE HELPER =================
  String publicImage(String? path) {
    if (path == null || path.isEmpty) return '';
    return path.startsWith('http')
        ? path
        : supabase.storage.from('avatars').getPublicUrl(path);
  }

  // ================= CALCULATIONS =================
  double averageRating(List<Map<String, dynamic>> ratings) {
    final total =
    ratings.fold<int>(0, (sum, r) => sum + (r['rating'] as int));
    return total / ratings.length;
  }

  Map<int, int> ratingCount(List<Map<String, dynamic>> ratings) {
    final Map<int, int> count = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    for (final r in ratings) {
      count[r['rating']] = count[r['rating']]! + 1;
    }
    return count;
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Customer Ratings"),
        backgroundColor: Colors.green,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _ratingsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No ratings yet"));
          }

          final ratings = snapshot.data!;
          final avg = averageRating(ratings);
          final counts = ratingCount(ratings);

          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              // ================= AVERAGE =================
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        avg.toStringAsFixed(1),
                        style: const TextStyle(
                            fontSize: 36, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          5,
                              (i) => Icon(
                            i < avg.round()
                                ? Icons.star
                                : Icons.star_border,
                            color: Colors.amber,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Based on ${ratings.length} ratings",
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ================= RATING GRAPH =================
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: List.generate(5, (i) {
                      final star = 5 - i;
                      final value = counts[star]!;
                      final percent = value / ratings.length;

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Text("$star★"),
                            const SizedBox(width: 8),
                            Expanded(
                              child: LinearProgressIndicator(
                                value: percent,
                                minHeight: 8,
                                backgroundColor: Colors.grey.shade300,
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(value.toString()),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ================= INDIVIDUAL REVIEWS =================
              ...ratings.map((r) {
                final customer = r['customer'];
                final name = customer?['name'] ?? 'Customer';
                final avatar = publicImage(customer?['avatar_url']);
                final date = DateFormat('dd MMM yyyy')
                    .format(DateTime.parse(r['created_at']));
                final rating = r['rating'];
                final comment = r['comment'] ?? '';

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundImage:
                              avatar.isNotEmpty ? NetworkImage(avatar) : null,
                              child: avatar.isEmpty
                                  ? const Icon(Icons.person)
                                  : null,
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                                Text(date,
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.grey)),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: List.generate(
                            5,
                                (i) => Icon(
                              i < rating
                                  ? Icons.star
                                  : Icons.star_border,
                              color: Colors.amber,
                              size: 20,
                            ),
                          ),
                        ),
                        if (comment.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(comment),
                        ],
                      ],
                    ),
                  ),
                );
              }).toList(),
            ],
          );
        },
      ),
    );
  }
}

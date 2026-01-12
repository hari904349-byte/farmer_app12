import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'add_offer.dart';

class OffersList extends StatefulWidget {
  const OffersList({super.key});

  @override
  State<OffersList> createState() => _OffersListState();
}

class _OffersListState extends State<OffersList> {
  final supabase = Supabase.instance.client;

  bool loading = true;
  List offers = [];

  @override
  void initState() {
    super.initState();
    fetchOffers();
  }

  // ================= FETCH OFFERS (WITH PRODUCT JOIN) =================
  Future<void> fetchOffers() async {
    try {
      final userId = supabase.auth.currentUser!.id;

      final data = await supabase
          .from('offers')
          .select('''
            id,
            discount_type,
            discount_value,
            start_date,
            end_date,
            created_at,
            products (
              id,
              name
            )
          ''')
          .eq('farmer_id', userId)
          .order('created_at', ascending: false);

      setState(() {
        offers = data;
        loading = false;
      });
    } catch (e) {
      debugPrint("Fetch offers error: $e");
      setState(() => loading = false);
    }
  }

  // ================= DELETE OFFER =================
  Future<void> deleteOffer(String id) async {
    await supabase.from('offers').delete().eq('id', id);
    fetchOffers();
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Offers & Discounts"),
        backgroundColor: Colors.green,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        child: const Icon(Icons.add),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddOffer()),
          );
          fetchOffers();
        },
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : offers.isEmpty
          ? const Center(child: Text("No offers created yet"))
          : ListView.builder(
        itemCount: offers.length,
        itemBuilder: (context, index) {
          final offer = offers[index];
          final product = offer['products'];

          final productName =
          product != null ? product['name'] : 'Unknown Product';

          return Card(
            margin: const EdgeInsets.all(10),
            child: ListTile(
              title: Text(
                productName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Type: ${offer['discount_type']}",
                  ),
                  Text(
                    "Value: ${offer['discount_value']}",
                  ),
                  Text(
                    "From: ${offer['start_date']}",
                  ),
                  Text(
                    "To: ${offer['end_date']}",
                  ),
                ],
              ),
              trailing: IconButton(
                icon:
                const Icon(Icons.delete, color: Colors.red),
                onPressed: () =>
                    deleteOffer(offer['id']),
              ),
            ),
          );
        },
      ),
    );
  }
}

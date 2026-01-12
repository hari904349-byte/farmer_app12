import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CustomerOffers extends StatefulWidget {
  const CustomerOffers({super.key});

  @override
  State<CustomerOffers> createState() => _CustomerOffersState();
}

class _CustomerOffersState extends State<CustomerOffers> {
  final supabase = Supabase.instance.client;

  bool loading = true;
  List offers = [];

  /// offerId -> quantity
  final Map<String, int> quantities = {};

  @override
  void initState() {
    super.initState();
    fetchOffers();
  }

  // ================= FETCH ACTIVE OFFERS =================
  Future<void> fetchOffers() async {
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];

      final data = await supabase
          .from('offers')
          .select('''
            id,
            discount_type,
            discount_value,
            start_date,
            end_date,
            products (
              id,
              name,
              price,
              image_url,
              profiles(name)
            )
          ''')
          .lte('start_date', today)
          .gte('end_date', today)
          .order('created_at', ascending: false);

      setState(() {
        offers = data;
        for (var o in offers) {
          quantities[o['id']] = 1;
        }
        loading = false;
      });
    } catch (e) {
      debugPrint("Customer offers error: $e");
      setState(() => loading = false);
    }
  }

  // ================= FINAL PRICE =================
  int getFinalPrice(int price, String type, int value) {
    if (type == 'percentage') {
      return price - ((price * value) ~/ 100);
    } else {
      return price - value;
    }
  }

  // ================= ADD TO CART =================
  Future<void> addToCart(Map offer) async {
    final userId = supabase.auth.currentUser!.id;
    final product = offer['products'];
    final qty = quantities[offer['id']] ?? 1;

    final discountedPrice = getFinalPrice(
      product['price'],
      offer['discount_type'],
      offer['discount_value'],
    );

    try {
      final existing = await supabase
          .from('cart')
          .select('id, quantity')
          .eq('customer_id', userId)
          .eq('product_id', product['id'])
          .maybeSingle();

      if (existing != null) {
        await supabase.from('cart').update({
          'quantity': (existing['quantity'] as int) + qty,
        }).eq('id', existing['id']);
      } else {
        await supabase.from('cart').insert({
          'customer_id': userId,
          'product_id': product['id'],
          'product_name': product['name'],
          'price': product['price'],
          'quantity': qty,
          'discount': offer['discount_value'],
          'final_price': discountedPrice,
          'offer_id': offer['id'],
        });
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Added to cart"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Add to cart failed: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Available Offers"),
        backgroundColor: Colors.green,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : offers.isEmpty
          ? const Center(child: Text("No offers available"))
          : ListView.builder(
        itemCount: offers.length,
        itemBuilder: (context, index) {
          final offer = offers[index];
          final product = offer['products'];
          if (product == null) return const SizedBox();

          final qty = quantities[offer['id']] ?? 1;
          final farmerName =
              product['profiles']?['name'] ?? 'Farmer';

          String? imageUrl;
          if (product['image_url'] != null) {
            imageUrl = product['image_url']
                .toString()
                .startsWith('http')
                ? product['image_url']
                : supabase.storage
                .from('product-images')
                .getPublicUrl(product['image_url']);
          }

          final finalPrice = getFinalPrice(
            product['price'],
            offer['discount_type'],
            offer['discount_value'],
          );

          return Card(
            margin: const EdgeInsets.all(10),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  // IMAGE (LEFT)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: imageUrl != null
                        ? Image.network(
                      imageUrl,
                      width: 90,
                      height: 90,
                      fit: BoxFit.cover,
                    )
                        : Container(
                      width: 90,
                      height: 90,
                      color: Colors.grey[300],
                      child: const Icon(Icons.image),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // DETAILS
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product['name'],
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "₹${product['price']} → ₹$finalPrice",
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "Farmer: $farmerName",
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          "Valid till: ${offer['end_date']}",
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(height: 8),

                        Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                          children: [
                            // QTY
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(
                                      Icons.remove_circle),
                                  onPressed: qty > 1
                                      ? () => setState(() {
                                    quantities[offer['id']] =
                                        qty - 1;
                                  })
                                      : null,
                                ),
                                Text(qty.toString()),
                                IconButton(
                                  icon:
                                  const Icon(Icons.add_circle),
                                  onPressed: () => setState(() {
                                    quantities[offer['id']] =
                                        qty + 1;
                                  }),
                                ),
                              ],
                            ),

                            // ADD
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                              ),
                              onPressed: () => addToCart(offer),
                              child: const Text("Add"),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

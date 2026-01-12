import 'package:farm_fresh_connect/customer/checkout_page.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final supabase = Supabase.instance.client;

  List cartItems = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchCart();
  }

  // ================= FETCH CART =================
  Future<void> fetchCart() async {
    final userId = supabase.auth.currentUser!.id;

    final response = await supabase
        .from('cart')
        .select('''
          id,
          product_id,
          product_name,
          price,
          quantity,
          discount,
          final_price,
          products (
            id,
            image_url,
            farmer_id
          )
        ''')
        .eq('customer_id', userId);

    setState(() {
      cartItems = response;
      loading = false;
    });
  }

  // ================= DELETE ITEM =================
  Future<void> removeItem(String cartId) async {
    await supabase.from('cart').delete().eq('id', cartId);
    await fetchCart();
  }

  // ================= TOTAL =================
  int getTotal() {
    int total = 0;
    for (var item in cartItems) {
      total +=
          (item['final_price'] as num).toInt() *
              (item['quantity'] as num).toInt();
    }
    return total;
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Cart"),
        backgroundColor: Colors.green,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : cartItems.isEmpty
          ? const Center(child: Text("Cart is empty"))
          : Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: cartItems.length,
              itemBuilder: (context, index) {
                final item = cartItems[index];

                // IMAGE
                String? imageUrl;
                final imagePath =
                item['products']?['image_url'];

                if (imagePath != null &&
                    imagePath.toString().isNotEmpty) {
                  imageUrl = imagePath.startsWith('http')
                      ? imagePath
                      : supabase.storage
                      .from('product-images')
                      .getPublicUrl(imagePath);
                }

                return Card(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  child: ListTile(
                    leading: imageUrl != null
                        ? Image.network(
                      imageUrl,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    )
                        : const Icon(Icons.image),
                    title: Text(
                      item['product_name'],
                      style: const TextStyle(
                          fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      "₹${item['final_price']} × ${item['quantity']}",
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete,
                          color: Colors.red),
                      onPressed: () =>
                          removeItem(item['id']),
                    ),
                  ),
                );
              },
            ),
          ),

          // ================= FOOTER =================
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  "Total: ₹${getTotal()}",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CheckoutPage(
                            cartItems: cartItems,
                            total: getTotal(),
                          ),
                        ),
                      );
                    },
                    child: const Text("Checkout"),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

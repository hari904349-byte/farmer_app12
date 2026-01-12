import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReviewOrderPage extends StatelessWidget {
  final List cartItems;

  const ReviewOrderPage({
    super.key,
    required this.cartItems,
  });

  int getSubTotal() {
    int total = 0;
    for (var item in cartItems) {
      total +=
          (item['price'] as num).toInt() *
              (item['quantity'] as num).toInt();
    }
    return total;
  }

  int getDiscount() {
    int discount = 0;
    for (var item in cartItems) {
      discount +=
          (item['discount'] as num).toInt() *
              (item['quantity'] as num).toInt();
    }
    return discount;
  }

  int getPayable() => getSubTotal() - getDiscount();

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;

    return Scaffold(
      appBar: AppBar(
        title: const Text("REVIEW YOUR ORDER"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: ListView(
        children: [
          // ================= STEP INDICATOR =================
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: const [
                CircleAvatar(radius: 12, child: Text("1")),
                SizedBox(width: 8),
                Text("Review"),
                Expanded(child: Divider()),
                CircleAvatar(
                  radius: 12,
                  backgroundColor: Colors.grey,
                  child: Text("2"),
                ),
                SizedBox(width: 8),
                Text("Payment", style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),

          // ================= OFFER BANNER =================
          Container(
            padding: const EdgeInsets.all(14),
            color: Colors.green.shade50,
            child: Text(
              "₹${getDiscount()} OFF on this order",
              style: const TextStyle(
                color: Colors.green,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // ================= PRODUCTS =================
          ...cartItems.map((item) {
            final product = item['products'];
            String? imageUrl;

            if (product['image_url'] != null) {
              imageUrl = product['image_url'].toString().startsWith('http')
                  ? product['image_url']
                  : supabase.storage
                  .from('product-images')
                  .getPublicUrl(product['image_url']);
            }

            final original =
                (item['price'] as num).toInt() *
                    (item['quantity'] as num).toInt();

            final finalPrice =
                (item['final_price'] as num).toInt() *
                    (item['quantity'] as num).toInt();

            return Card(
              margin: const EdgeInsets.all(10),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // IMAGE
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
                      ),
                    ),

                    const SizedBox(width: 12),

                    // DETAILS
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['product_name'],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "₹$finalPrice  ",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "₹$original",
                            style: const TextStyle(
                              decoration: TextDecoration.lineThrough,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            "Qty: ${item['quantity']}",
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Sold by: ${product['farmer_name'] ?? 'Farmer'}",
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),

          // ================= PRICE DETAILS =================
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                _priceRow("Subtotal", getSubTotal()),
                _priceRow("Discount", -getDiscount(), green: true),
                const Divider(),
                _priceRow(
                  "Total Payable",
                  getPayable(),
                  bold: true,
                ),
              ],
            ),
          ),

          // ================= CONTINUE BUTTON =================
          Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                ),
                onPressed: () {
                  // 👉 Navigate to payment page later
                },
                child: const Text(
                  "Continue",
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _priceRow(
      String label,
      int value, {
        bool bold = false,
        bool green = false,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              )),
          Text(
            "₹$value",
            style: TextStyle(
              fontSize: 15,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              color: green ? Colors.green : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}

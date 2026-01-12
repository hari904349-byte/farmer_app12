import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'order_review_page.dart'; // 👈 NEW PAGE

class CheckoutPage extends StatefulWidget {
  final List cartItems;

  const CheckoutPage({
    super.key,
    required this.cartItems, required int total,
  });

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final supabase = Supabase.instance.client;

  // ================= PRICE CALCULATIONS =================

  int itemMRP(Map item) {
    return (item['price'] as num).toInt() *
        (item['quantity'] as num).toInt();
  }

  int itemFinal(Map item) {
    return (item['final_price'] as num).toInt() *
        (item['quantity'] as num).toInt();
  }

  int itemDiscount(Map item) {
    return itemMRP(item) - itemFinal(item);
  }

  int getSubTotal() {
    int total = 0;
    for (var item in widget.cartItems) {
      total += itemMRP(item);
    }
    return total;
  }

  int getTotalDiscount() {
    int total = 0;
    for (var item in widget.cartItems) {
      total += itemDiscount(item);
    }
    return total;
  }

  int getPayable() {
    return getSubTotal() - getTotalDiscount();
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Review Your Order"),
        backgroundColor: Colors.green,
      ),
      body: Column(
        children: [
          // ================= ITEM LIST =================
          Expanded(
            child: ListView.builder(
              itemCount: widget.cartItems.length,
              itemBuilder: (context, index) {
                final item = widget.cartItems[index];
                final product = item['products'];

                String? imageUrl;
                if (product?['image_url'] != null &&
                    product['image_url'].toString().isNotEmpty) {
                  imageUrl = product['image_url'].toString().startsWith('http')
                      ? product['image_url']
                      : supabase.storage
                      .from('product-images')
                      .getPublicUrl(product['image_url']);
                }

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
                                item['product_name'],
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "₹${item['price']} × ${item['quantity']}",
                                style: const TextStyle(color: Colors.grey),
                              ),
                              if (itemDiscount(item) > 0)
                                Text(
                                  "Discount: -₹${itemDiscount(item)}",
                                  style: const TextStyle(color: Colors.red),
                                ),
                              const SizedBox(height: 4),
                              Text(
                                "Line Total: ₹${itemFinal(item)}",
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
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
          ),

          // ================= PRICE SUMMARY =================
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: Column(
              children: [
                _row("Subtotal", getSubTotal()),
                _row("Discount", -getTotalDiscount(), green: true),
                const Divider(),
                _row("Total Payable", getPayable(), bold: true),
                const SizedBox(height: 12),

                // 🔥 IMPORTANT BUTTON
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    onPressed: () {
                      // ✅ NAVIGATE TO AMAZON-STYLE REVIEW / PAYMENT PAGE
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OrderReviewPage(
                            cartItems: widget.cartItems,
                            subtotal: getSubTotal(),
                            discount: getTotalDiscount(),
                            total: getPayable(),
                          ),
                        ),
                      );
                    },
                    child: const Text(
                      "Place Order",
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(
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
          Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
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

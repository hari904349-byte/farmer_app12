import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'order_success_page.dart';

class PaymentPage extends StatefulWidget {
  final List cartItems;
  final int subtotal;
  final int discount;
  final int total;
  final Map<String, dynamic> address;

  const PaymentPage({
    super.key,
    required this.cartItems,
    required this.subtotal,
    required this.discount,
    required this.total,
    required this.address,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final supabase = Supabase.instance.client;

  String paymentMethod = "COD";
  bool placingOrder = false;

  Future<void> placeOrder() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    if (widget.cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cart is empty")),
      );
      return;
    }

    setState(() => placingOrder = true);

    try {
      // ================= STEP 1: SAFELY GET FARMER ID =================
      final firstItem = widget.cartItems.first;

      final product = firstItem['products'];
      if (product == null || product['farmer_id'] == null) {
        throw Exception("Farmer ID not found in cart items");
      }

      final farmerId = product['farmer_id'];

      // ================= STEP 2: INSERT ORDER =================
      final order = await supabase
          .from('orders')
          .insert({
        'customer_id': user.id,
        'farmer_id': farmerId,
        'address_id': widget.address['id'],
        'delivery_address':
        "${widget.address['address']}, ${widget.address['city']} - ${widget.address['pincode']}",
        'total_amount': widget.total,
        'payment_method': paymentMethod,
        'status': 'Placed', // MUST match farmer_orders.dart
      })
          .select()
          .single();

      final orderId = order['id'];

      // ================= STEP 3: INSERT ORDER ITEMS =================
      for (final item in widget.cartItems) {
        await supabase.from('order_items').insert({
          'order_id': orderId,
          'product_id': item['product_id'],
          'quantity': item['quantity'],
          'price': item['price'],
        });
      }

      // ================= STEP 4: CLEAR CART =================
      await supabase
          .from('cart')
          .delete()
          .eq('customer_id', user.id);

      // ================= STEP 5: SUCCESS PAGE =================
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const OrderSuccessPage(),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Order failed: $e")),
      );
    } finally {
      setState(() => placingOrder = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Payment Method"),
        backgroundColor: Colors.green,
      ),
      body: Column(
        children: [
          RadioListTile(
            value: "COD",
            groupValue: paymentMethod,
            title: const Text("Cash on Delivery"),
            onChanged: (v) => setState(() => paymentMethod = v!),
          ),
          const RadioListTile(
            value: "ONLINE",
            groupValue: "COD",
            title: Text("Pay Online (Coming Soon)"),
            onChanged: null,
          ),

          const Divider(),

          ListTile(
            title: const Text("Subtotal"),
            trailing: Text("₹${widget.subtotal}"),
          ),
          ListTile(
            title: const Text("Discount"),
            trailing: Text(
              "-₹${widget.discount}",
              style: const TextStyle(color: Colors.green),
            ),
          ),
          ListTile(
            title: const Text(
              "Order Total",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            trailing: Text(
              "₹${widget.total}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),

          const Spacer(),

          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
                onPressed: placingOrder ? null : placeOrder,
                child: placingOrder
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Place Order"),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

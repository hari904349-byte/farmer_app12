import 'dart:math';
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
  String deliveryOption = "direct"; // direct | delivery_partner
  bool placingOrder = false;

  // ================= PLACE ORDER =================
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
      // ================= GET FARMER ID (✅ FIXED) =================
      final firstItem = widget.cartItems.first;
      final productId = firstItem['product_id'];

      final productData = await supabase
          .from('products')
          .select('farmer_id')
          .eq('id', productId)
          .single();

      final String farmerId = productData['farmer_id'];

      if (farmerId.isEmpty) {
        throw Exception("Farmer not found for this product");
      }

      // ================= OTP GENERATION =================
      final String? pickupOtp = deliveryOption == 'direct'
          ? (1000 + Random().nextInt(9000)).toString()
          : null;

      final String? deliveryOtp = deliveryOption == 'delivery_partner'
          ? (1000 + Random().nextInt(9000)).toString()
          : null;

      // ================= INSERT ORDER =================
      final order = await supabase.from('orders').insert({
        'customer_id': user.id,
        'farmer_id': farmerId, // ✅ NOW ALWAYS SAVED
        'delivery_type': deliveryOption,
        'status': deliveryOption == 'direct'
            ? 'Placed'
            : 'Searching Delivery Partner',
        'pickup_otp': pickupOtp,
        'delivery_otp': deliveryOtp,
        'payment_method': paymentMethod,
        'total_amount': widget.total,
        'delivery_address':
        "${widget.address['address']}, ${widget.address['city']} - ${widget.address['pincode']}",
      }).select().single();

      final orderId = order['id'];

      // ================= INSERT ORDER ITEMS =================
      for (final item in widget.cartItems) {
        await supabase.from('order_items').insert({
          'order_id': orderId,
          'product_id': item['product_id'],
          'quantity': item['quantity'],
          'price': item['price'],
        });
      }

      // ================= CLEAR CART =================
      await supabase
          .from('cart')
          .delete()
          .eq('customer_id', user.id);

      if (!mounted) return;

      // ================= SUCCESS =================
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

  // ================= UI =================
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

          const Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              "How do you want to receive your order?",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),

          RadioListTile(
            value: "direct",
            groupValue: deliveryOption,
            title: const Text("Get directly from Farmer"),
            onChanged: (v) => setState(() => deliveryOption = v!),
          ),
          RadioListTile(
            value: "delivery_partner",
            groupValue: deliveryOption,
            title: const Text("Use Delivery Partner"),
            onChanged: (v) => setState(() => deliveryOption = v!),
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

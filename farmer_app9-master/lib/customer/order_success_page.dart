import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'customer_home.dart';
import 'product_list.dart';

class OrderSuccessPage extends StatefulWidget {
  const OrderSuccessPage({super.key});

  @override
  State<OrderSuccessPage> createState() => _OrderSuccessPageState();
}

class _OrderSuccessPageState extends State<OrderSuccessPage> {
  final supabase = Supabase.instance.client;
  bool clearingCart = true;

  @override
  void initState() {
    super.initState();
    _clearCart();
  }

  // ================= CLEAR CUSTOMER CART =================
  Future<void> _clearCart() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      await supabase
          .from('cart')
          .delete()
          .eq('customer_id', user.id);
    } catch (e) {
      debugPrint("Cart clear error: $e");
    } finally {
      setState(() => clearingCart = false);
    }
  }

  // ================= NAVIGATION =================

  // 🏠 GO TO HOME → clears stack (NO back arrow)
  void _goToHome() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const CustomerHome()),
          (route) => false,
    );
  }

  // 🛒 CONTINUE SHOPPING → keeps back arrow
  void _continueShopping() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const ProductListPage()),
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: clearingCart
            ? const CircularProgressIndicator(color: Colors.green)
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle,
              size: 100,
              color: Colors.green,
            ),

            const SizedBox(height: 20),

            const Text(
              "Order Placed Successfully!",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              "Your order will be delivered soon.",
              style: TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 40),

            // 🛒 CONTINUE SHOPPING
            SizedBox(
              width: 220,
              child: OutlinedButton(
                onPressed: _continueShopping,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.green),
                ),
                child: const Text(
                  "Continue Shopping",
                  style: TextStyle(color: Colors.green),
                ),
              ),
            ),

            const SizedBox(height: 15),

            // 🏠 GO TO HOME
            SizedBox(
              width: 220,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding:
                  const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: _goToHome,
                child: const Text("Go to Home"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

            const SizedBox(height: 30),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 12,
                ),
              ),
              onPressed: () {
                Navigator.popUntil(
                  context,
                      (route) => route.isFirst,
                );
              },
              child: const Text("Go to Home"),
            ),
          ],
        ),
      ),
    );
  }
}

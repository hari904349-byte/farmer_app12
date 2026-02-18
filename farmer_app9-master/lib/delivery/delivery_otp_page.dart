import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DeliveryOtpPage extends StatefulWidget {
  final String orderId;

  const DeliveryOtpPage({
    super.key,
    required this.orderId,
  });

  @override
  State<DeliveryOtpPage> createState() => _DeliveryOtpPageState();
}

class _DeliveryOtpPageState extends State<DeliveryOtpPage> {
  final SupabaseClient supabase = Supabase.instance.client;
  final TextEditingController otpController = TextEditingController();

  bool verifying = false;

  // ================= VERIFY DELIVERY OTP =================
  Future<void> verifyOtp() async {
    final enteredOtp = otpController.text.trim();

    if (enteredOtp.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter OTP")),
      );
      return;
    }

    setState(() => verifying = true);

    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw "Not authenticated";

      // 🔹 1. FETCH ORDER DETAILS
      final order = await supabase
          .from('orders')
          .select('delivery_otp, delivery_partner_id, status')
          .eq('id', widget.orderId)
          .single();

      // 🔐 SECURITY CHECK
      if (order['delivery_partner_id'] != user.id) {
        throw "You are not assigned to this order";
      }

      if (order['delivery_otp'] == null) {
        throw "Delivery OTP not generated";
      }

      // 🔹 2. VERIFY OTP
      if (enteredOtp != order['delivery_otp']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Invalid OTP"),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => verifying = false);
        return;
      }

      // 🔹 3. MARK ORDER AS DELIVERED
      await supabase.from('orders').update({
        'status': 'Delivered',
        'delivered_at': DateTime.now().toIso8601String(),
      }).eq('id', widget.orderId);

      // 🔥 Reduce product stock after delivery
      final orderItems = await supabase
          .from('order_items')
          .select('product_id, quantity')
          .eq('order_id', widget.orderId);

      for (var item in orderItems) {
        await supabase.rpc('decrease_stock', params: {
          'p_id': item['product_id'],
          'qty': item['quantity'],
        });
      }


      // 🔹 4. SUCCESS
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Order delivered successfully ✅"),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      debugPrint("❌ Delivery OTP error: $e");

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => verifying = false);
    }
  }

  @override
  void dispose() {
    otpController.dispose();
    super.dispose();
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Verify Delivery OTP"),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Enter OTP from Customer",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: otpController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              decoration: const InputDecoration(
                labelText: "4-digit OTP",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
                onPressed: verifying ? null : verifyOtp,
                child: verifying
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Confirm Delivery"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

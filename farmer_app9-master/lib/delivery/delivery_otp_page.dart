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
  final supabase = Supabase.instance.client;
  final TextEditingController otpController = TextEditingController();

  bool verifying = false;

  // ================= VERIFY OTP =================

  Future<void> verifyOtp() async {
    if (otpController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter OTP")),
      );
      return;
    }

    setState(() => verifying = true);

    try {
      // 1️⃣ Fetch OTP from DB
      final order = await supabase
          .from('orders')
          .select('delivery_otp')
          .eq('id', widget.orderId)
          .single();

      final String dbOtp = order['delivery_otp'];

      // 2️⃣ Compare OTP
      if (otpController.text.trim() != dbOtp) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Invalid OTP")),
        );
        setState(() => verifying = false);
        return;
      }

      // 3️⃣ Mark order as delivered
      await supabase.from('orders').update({
        'status': 'Delivered',
        'delivered_at': DateTime.now().toIso8601String(),
      }).eq('id', widget.orderId);

      // 4️⃣ Success
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Order delivered successfully ✅")),
      );

      // Go back to Assigned Orders
      Navigator.pop(context);
    } catch (e) {
      debugPrint("OTP Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Something went wrong")),
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

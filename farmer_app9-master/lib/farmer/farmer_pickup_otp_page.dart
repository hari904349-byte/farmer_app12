import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FarmerPickupOtpPage extends StatefulWidget {
  final String orderId;
  final String correctOtp;

  const FarmerPickupOtpPage({
    super.key,
    required this.orderId,
    required this.correctOtp,
  });

  @override
  State<FarmerPickupOtpPage> createState() => _FarmerPickupOtpPageState();
}

class _FarmerPickupOtpPageState extends State<FarmerPickupOtpPage> {
  final supabase = Supabase.instance.client;
  final TextEditingController otpController = TextEditingController();

  bool verifying = false;

  // ================= VERIFY OTP & MARK DELIVERED =================
  Future<void> verifyOtp() async {
    final enteredOtp = otpController.text.trim();

    if (enteredOtp.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter 4-digit OTP")),
      );
      return;
    }

    if (enteredOtp != widget.correctOtp) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid OTP")),
      );
      return;
    }

    setState(() => verifying = true);

    try {
      // ✅ FINAL STEP: MARK ORDER AS DELIVERED
      await supabase.from('orders').update({
        'status': 'Delivered',
        'delivered_at': DateTime.now().toIso8601String(),
      }).eq('id', widget.orderId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Order delivered successfully ✅")),
      );

      // Go back to Farmer Orders page
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      if (mounted) {
        setState(() => verifying = false);
      }
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
        title: const Text("Verify Customer OTP"),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Enter OTP shown by Customer",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: otpController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
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
                onPressed: verifying ? null : verifyOtp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
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

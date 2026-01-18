import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DeliveryPickupOtpPage extends StatefulWidget {
  final String orderId;

  const DeliveryPickupOtpPage({super.key, required this.orderId});

  @override
  State<DeliveryPickupOtpPage> createState() => _DeliveryPickupOtpPageState();
}

class _DeliveryPickupOtpPageState extends State<DeliveryPickupOtpPage> {
  final supabase = Supabase.instance.client;
  final otpController = TextEditingController();
  bool verifying = false;

  Future<void> verifyPickupOtp() async {
    if (otpController.text.trim().length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter valid 4-digit OTP")),
      );
      return;
    }

    setState(() => verifying = true);

    try {
      final order = await supabase
          .from('orders')
          .select('pickup_otp')
          .eq('id', widget.orderId)
          .single();

      if (order['pickup_otp'] != otpController.text.trim()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Invalid Pickup OTP")),
        );
        setState(() => verifying = false);
        return;
      }

      // ✅ Mark as Out for Delivery
      await supabase.from('orders').update({
        'status': 'Out for Delivery',
      }).eq('id', widget.orderId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pickup verified ✅")),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pickup OTP verification failed")),
      );
    } finally {
      setState(() => verifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Verify Pickup OTP"),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Enter OTP from Farmer",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: otpController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              decoration: const InputDecoration(
                labelText: "Pickup OTP",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: verifying ? null : verifyPickupOtp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
                child: verifying
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Confirm Pickup"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

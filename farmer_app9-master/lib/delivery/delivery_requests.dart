import 'dart:math';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DeliveryRequestsPage extends StatefulWidget {
  const DeliveryRequestsPage({super.key});

  @override
  State<DeliveryRequestsPage> createState() =>
      _DeliveryRequestsPageState();
}

class _DeliveryRequestsPageState extends State<DeliveryRequestsPage> {
  final SupabaseClient supabase = Supabase.instance.client;

  bool loading = true;
  List<Map<String, dynamic>> orders = [];

  @override
  void initState() {
    super.initState();
    fetchRequests();
  }

  // 🔐 SECURE RANDOM OTP GENERATOR
  String generateOtp() {
    final random = Random();
    return (1000 + random.nextInt(9000)).toString();
  }

  // ✅ FETCH OPEN DELIVERY REQUESTS
  Future<void> fetchRequests() async {
    try {
      final data = await supabase
          .from('orders')
          .select('''
            id,
            delivery_address,
            total_amount,
            profiles!orders_customer_id_fkey(name)
          ''')
          .eq('delivery_type', 'delivery_partner')
          .eq('status', 'Searching Delivery Partner')
          .filter('delivery_partner_id', 'is',null);

      if (!mounted) return;

      setState(() {
        orders = List<Map<String, dynamic>>.from(data);
        loading = false;
      });
    } catch (e) {
      debugPrint("❌ Fetch delivery requests error: $e");
      if (!mounted) return;
      setState(() => loading = false);
    }
  }

  // ✅ ACCEPT ORDER + GENERATE OTP
  Future<void> acceptOrder(String orderId) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final pickupOtp = generateOtp();
      final deliveryOtp = generateOtp();

      // 🔒 Only accept if still unassigned
      final response = await supabase
          .from('orders')
          .update({
        'delivery_partner_id': user.id,
        'status': 'Delivery Partner Assigned',
        'pickup_otp': pickupOtp,
        'delivery_otp': deliveryOtp,
      })
          .eq('id', orderId)
          .filter('delivery_partner_id', 'is',null)
          .select();

      if (response.isEmpty) {
        throw "Order already accepted by another delivery partner";
      }

      await fetchRequests();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              "Order accepted ✅\nPickup OTP: $pickupOtp"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Accept failed: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text("Delivery Requests"),
        backgroundColor: Colors.green,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : orders.isEmpty
          ? const Center(
        child: Text(
          "No delivery requests",
          style: TextStyle(fontSize: 16),
        ),
      )
          : RefreshIndicator(
        onRefresh: fetchRequests,
        child: ListView.builder(
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            final customerName =
                order['profiles']?['name'] ?? 'Customer';

            return Card(
              margin: const EdgeInsets.all(12),
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Customer: $customerName",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Address: ${order['delivery_address']}",
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Amount: ₹${order['total_amount']}",
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        onPressed: () =>
                            acceptOrder(order['id']),
                        child: const Text(
                            "Accept Delivery"),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

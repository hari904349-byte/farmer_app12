import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'delivery_otp_page.dart';
import 'delivery_pickup_otp_page.dart';

class AssignedOrdersPage extends StatefulWidget {
  const AssignedOrdersPage({super.key});

  @override
  State<AssignedOrdersPage> createState() => _AssignedOrdersPageState();
}

class _AssignedOrdersPageState extends State<AssignedOrdersPage> {
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> orders = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchAssignedOrders();
  }

  // ================= FETCH ASSIGNED ORDERS =================
  Future<void> fetchAssignedOrders() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final data = await supabase
          .from('orders')
          .select('''
            id,
            total_amount,
            status,
            delivery_address
          ''')
          .eq('delivery_partner_id', user.id)
          .order('created_at', ascending: false);

      if (!mounted) return;

      setState(() {
        orders = List<Map<String, dynamic>>.from(data);
        loading = false;
      });
    } catch (e) {
      debugPrint("❌ Error loading assigned orders: $e");
      if (!mounted) return;
      setState(() => loading = false);
    }
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Assigned Orders"),
        backgroundColor: Colors.green,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : orders.isEmpty
          ? const Center(child: Text("No assigned orders"))
          : RefreshIndicator(
        onRefresh: fetchAssignedOrders,
        child: ListView.builder(
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];

            return Card(
              margin: const EdgeInsets.all(12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // HEADER
                    Text(
                      "Order #${order['id'].toString().substring(0, 8)}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text("Amount: ₹${order['total_amount']}"),
                    Text("Status: ${order['status']}"),
                    Text("Address: ${order['delivery_address']}"),

                    const SizedBox(height: 14),

                    // 🔴 VERIFY PICKUP OTP (FARMER)
                    if (order['status'] ==
                        'Delivery Partner Assigned')
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    DeliveryPickupOtpPage(
                                      orderId: order['id'],
                                    ),
                              ),
                            ).then((_) => fetchAssignedOrders());
                          },
                          child: const Text(
                            "Verify Pickup OTP (From Farmer)",
                          ),
                        ),
                      ),

                    // 🔵 DELIVER ORDER (CUSTOMER OTP)
                    if (order['status'] == 'Out for Delivery')
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DeliveryOtpPage(
                                  orderId: order['id'],
                                ),
                              ),
                            ).then((_) => fetchAssignedOrders());
                          },
                          child: const Text(
                            "Deliver Order (Enter Customer OTP)",
                          ),
                        ),
                      ),

                    // ✅ DELIVERED
                    if (order['status'] == 'Delivered')
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          "✅ Order Delivered",
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
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

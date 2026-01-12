import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'delivery_otp_page.dart';

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

  // 🔹 FETCH ASSIGNED ORDERS FOR DELIVERY PARTNER
  Future<void> fetchAssignedOrders() async {
    try {
      final deliveryPartnerId =
          supabase.auth.currentUser!.id;

      final response = await supabase
          .from('orders')
          .select('''
            id,
            total_amount,
            status,
            delivery_address
          ''')
          .eq('delivery_partner_id', deliveryPartnerId)
          .eq('status', 'Out for Delivery')
          .order('created_at', ascending: false);

      setState(() {
        orders = List<Map<String, dynamic>>.from(response);
        loading = false;
      });
    } catch (e) {
      debugPrint("❌ Error loading assigned orders: $e");
      setState(() => loading = false);
    }
  }

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
          : ListView.builder(
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];

          return Card(
            margin: const EdgeInsets.all(12),
            child: ListTile(
              leading: const Icon(
                Icons.local_shipping,
                color: Colors.green,
              ),
              title: Text(
                "Order #${order['id'].toString().substring(0, 8)}",
                style: const TextStyle(
                    fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                      "Amount: ₹${order['total_amount']}"),
                  const SizedBox(height: 4),
                  Text(
                    "Address: ${order['delivery_address'] ?? 'N/A'}",
                  ),
                ],
              ),
              trailing: const Icon(
                  Icons.arrow_forward_ios,
                  size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DeliveryOtpPage(
                      orderId: order['id'],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

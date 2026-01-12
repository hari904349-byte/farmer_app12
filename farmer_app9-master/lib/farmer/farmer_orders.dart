import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FarmerOrders extends StatefulWidget {
  const FarmerOrders({super.key});

  @override
  State<FarmerOrders> createState() => _FarmerOrdersState();
}

class _FarmerOrdersState extends State<FarmerOrders> {
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> orders = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchOrders();
  }

  // 🔹 FETCH ORDERS FOR LOGGED-IN FARMER
  Future<void> fetchOrders() async {
    try {
      final farmerId = supabase.auth.currentUser!.id;

      final response = await supabase
          .from('orders')
          .select('''
            id,
            total_amount,
            status,
            created_at,
            order_items (
              quantity,
              price,
              products (
                name
              )
            )
          ''')
          .eq('farmer_id', farmerId)
          .order('created_at', ascending: false);

      setState(() {
        orders = List<Map<String, dynamic>>.from(response);
        loading = false;
      });
    } catch (e) {
      debugPrint("❌ Error fetching farmer orders: $e");
      setState(() => loading = false);
    }
  }

  // 🔹 UPDATE ORDER STATUS
  Future<void> updateStatus(String orderId, String status) async {
    try {
      await supabase
          .from('orders')
          .update({'status': status})
          .eq('id', orderId);

      fetchOrders();
    } catch (e) {
      debugPrint("❌ Status update error: $e");
    }
  }

  // 🔹 STATUS COLOR
  Color statusColor(String status) {
    switch (status) {
      case 'Accepted':
        return Colors.blue;
      case 'Delivered':
        return Colors.green;
      case 'Rejected':
        return Colors.red;
      default: // Placed
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Received Orders"),
        backgroundColor: Colors.green,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : orders.isEmpty
          ? const Center(child: Text("No orders received"))
          : ListView.builder(
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          final List items =
          (order['order_items'] ?? []) as List;

          return Card(
            margin: const EdgeInsets.all(12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🔹 HEADER
                  Row(
                    mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Order ID: ${order['id'].toString().substring(0, 8)}",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold),
                      ),
                      Chip(
                        label: Text(order['status']),
                        backgroundColor:
                        statusColor(order['status']),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // 🔹 ITEMS
                  Column(
                    children: items.map((item) {
                      return Row(
                        mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            item['products']?['name'] ?? '',
                            style:
                            const TextStyle(fontSize: 14),
                          ),
                          Text(
                            "${item['quantity']} × ₹${item['price']}",
                          ),
                        ],
                      );
                    }).toList(),
                  ),

                  const Divider(),

                  Text(
                    "Total: ₹${order['total_amount']}",
                    style: const TextStyle(
                        fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 10),

                  // 🔹 ACTIONS
                  if (order['status'] == 'Placed')
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => updateStatus(
                                order['id'], 'Accepted'),
                            style:
                            ElevatedButton.styleFrom(
                              backgroundColor:
                              Colors.green,
                            ),
                            child: const Text("Accept"),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => updateStatus(
                                order['id'], 'Rejected'),
                            style:
                            ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            child: const Text("Reject"),
                          ),
                        ),
                      ],
                    ),

                  if (order['status'] == 'Accepted')
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        "Waiting for delivery assignment",
                        style: TextStyle(
                          color: Colors.blueGrey,
                          fontSize: 13,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

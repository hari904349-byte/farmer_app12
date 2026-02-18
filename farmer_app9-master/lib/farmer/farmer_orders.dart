import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'farmer_pickup_otp_page.dart';

class FarmerOrders extends StatefulWidget {
  const FarmerOrders({super.key});

  @override
  State<FarmerOrders> createState() => _FarmerOrdersState();
}

class _FarmerOrdersState extends State<FarmerOrders>
    with SingleTickerProviderStateMixin {
  final supabase = Supabase.instance.client;

  late TabController _tabController;

  List<Map<String, dynamic>> directOrders = [];
  List<Map<String, dynamic>> deliveryOrders = [];

  bool loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    fetchOrders();
  }

  // ================= FETCH FARMER ORDERS =================
  Future<void> fetchOrders() async {
    try {
      final farmerId = supabase.auth.currentUser!.id;

      final data = await supabase
          .from('orders')
          .select('''
            id,
            total_amount,
            status,
            delivery_type,
            pickup_otp,
            order_items (
              quantity,
              price,
              products ( name )
            )
          ''')
          .eq('farmer_id', farmerId)
          .order('created_at', ascending: false);

      if (!mounted) return;

      setState(() {
        directOrders = data.where((o) =>
        o['delivery_type'] == 'direct_farmer' ||
            o['delivery_type'] == 'direct'
        ).cast<Map<String, dynamic>>().toList();

        deliveryOrders = data
            .where((o) => o['delivery_type'] == 'delivery_partner')
            .cast<Map<String, dynamic>>()
            .toList();

        loading = false;
      });
    } catch (e) {
      debugPrint("❌ Farmer order fetch error: $e");
      setState(() => loading = false);
    }
  }

  // ================= UPDATE STATUS =================
  Future<void> updateStatus(String orderId, String status) async {
    await supabase.from('orders').update({
      'status': status,
    }).eq('id', orderId);

    fetchOrders();
  }

  // ================= STATUS COLOR =================
  Color statusColor(String status) {
    switch (status) {
      case 'Placed':
        return Colors.orange;
      case 'Accepted':
        return Colors.blue;
      case 'Ready for Pickup':
        return Colors.deepPurple;
      case 'Delivery Partner Assigned':
        return Colors.grey;
      case 'Delivered':
        return Colors.green;
      case 'Rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // ================= ORDER CARD =================
  Widget orderCard(Map<String, dynamic> order, bool isDirect) {
    final items = (order['order_items'] ?? []) as List;

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
            // HEADER
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Order #${order['id'].toString().substring(0, 8)}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Chip(
                  label: Text(
                    order['status'],
                    style: const TextStyle(color: Colors.white),
                  ),
                  backgroundColor: statusColor(order['status']),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // ITEMS
            Column(
              children: items.map((item) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(item['products']?['name'] ?? ''),
                    Text("${item['quantity']} × ₹${item['price']}"),
                  ],
                );
              }).toList(),
            ),

            const Divider(),

            Text(
              "Total: ₹${order['total_amount']}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),

            // ================= DIRECT FARMER FLOW =================

            if (isDirect && order['status'] == 'Placed')
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        await updateStatus(order['id'], 'Ready for Pickup');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      child: const Text("Accept"),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        await updateStatus(order['id'], 'Rejected');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: const Text("Reject"),
                    ),
                  ),
                ],
              ),

            if (isDirect &&
                order['status'] == 'Ready for Pickup' &&
                order['pickup_otp'] != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FarmerPickupOtpPage(
                            orderId: order['id'],
                            correctOtp: order['pickup_otp'],
                          ),
                        ),
                      );
                      fetchOrders();
                    },
                    child: const Text("Verify Customer OTP"),
                  ),
                ),
              ),

            // ================= DELIVERY PARTNER OTP DISPLAY =================

            if (!isDirect &&
                order['status'] == 'Delivery Partner Assigned' &&
                order['pickup_otp'] != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Pickup OTP for Delivery Partner:",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        order['pickup_otp'].toString(),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            if (order['status'] == 'Delivered')
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  "Order completed successfully",
                  style: TextStyle(color: Colors.green),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Received Orders"),
        backgroundColor: Colors.green,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Direct Orders"),
            Tab(text: "Delivery Partner"),
          ],
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
        controller: _tabController,
        children: [
          directOrders.isEmpty
              ? const Center(child: Text("No direct orders"))
              : ListView(
            children:
            directOrders.map((o) => orderCard(o, true)).toList(),
          ),
          deliveryOrders.isEmpty
              ? const Center(child: Text("No delivery partner orders"))
              : ListView(
            children:
            deliveryOrders.map((o) => orderCard(o, false)).toList(),
          ),
        ],
      ),
    );
  }
}

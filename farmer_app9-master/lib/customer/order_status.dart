import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'order_details_page.dart';

class OrderStatusPage extends StatefulWidget {
  const OrderStatusPage({super.key});

  @override
  State<OrderStatusPage> createState() => _OrderStatusPageState();
}

class _OrderStatusPageState extends State<OrderStatusPage>
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
    fetchMyOrders();
  }

  // ================= FETCH CUSTOMER ORDERS =================
  Future<void> fetchMyOrders() async {
    try {
      final userId = supabase.auth.currentUser!.id;

      final data = await supabase
          .from('orders')
          .select('''
            id,
            status,
            total_amount,
            delivery_address,
            delivery_type,
            pickup_otp,
            delivery_otp,
            created_at,
            order_items (
              quantity,
              price,
              products (
                name,
                image_url
              )
            )
          ''')
          .eq('customer_id', userId)
          .order('created_at', ascending: false);

      if (!mounted) return;

      setState(() {
        directOrders = data
            .where((o) => o['delivery_type'] == 'direct')
            .cast<Map<String, dynamic>>()
            .toList();

        deliveryOrders = data
            .where((o) => o['delivery_type'] == 'delivery_partner')
            .cast<Map<String, dynamic>>()
            .toList();

        loading = false;
      });
    } catch (e) {
      debugPrint("Order fetch error: $e");
      setState(() => loading = false);
    }
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
      case 'Out for Delivery':
        return Colors.purple;
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
    final firstProduct = items.isNotEmpty ? items[0]['products'] : null;

    String? imageUrl;
    final imagePath = firstProduct?['image_url'];
    if (imagePath != null && imagePath.toString().isNotEmpty) {
      imageUrl = imagePath.startsWith('http')
          ? imagePath
          : supabase.storage.from('product-images').getPublicUrl(imagePath);
    }

    return Card(
      margin: const EdgeInsets.all(12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: imageUrl != null
                  ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  imageUrl,
                  width: 55,
                  height: 55,
                  fit: BoxFit.cover,
                ),
              )
                  : const Icon(Icons.shopping_bag,
                  color: Colors.green, size: 40),
              title: Text(
                "Order #${order['id'].toString().substring(0, 8)}",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                "₹${order['total_amount']}\n${order['delivery_address']}",
              ),
              trailing: Chip(
                label: Text(order['status']),
                backgroundColor: statusColor(order['status']),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => OrderDetailsPage(
                      orderId: order['id'].toString(),
                    ),

                  ),
                );
              },
            ),

            // ===== DIRECT BUY OTP =====
            if (isDirect &&
                order['status'] == 'Ready for Pickup' &&
                order['pickup_otp'] != null)
              otpBox(
                title: "Pickup OTP (Show to Farmer)",
                otp: order['pickup_otp'],
                color: Colors.deepPurple,
              ),

            // ===== DELIVERY PARTNER OTP =====
            if (!isDirect &&
                order['status'] == 'Out for Delivery' &&
                order['delivery_otp'] != null)
              otpBox(
                title: "Delivery OTP (Share with Delivery Partner)",
                otp: order['delivery_otp'],
                color: Colors.green,
              ),
          ],
        ),
      ),
    );
  }

  Widget otpBox({
    required String title,
    required String otp,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            otp,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Orders"),
        backgroundColor: Colors.green,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Direct Buy"),
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
            children: directOrders
                .map((o) => orderCard(o, true))
                .toList(),
          ),
          deliveryOrders.isEmpty
              ? const Center(child: Text("No delivery orders"))
              : ListView(
            children: deliveryOrders
                .map((o) => orderCard(o, false))
                .toList(),
          ),
        ],
      ),
    );
  }
}

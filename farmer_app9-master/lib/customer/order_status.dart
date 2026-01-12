import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'order_details_page.dart';

class OrderStatusPage extends StatefulWidget {
  const OrderStatusPage({super.key});

  @override
  State<OrderStatusPage> createState() => _OrderStatusPageState();
}

class _OrderStatusPageState extends State<OrderStatusPage> {
  final supabase = Supabase.instance.client;

  List orders = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchMyOrders();
  }

  // 🔹 FETCH CUSTOMER ORDERS
  Future<void> fetchMyOrders() async {
    try {
      final userId = supabase.auth.currentUser!.id;

      final response = await supabase
          .from('orders')
          .select('''
            id,
            status,
            total_amount,
            delivery_address,
            created_at,
            farmer_id,
            delivery_partner_id,
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

      setState(() {
        orders = response;
        loading = false;
      });
    } catch (e) {
      debugPrint("Order fetch error: $e");
      setState(() => loading = false);
    }
  }

  // 🔹 STATUS COLOR
  Color statusColor(String status) {
    switch (status) {
      case 'Placed':
        return Colors.orange;
      case 'Accepted':
        return Colors.blue;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Orders"),
        backgroundColor: Colors.green,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : orders.isEmpty
          ? const Center(child: Text("No orders found"))
          : ListView.builder(
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          final items = (order['order_items'] ?? []) as List;

          // 🔹 FIRST PRODUCT INFO
          final firstProduct =
          items.isNotEmpty ? items[0]['products'] : null;

          final String productName =
              firstProduct?['name'] ?? 'Product';

          // 🔹 IMAGE HANDLING
          String? imageUrl;
          final imagePath = firstProduct?['image_url'];

          if (imagePath != null &&
              imagePath.toString().isNotEmpty) {
            imageUrl = imagePath.startsWith('http')
                ? imagePath
                : supabase.storage
                .from('product-images')
                .getPublicUrl(imagePath);
          }

          return Card(
            margin: const EdgeInsets.all(12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              // ✅ PRODUCT IMAGE
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
                  : const Icon(
                Icons.shopping_bag,
                color: Colors.green,
                size: 40,
              ),

              title: Text(
                "Order #${order['id'].toString().substring(0, 8)}",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),

              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(productName),
                  const SizedBox(height: 4),
                  Text(
                    "Total: ₹${order['total_amount']}",
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    order['delivery_address'] ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),

              trailing: Chip(
                label: Text(order['status']),
                backgroundColor:
                statusColor(order['status']),
              ),

              // ✅ OPEN FULL ORDER DETAILS (FIXED)
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        OrderDetailsPage(order: order),
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

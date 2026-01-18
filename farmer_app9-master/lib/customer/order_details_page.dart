import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'invoice_service.dart';
import 'rate_farmer_page.dart';

class OrderDetailsPage extends StatefulWidget {
  final String orderId;

  const OrderDetailsPage({
    super.key,
    required this.orderId,
  });

  @override
  State<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  final supabase = Supabase.instance.client;

  Map<String, dynamic>? order;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  // ================= FETCH LATEST ORDER =================
  Future<void> _loadOrder() async {
    final data = await supabase
        .from('orders')
        .select('''
          *,
          order_items (
            quantity,
            price,
            products ( name, image_url )
          )
        ''')
        .eq('id', widget.orderId)
        .single();

    setState(() {
      order = data;
      loading = false;
    });
  }

  // ================= STATUS COLOR =================
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
      case 'Cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // ================= FARMER =================
  Future<Map<String, dynamic>?> _getFarmer(String? farmerId) async {
    if (farmerId == null) return null;

    return await supabase
        .from('profiles')
        .select('name, mobile')
        .eq('id', farmerId)
        .maybeSingle();
  }

  // ================= DELIVERY PARTNER =================
  Future<Map<String, dynamic>?> _getDeliveryPartner(String? partnerId) async {
    if (partnerId == null) return null;

    return await supabase
        .from('profiles')
        .select('name, mobile')
        .eq('id', partnerId)
        .maybeSingle();
  }

  // ================= ORDER TRACKING =================
  Widget orderTimeline({
    required String status,
    required bool isDirect,
  }) {
    final steps = isDirect
        ? ['Placed', 'Accepted', 'Delivered']
        : ['Placed', 'Accepted', 'Out for Delivery', 'Delivered'];

    int currentStep = steps.indexOf(status);
    if (currentStep < 0) currentStep = 0;

    return Column(
      children: List.generate(steps.length, (index) {
        final isCompleted = index <= currentStep;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Icon(
                  isCompleted
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: isCompleted ? Colors.green : Colors.grey,
                  size: 22,
                ),
                if (index != steps.length - 1)
                  Container(
                    width: 2,
                    height: 32,
                    color: isCompleted ? Colors.green : Colors.grey,
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                steps[index],
                style: TextStyle(
                  fontWeight:
                  isCompleted ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (order == null) {
      return const Scaffold(
        body: Center(child: Text("Order not found")),
      );
    }

    final items = (order!['order_items'] ?? []) as List;
    final product =
    items.isNotEmpty ? items.first['products'] : null;

    final bool isDirect = order!['delivery_type'] == 'direct';

    String? imageUrl;
    final imagePath = product?['image_url'];
    if (imagePath != null && imagePath.toString().isNotEmpty) {
      imageUrl = imagePath.startsWith('http')
          ? imagePath
          : supabase.storage
          .from('product-images')
          .getPublicUrl(imagePath);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Order Details"),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ================= PRODUCT =================
            Card(
              elevation: 2,
              child: ListTile(
                leading: imageUrl != null
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.network(
                    imageUrl,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                  ),
                )
                    : const Icon(Icons.shopping_bag, size: 40),
                title: Text(product?['name'] ?? 'Product'),
                subtitle: Text("₹${order!['total_amount']}"),
                trailing: Chip(
                  label: Text(
                    order!['status'],
                    style: const TextStyle(color: Colors.white),
                  ),
                  backgroundColor: statusColor(order!['status']),
                ),
              ),
            ),

            const SizedBox(height: 20),

            const Text("Order Tracking",
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            orderTimeline(
              status: order!['status'],
              isDirect: isDirect,
            ),

            const Divider(height: 30),

            const Text("Shipping Details",
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(order!['delivery_address'] ?? '—'),
            Text("Payment Method: ${order!['payment_method'] ?? 'COD'}"),

            const Divider(height: 30),

            // ================= FARMER DETAILS =================
            const Text("Farmer Details",
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            FutureBuilder<Map<String, dynamic>?>(
              future: _getFarmer(order!['farmer_id']),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Text("Loading farmer details...");
                }
                if (!snapshot.hasData || snapshot.data == null) {
                  return const Text("Farmer information not available yet");
                }
                final farmer = snapshot.data!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Name: ${farmer['name']}"),
                    Text("Mobile: ${farmer['mobile']}"),
                  ],
                );
              },
            ),

            const Divider(height: 30),

            Text(
              "Grand Total: ₹${order!['total_amount']}",
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16),
            ),

            const SizedBox(height: 30),

            // ================= ACTIONS =================
            ElevatedButton.icon(
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text("Download Invoice"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: const Size.fromHeight(45),
              ),
              onPressed: () async {
                await InvoiceService.generateInvoice(order: order!);
              },
            ),

            const SizedBox(height: 10),

            ElevatedButton.icon(
              icon: const Icon(Icons.star),
              label: const Text("Rate Farmer"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: const Size.fromHeight(45),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RateFarmerPage(
                      farmerId: order!['farmer_id'],
                      orderId: order!['id'],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

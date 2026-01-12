import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'invoice_service.dart';

class OrderDetailsPage extends StatelessWidget {
  final Map<String, dynamic> order;

  const OrderDetailsPage({
    super.key,
    required this.order,
  });

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
      default:
        return Colors.grey;
    }
  }

  // ================= DELIVERY PARTNER =================
  Future<Map<String, dynamic>?> _getDeliveryPartner(
      String? partnerId) async {
    if (partnerId == null) return null;

    return await Supabase.instance.client
        .from('profiles')
        .select('name, mobile')
        .eq('id', partnerId)
        .maybeSingle();
  }

  // ================= TRACKING TIMELINE =================
  Widget orderTimeline(String status) {
    final steps = [
      'Placed',
      'Accepted',
      'Out for Delivery',
      'Delivered',
    ];

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
                    height: 35,
                    color:
                    isCompleted ? Colors.green : Colors.grey,
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
                  color:
                  isCompleted ? Colors.black : Colors.grey,
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
    final items = (order['order_items'] ?? []) as List;
    final product = items.isNotEmpty ? items[0]['products'] : null;

    // ================= PRODUCT IMAGE =================
    String? imageUrl;
    final imagePath = product?['image_url'];
    if (imagePath != null && imagePath.toString().isNotEmpty) {
      imageUrl = imagePath.startsWith('http')
          ? imagePath
          : Supabase.instance.client.storage
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
            // ================= PRODUCT CARD =================
            Card(
              child: ListTile(
                leading: imageUrl != null
                    ? Image.network(
                  imageUrl,
                  width: 60,
                  fit: BoxFit.cover,
                )
                    : const Icon(Icons.shopping_bag),
                title: Text(
                  product?['name'] ?? 'Product',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text("₹${order['total_amount']}"),
                trailing: Chip(
                  label: Text(order['status']),
                  backgroundColor:
                  statusColor(order['status']),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ================= ORDER TRACKING =================
            const Text(
              "Order Tracking",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            orderTimeline(order['status']),

            const Divider(height: 30),

            // ================= SHIPPING DETAILS =================
            const Text(
              "Shipping Details",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(order['delivery_address'] ?? ''),
            Text("Payment: Cash on Delivery"),

            const Divider(height: 30),

            // ================= DELIVERY PARTNER =================
            const Text(
              "Delivery Partner",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),

            FutureBuilder<Map<String, dynamic>?>(
              future:
              _getDeliveryPartner(order['delivery_partner_id']),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Text("Not assigned yet");
                }
                final partner = snapshot.data!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Name: ${partner['name']}"),
                    Text("Mobile: ${partner['mobile']}"),
                  ],
                );
              },
            ),

            const Divider(height: 30),

            // ================= TOTAL =================
            Text(
              "Grand Total: ₹${order['total_amount']}",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 30),

            // ================= ACTION BUTTONS =================
            ElevatedButton.icon(
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text("Download Invoice"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: const Size.fromHeight(45),
              ),
              onPressed: () async {
                await InvoiceService.generateInvoice(order: order);
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
              onPressed: () {},
            ),

            const SizedBox(height: 10),

            ElevatedButton.icon(
              icon: const Icon(Icons.delivery_dining),
              label: const Text("Rate Delivery Partner"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: const Size.fromHeight(45),
              ),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AssignDeliveryPage extends StatefulWidget {
  const AssignDeliveryPage({super.key});

  @override
  State<AssignDeliveryPage> createState() => _AssignDeliveryPageState();
}

class _AssignDeliveryPageState extends State<AssignDeliveryPage> {
  final supabase = Supabase.instance.client;

  bool loading = true;

  List<Map<String, dynamic>> orders = [];
  List<Map<String, dynamic>> deliveryPartners = [];

  Map<String, dynamic>? selectedOrder;
  Map<String, dynamic>? selectedPartner;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // ================= LOAD DATA =================
  Future<void> _loadData() async {
    try {
      // ✅ Load ACCEPTED orders that are NOT yet assigned
      final orderData = await supabase
          .from('orders')
          .select('id, total_amount, status, created_at')
          .eq('status', 'Accepted')
          .filter('delivery_partner_id', 'is', null) // ✅ FIX
          .order('created_at', ascending: false);

      // ✅ Load delivery partners
      final partnerData = await supabase
          .from('profiles')
          .select('id, name, mobile')
          .eq('role', 'delivery');

      setState(() {
        orders = List<Map<String, dynamic>>.from(orderData);
        deliveryPartners = List<Map<String, dynamic>>.from(partnerData);
        loading = false;
      });
    } catch (e) {
      debugPrint("Load error: $e");
      loading = false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load data: $e")),
      );
    }
  }

  // ================= ASSIGN DELIVERY =================
  Future<void> _assignDelivery() async {
    if (selectedOrder == null || selectedPartner == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Select order and delivery partner")),
      );
      return;
    }

    final otp = (1000 + Random().nextInt(9000)).toString();

    try {
      await supabase.from('orders').update({
        'delivery_partner_id': selectedPartner!['id'],
        'delivery_otp': otp,
        'status': 'Out for Delivery',
      }).eq('id', selectedOrder!['id']);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Delivery assigned successfully\nOTP: $otp"),
        ),
      );

      setState(() {
        selectedOrder = null;
        selectedPartner = null;
      });

      _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Assignment failed: $e")),
      );
    }
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Assign Delivery Partner"),
        backgroundColor: Colors.green,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Select Order",
              style:
              TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            DropdownButtonFormField<Map<String, dynamic>>(
              value: selectedOrder,
              hint: const Text("Choose Order"),
              items: orders.map((order) {
                return DropdownMenuItem(
                  value: order,
                  child: Text(
                    "Order ${order['id'].toString().substring(0, 8)} - ₹${order['total_amount']}",
                  ),
                );
              }).toList(),
              onChanged: (val) =>
                  setState(() => selectedOrder = val),
            ),

            const SizedBox(height: 20),

            const Text(
              "Select Delivery Partner",
              style:
              TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            DropdownButtonFormField<Map<String, dynamic>>(
              value: selectedPartner,
              hint: const Text("Choose Delivery Partner"),
              items: deliveryPartners.map((partner) {
                return DropdownMenuItem(
                  value: partner,
                  child: Text(
                    "${partner['name']} (${partner['mobile']})",
                  ),
                );
              }).toList(),
              onChanged: (val) =>
                  setState(() => selectedPartner = val),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
                onPressed: _assignDelivery,
                child: const Text("Assign Delivery"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

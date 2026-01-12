import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'payment_page.dart'; // ✅ STEP 2 PAGE

class OrderReviewPage extends StatefulWidget {
  final List cartItems;
  final int subtotal;
  final int discount;
  final int total;

  const OrderReviewPage({
    super.key,
    required this.cartItems,
    required this.subtotal,
    required this.discount,
    required this.total,
  });

  @override
  State<OrderReviewPage> createState() => _OrderReviewPageState();
}

class _OrderReviewPageState extends State<OrderReviewPage> {
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> addresses = [];
  Map<String, dynamic>? selectedAddress;

  bool loadingAddress = true;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  // ================= LOAD ADDRESSES =================
  Future<void> _loadAddresses() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final data = await supabase
        .from('addresses')
        .select()
        .eq('customer_id', user.id)
        .order('created_at', ascending: false);

    setState(() {
      addresses = List<Map<String, dynamic>>.from(data);
      selectedAddress = addresses.isNotEmpty ? addresses.first : null;
      loadingAddress = false;
    });
  }

  // ================= ADD ADDRESS =================
  void _addAddress() {
    final nameCtrl = TextEditingController();
    final mobileCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final cityCtrl = TextEditingController();
    final stateCtrl = TextEditingController();
    final pincodeCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Add Address"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Name")),
              TextField(controller: mobileCtrl, decoration: const InputDecoration(labelText: "Mobile")),
              TextField(controller: addressCtrl, decoration: const InputDecoration(labelText: "Address")),
              TextField(controller: cityCtrl, decoration: const InputDecoration(labelText: "City")),
              TextField(controller: stateCtrl, decoration: const InputDecoration(labelText: "State")),
              TextField(controller: pincodeCtrl, decoration: const InputDecoration(labelText: "Pincode")),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            child: const Text("Save"),
            onPressed: () async {
              final user = supabase.auth.currentUser;
              if (user == null) return;

              final res = await supabase.from('addresses').insert({
                'customer_id': user.id,
                'name': nameCtrl.text,
                'mobile': mobileCtrl.text,
                'address': addressCtrl.text,
                'city': cityCtrl.text,
                'state': stateCtrl.text,
                'pincode': pincodeCtrl.text,
              }).select().single();

              setState(() {
                addresses.insert(0, res);
                selectedAddress = res; // ✅ auto select
              });

              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  // ================= IMAGE =================
  String? getImageUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http')) return path;

    final fixedPath = path.startsWith('products/')
        ? path
        : 'products/$path';

    return supabase.storage
        .from('product-images')
        .getPublicUrl(fixedPath);
  }

  // ================= CHANGE ADDRESS =================
  void _changeAddress() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Select Address",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            ElevatedButton.icon(
              onPressed: _addAddress,
              icon: const Icon(Icons.add),
              label: const Text("Add Address"),
            ),

            const SizedBox(height: 10),

            ...addresses.map((addr) {
              final isSelected = selectedAddress?['id'] == addr['id'];
              return Card(
                color: isSelected ? Colors.green.shade50 : null,
                child: ListTile(
                  title: Text(addr['name']),
                  subtitle: Text(
                    "${addr['address']}, ${addr['city']} - ${addr['pincode']}\n${addr['mobile']}",
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : null,
                  onTap: () {
                    setState(() => selectedAddress = addr);
                    Navigator.pop(context);
                  },
                ),
              );
            }),
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
        title: const Text("REVIEW YOUR ORDER"),
        backgroundColor: Colors.green,
      ),
      body: loadingAddress
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          if (widget.discount > 0)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Colors.green.shade50,
              child: Text(
                "₹${widget.discount} OFF on this order",
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green),
              ),
            ),

          // PRODUCTS
          Expanded(
            child: ListView.builder(
              itemCount: widget.cartItems.length,
              itemBuilder: (context, i) {
                final item = widget.cartItems[i];
                final imageUrl =
                getImageUrl(item['products']?['image_url']);

                return ListTile(
                  leading: imageUrl != null
                      ? Image.network(imageUrl,
                      width: 60, height: 60, fit: BoxFit.cover)
                      : const Icon(Icons.image),
                  title: Text(item['product_name']),
                  subtitle:
                  Text("₹${item['price']} × ${item['quantity']}"),
                  trailing:
                  Text("₹${item['final_price']}"),
                );
              },
            ),
          ),

          // ADDRESS
          ListTile(
            leading: const Icon(Icons.location_on),
            title: const Text("Delivery Address"),
            subtitle: Text(
              selectedAddress == null
                  ? "No address selected"
                  : "${selectedAddress!['name']}\n${selectedAddress!['address']}, ${selectedAddress!['city']}",
            ),
            trailing: TextButton(
              onPressed: _changeAddress,
              child: const Text("Change"),
            ),
          ),

          // PRICE + CONTINUE
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _row("Subtotal", widget.subtotal),
                _row("Discount", -widget.discount, green: true),
                const Divider(),
                _row("Total Payable", widget.total, bold: true),
                const SizedBox(height: 10),

                // ✅ CONTINUE → PAYMENT PAGE
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green),
                    onPressed: () {
                      if (selectedAddress == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                "Please select a delivery address"),
                          ),
                        );
                        return;
                      }

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PaymentPage(
                            cartItems: widget.cartItems,
                            subtotal: widget.subtotal,
                            discount: widget.discount,
                            total: widget.total,
                            address: selectedAddress!,
                          ),
                        ),
                      );
                    },
                    child: const Text("Continue"),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, int value,
      {bool bold = false, bool green = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                fontWeight:
                bold ? FontWeight.bold : FontWeight.normal)),
        Text(
          "₹$value",
          style: TextStyle(
            fontWeight:
            bold ? FontWeight.bold : FontWeight.normal,
            color: green ? Colors.green : Colors.black,
          ),
        ),
      ],
    );
  }
}

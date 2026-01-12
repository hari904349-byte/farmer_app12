import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddOffer extends StatefulWidget {
  const AddOffer({super.key});

  @override
  State<AddOffer> createState() => _AddOfferState();
}

class _AddOfferState extends State<AddOffer> {
  final supabase = Supabase.instance.client;

  // Controllers
  final valueCtrl = TextEditingController();

  // State
  List products = [];
  String? selectedProductId;
  String discountType = "percentage";
  DateTime? startDate;
  DateTime? endDate;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    fetchMyProducts();
  }

  // ================= FETCH FARMER PRODUCTS =================
  Future<void> fetchMyProducts() async {
    final farmerId = supabase.auth.currentUser!.id;

    final response = await supabase
        .from('products')
        .select('id, name')
        .eq('farmer_id', farmerId);

    setState(() {
      products = response;
    });
  }

  // ================= DATE PICKER =================
  Future<void> pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      initialDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        isStart ? startDate = picked : endDate = picked;
      });
    }
  }

  // ================= SUBMIT OFFER =================
  Future<void> submitOffer() async {
    if (selectedProductId == null ||
        valueCtrl.text.isEmpty ||
        startDate == null ||
        endDate == null) {
      _show("All fields required");
      return;
    }

    try {
      setState(() => loading = true);

      await supabase.from('offers').insert({
        'farmer_id': supabase.auth.currentUser!.id,
        'product_id': selectedProductId,
        'discount_type': discountType,
        'discount_value': int.parse(valueCtrl.text),
        'start_date': startDate!.toIso8601String(),
        'end_date': endDate!.toIso8601String(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Offer added successfully ✅"),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      _show("Error: $e");
    } finally {
      setState(() => loading = false);
    }
  }

  void _show(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Offer"),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // PRODUCT DROPDOWN
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: "Select Product",
                border: OutlineInputBorder(),
              ),
              items: products.map<DropdownMenuItem<String>>((product) {
                return DropdownMenuItem(
                  value: product['id'],
                  child: Text(product['name']),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => selectedProductId = value);
              },
            ),

            const SizedBox(height: 16),

            // DISCOUNT TYPE
            DropdownButtonFormField(
              value: discountType,
              items: const [
                DropdownMenuItem(
                  value: "percentage",
                  child: Text("Percentage"),
                ),
                DropdownMenuItem(
                  value: "flat",
                  child: Text("Flat Amount"),
                ),
              ],
              onChanged: (v) => setState(() => discountType = v!),
              decoration: const InputDecoration(
                labelText: "Discount Type",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            // DISCOUNT VALUE
            TextField(
              controller: valueCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Discount Value",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            // DATE PICKERS
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => pickDate(true),
                    child: Text(
                      startDate == null
                          ? "Pick Start Date"
                          : startDate!.toString().split(" ")[0],
                    ),
                  ),
                ),
                Expanded(
                  child: TextButton(
                    onPressed: () => pickDate(false),
                    child: Text(
                      endDate == null
                          ? "Pick End Date"
                          : endDate!.toString().split(" ")[0],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // SAVE BUTTON
            SizedBox(
              width: double.infinity,
              height: 45,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
                onPressed: loading ? null : submitOffer,
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Save Offer"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

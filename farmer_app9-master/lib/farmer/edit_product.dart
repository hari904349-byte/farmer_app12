import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditProductPage extends StatefulWidget {
  final Map product;

  const EditProductPage({super.key, required this.product});

  @override
  State<EditProductPage> createState() => _EditProductPageState();
}

class _EditProductPageState extends State<EditProductPage> {
  final supabase = Supabase.instance.client;

  late TextEditingController nameCtrl;
  late TextEditingController priceCtrl;
  late TextEditingController stockCtrl;

  String priceUnit = '';
  String stockUnit = '';

  @override
  void initState() {
    super.initState();
    nameCtrl = TextEditingController(text: widget.product['name']);
    priceCtrl =
        TextEditingController(text: widget.product['price'].toString());
    stockCtrl =
        TextEditingController(text: widget.product['stock'].toString());

    priceUnit = widget.product['price_unit'];
    stockUnit = widget.product['stock_unit'];
  }

  Future<void> updateProduct() async {
    await supabase.from('products').update({
      'name': nameCtrl.text,
      'price': int.parse(priceCtrl.text),
      'stock': int.parse(stockCtrl.text),
      'price_unit': priceUnit,
      'stock_unit': stockUnit,
    }).eq('id', widget.product['id']);

    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Product"),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: "Product Name"),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: priceCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Price"),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: stockCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Stock"),
            ),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: updateProduct,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              child: const Text("Update Product"),
            )
          ],
        ),
      ),
    );
  }
}

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/foundation.dart';

class AddProduct extends StatefulWidget {
  const AddProduct({super.key});

  @override
  State<AddProduct> createState() => _AddProductState();
}

class _AddProductState extends State<AddProduct> {
  final supabase = Supabase.instance.client;

  // Controllers
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();

  // Units
  String priceUnit = 'Per Kg';
  String stockUnit = 'Per Kg';

  // Dates
  DateTime? cultivatedDate;
  DateTime? expiryDate;

  // Image
  Uint8List? imageBytes;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    _loadFarmerLocation();
  }

  // ================= LOAD FARMER LOCATION =================

  Future<void> _loadFarmerLocation() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final data = await supabase
          .from('profiles')
          .select('location')
          .eq('id', user.id)
          .single();

      final rawLocation = data['location'] ?? '';

      // 🔁 Convert Lat/Lng → Place name if needed
      if (rawLocation.contains('Lat') && !kIsWeb) {
        final address = await _convertLatLngToAddress(rawLocation);
        _locationCtrl.text = address;
      } else {
        _locationCtrl.text = rawLocation;
      }
    } catch (e) {
      debugPrint('Failed to load farmer location: $e');
    }
  }

  // ================= LAT LNG → ADDRESS =================

  Future<String> _convertLatLngToAddress(String location) async {
    try {
      final cleaned = location
          .replaceAll('Lat:', '')
          .replaceAll('Lng:', '')
          .split(',');

      final lat = double.parse(cleaned[0].trim());
      final lng = double.parse(cleaned[1].trim());

      final placemarks = await placemarkFromCoordinates(lat, lng);
      final place = placemarks.first;

      return "${place.locality ?? place.subAdministrativeArea}, "
          "${place.administrativeArea}";
    } catch (_) {
      return location; // fallback
    }
  }

  // ================= PICK IMAGE =================

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      imageBytes = await picked.readAsBytes();
      setState(() {});
    }
  }

  // ================= SAVE PRODUCT =================

  Future<void> saveProduct() async {
    if (_nameCtrl.text.isEmpty ||
        _priceCtrl.text.isEmpty ||
        _stockCtrl.text.isEmpty ||
        _locationCtrl.text.isEmpty ||
        cultivatedDate == null ||
        expiryDate == null ||
        imageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    try {
      setState(() => loading = true);

      final userId = supabase.auth.currentUser!.id;

      final imagePath =
          'products/$userId-${DateTime.now().millisecondsSinceEpoch}.jpg';

      await supabase.storage.from('product-images').uploadBinary(
        imagePath,
        imageBytes!,
        fileOptions: const FileOptions(contentType: 'image/jpeg'),
      );

      await supabase.from('products').insert({
        'farmer_id': userId,
        'name': _nameCtrl.text.trim(),
        'price': int.parse(_priceCtrl.text),
        'price_unit': priceUnit,
        'stock': int.parse(_stockCtrl.text),
        'stock_unit': stockUnit,
        'location': _locationCtrl.text.trim(), // ✅ HUMAN READABLE
        'cultivated_date': cultivatedDate!.toIso8601String(),
        'expiry_date': expiryDate!.toIso8601String(),
        'image_url': imagePath,
      });

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => loading = false);
    }
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Product"),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // IMAGE
            GestureDetector(
              onTap: pickImage,
              child: Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green),
                  image: imageBytes != null
                      ? DecorationImage(
                    image: MemoryImage(imageBytes!),
                    fit: BoxFit.cover,
                  )
                      : null,
                ),
                child: imageBytes == null
                    ? const Center(
                  child: Icon(Icons.add_a_photo,
                      size: 40, color: Colors.green),
                )
                    : null,
              ),
            ),

            const SizedBox(height: 20),

            _input("Product Name", _nameCtrl),

            // ✅ AUTO LOCATION (READ ONLY)
            TextField(
              controller: _locationCtrl,
              readOnly: true,
              decoration: InputDecoration(
                labelText: "Location",
                prefixIcon: const Icon(Icons.location_on),
                border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),

            const SizedBox(height: 15),

            _priceStockInput(
              label: "Price",
              controller: _priceCtrl,
              unit: priceUnit,
              onChanged: (v) => setState(() => priceUnit = v),
            ),

            _priceStockInput(
              label: "Stock",
              controller: _stockCtrl,
              unit: stockUnit,
              onChanged: (v) => setState(() => stockUnit = v),
            ),

            _datePicker(
              label: "Cultivated Date",
              date: cultivatedDate,
              onPick: (d) => setState(() => cultivatedDate = d),
            ),

            _datePicker(
              label: "Expiry Date",
              date: expiryDate,
              onPick: (d) => setState(() => expiryDate = d),
            ),

            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style:
                ElevatedButton.styleFrom(backgroundColor: Colors.green),
                onPressed: loading ? null : saveProduct,
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Add Product"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= HELPERS =================

  Widget _input(String label, TextEditingController c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: c,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  Widget _priceStockInput({
    required String label,
    required TextEditingController controller,
    required String unit,
    required ValueChanged<String> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: label,
                border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          const SizedBox(width: 10),
          DropdownButton<String>(
            value: unit,
            items: const [
              DropdownMenuItem(value: 'Per Kg', child: Text("Per Kg")),
              DropdownMenuItem(value: 'Per Qty', child: Text("Per Qty")),
            ],
            onChanged: (v) => onChanged(v!),
          ),
        ],
      ),
    );
  }

  Widget _datePicker({
    required String label,
    required DateTime? date,
    required ValueChanged<DateTime> onPick,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: Text(
        date == null
            ? "Select date"
            : date.toLocal().toString().split(' ')[0],
      ),
      trailing: const Icon(Icons.calendar_today),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          firstDate: DateTime(2020),
          lastDate: DateTime(2100),
          initialDate: DateTime.now(),
        );
        if (picked != null) onPick(picked);
      },
    );
  }
}

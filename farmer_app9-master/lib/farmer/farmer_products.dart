import 'package:farm_fresh_connect/farmer/edit_product.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FarmerProductsPage extends StatefulWidget {
  const FarmerProductsPage({super.key});

  @override
  State<FarmerProductsPage> createState() => _FarmerProductsPageState();
}

class _FarmerProductsPageState extends State<FarmerProductsPage> {
  final supabase = Supabase.instance.client;

  List products = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchMyProducts();
  }

  Future<void> fetchMyProducts() async {
    try {
      final farmerId = supabase.auth.currentUser!.id;

      final response = await supabase
          .from('products')
          .select()
          .eq('farmer_id', farmerId)
          .order('created_at', ascending: false);

      setState(() {
        products = response;
        loading = false;
      });
    } catch (e) {
      debugPrint(e.toString());
      setState(() => loading = false);
    }
  }

  // 🗑 DELETE PRODUCT
  Future<void> deleteProduct(String productId, String? imagePath) async {
    try {
      // delete image from storage
      if (imagePath != null && imagePath.isNotEmpty) {
        await supabase.storage
            .from('product-images')
            .remove([imagePath]);
      }

      // delete product row
      await supabase.from('products').delete().eq('id', productId);

      fetchMyProducts();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Uploaded Products"),
        backgroundColor: Colors.green,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : products.isEmpty
          ? const Center(child: Text("No products uploaded"))
          : ListView.builder(
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];

          // image url
          String? imageUrl;
          final imagePath = product['image_url'];

          if (imagePath != null) {
            imageUrl = imagePath.startsWith('http')
                ? imagePath
                : supabase.storage
                .from('product-images')
                .getPublicUrl(imagePath);
          }

          return Card(
            margin: const EdgeInsets.all(10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
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
                  : const Icon(Icons.image, size: 40),

              title: Text(
                product['name'],
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),

              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Stock: ${product['stock']} ${product['stock_unit']}",
                  ),
                  Text(
                    "Price: ₹${product['price']} ${product['price_unit']}",
                  ),
                ],
              ),

              trailing: PopupMenuButton(
                itemBuilder: (context) => [
                  PopupMenuItem(
                    child: const Text("Edit"),
                    onTap: () {
                      Future.delayed(
                        Duration.zero,
                            () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EditProductPage(
                                product: product,
                              ),
                            ),
                          ).then((_) => fetchMyProducts());
                        },
                      );
                    },
                  ),
                  PopupMenuItem(
                    child: const Text(
                      "Delete",
                      style: TextStyle(color: Colors.red),
                    ),
                    onTap: () {
                      Future.delayed(
                        Duration.zero,
                            () {
                          deleteProduct(
                            product['id'],
                            product['image_url'],
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

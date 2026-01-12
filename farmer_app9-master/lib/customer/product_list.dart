import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProductListPage extends StatefulWidget {
  const ProductListPage({super.key});

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  final supabase = Supabase.instance.client;

  List allProducts = [];
  List products = [];
  bool isLoading = true;

  /// productId -> quantity
  final Map<String, int> quantities = {};

  // ================= FILTER STATE =================
  String searchQuery = '';
  String sortBy = 'newest'; // newest | oldest | price_low | price_high

  @override
  void initState() {
    super.initState();
    fetchProducts();
  }

  // ================= FETCH PRODUCTS =================
  Future<void> fetchProducts() async {
    try {
      final data = await supabase
          .from('products')
          .select('''
            id,
            name,
            price,
            price_unit,
            image_url,
            farmer_id,
            created_at,
            profiles(name),
            offers!left (
              id,
              discount_type,
              discount_value,
              start_date,
              end_date
            )
          ''')
          .order('created_at', ascending: false);

      setState(() {
        allProducts = data;
        products = data;
        for (var p in products) {
          quantities[p['id']] = quantities[p['id']] ?? 1;
        }
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Fetch products error: $e");
      setState(() => isLoading = false);
    }
  }

  // ================= APPLY FILTERS =================
  void applyFilters() {
    List filtered = List.from(allProducts);

    // 🔍 Search
    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((p) {
        return p['name']
            .toString()
            .toLowerCase()
            .contains(searchQuery.toLowerCase());
      }).toList();
    }

    // ↕ Sort
    if (sortBy == 'price_low') {
      filtered.sort((a, b) => a['price'].compareTo(b['price']));
    } else if (sortBy == 'price_high') {
      filtered.sort((a, b) => b['price'].compareTo(a['price']));
    } else if (sortBy == 'oldest') {
      filtered.sort((a, b) =>
          DateTime.parse(a['created_at'])
              .compareTo(DateTime.parse(b['created_at'])));
    } else {
      filtered.sort((a, b) =>
          DateTime.parse(b['created_at'])
              .compareTo(DateTime.parse(a['created_at'])));
    }

    setState(() => products = filtered);
  }

  // ================= ACTIVE OFFER =================
  Map<String, dynamic>? getActiveOffer(Map product) {
    if (product['offers'] == null || product['offers'].isEmpty) return null;

    final offer = product['offers'][0];
    final now = DateTime.now();
    final start = DateTime.parse(offer['start_date']);
    final end = DateTime.parse(offer['end_date']);

    if (!now.isBefore(start) && !now.isAfter(end)) {
      return offer;
    }
    return null;
  }

  // ================= FINAL PRICE =================
  num calculateFinalPrice(Map product) {
    final int price = product['price'];
    final offer = getActiveOffer(product);

    if (offer == null) return price;

    if (offer['discount_type'] == 'percentage') {
      return price - ((price * offer['discount_value']) ~/ 100);
    } else {
      return price - offer['discount_value'];
    }
  }

  // ================= ADD TO CART =================
  Future<void> addToCart(Map product) async {
    final userId = supabase.auth.currentUser!.id;
    final qty = quantities[product['id']] ?? 1;
    final offer = getActiveOffer(product);
    final finalPrice = calculateFinalPrice(product);

    final existing = await supabase
        .from('cart')
        .select('id, quantity')
        .eq('customer_id', userId)
        .eq('product_id', product['id'])
        .maybeSingle();

    if (existing != null) {
      await supabase.from('cart').update({
        'quantity': (existing['quantity'] as int) + qty,
      }).eq('id', existing['id']);
    } else {
      await supabase.from('cart').insert({
        'customer_id': userId,
        'product_id': product['id'],
        'product_name': product['name'],
        'price': product['price'],
        'quantity': qty,
        'discount': offer != null ? offer['discount_value'] : 0,
        'final_price': finalPrice,
        'offer_id': offer != null ? offer['id'] : null,
      });
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Added to cart"),
        backgroundColor: Colors.green,
      ),
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fresh Products'),
        backgroundColor: Colors.green,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(110),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                // 🔍 SEARCH
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search products...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) {
                    searchQuery = value;
                    applyFilters();
                  },
                ),
                const SizedBox(height: 8),

                // FILTER DROPDOWN
                Row(
                  children: [
                    const Text("Sort by: "),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: sortBy,
                      items: const [
                        DropdownMenuItem(
                            value: 'newest', child: Text('Newest')),
                        DropdownMenuItem(
                            value: 'oldest', child: Text('Oldest')),
                        DropdownMenuItem(
                            value: 'price_low', child: Text('Price: Low → High')),
                        DropdownMenuItem(
                            value: 'price_high', child: Text('Price: High → Low')),
                      ],
                      onChanged: (value) {
                        sortBy = value!;
                        applyFilters();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : products.isEmpty
          ? const Center(child: Text('No products found'))
          : ListView.builder(
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          final qty = quantities[product['id']] ?? 1;
          final offer = getActiveOffer(product);
          final finalPrice = calculateFinalPrice(product);
          final farmerName =
              product['profiles']?['name'] ?? 'Farmer';

          String? imageUrl;
          if (product['image_url'] != null &&
              product['image_url'].toString().isNotEmpty) {
            imageUrl = product['image_url']
                .toString()
                .startsWith('http')
                ? product['image_url']
                : supabase.storage
                .from('product-images')
                .getPublicUrl(product['image_url']);
          }

          return Card(
            margin: const EdgeInsets.all(10),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: imageUrl != null
                        ? Image.network(
                      imageUrl,
                      width: 90,
                      height: 90,
                      fit: BoxFit.cover,
                    )
                        : Container(
                      width: 90,
                      height: 90,
                      color: Colors.grey[300],
                      child: const Icon(Icons.image),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product['name'],
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                        ),
                        Text(
                          offer != null
                              ? "₹${product['price']} → ₹$finalPrice"
                              : "₹${product['price']} ${product['price_unit'] ?? ''}",
                          style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold),
                        ),
                        Text(
                          "Farmer: $farmerName",
                          style: const TextStyle(
                              fontSize: 13, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle),
                                  onPressed: qty > 1
                                      ? () => setState(() =>
                                  quantities[product['id']] =
                                      qty - 1)
                                      : null,
                                ),
                                Text(qty.toString()),
                                IconButton(
                                  icon: const Icon(Icons.add_circle),
                                  onPressed: () => setState(() =>
                                  quantities[product['id']] =
                                      qty + 1),
                                ),
                              ],
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green),
                              onPressed: () => addToCart(product),
                              child: const Text("Add"),
                            ),
                          ],
                        ),
                      ],
                    ),
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

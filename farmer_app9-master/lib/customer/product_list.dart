import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
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
  String sortBy = 'nearest'; // nearest | newest | oldest | price_low | price_high

  double? userLat;
  double? userLng;

  @override
  void initState() {
    super.initState();
    _init();

    // 🔥 Auto refresh every 1 minute
    Timer.periodic(const Duration(minutes: 1), (timer) {
      fetchProducts();
    });
  }
  Future<void> _init() async {
    final hasSavedLocation = await _loadLocationFromProfile();

    if (!hasSavedLocation) {
      await _getUserLocation();
      await _saveLocationToProfile();
    }

    await fetchProducts();
  }

  Future<bool> _loadLocationFromProfile() async {
    try {
      final userId = supabase.auth.currentUser!.id;

      final data = await supabase
          .from('profiles')
          .select('latitude, longitude')
          .eq('id', userId)
          .maybeSingle();

      if (data != null &&
          data['latitude'] != null &&
          data['longitude'] != null) {
        userLat = (data['latitude'] as num).toDouble();
        userLng = (data['longitude'] as num).toDouble();
        debugPrint("Location loaded from DB");
        return true;
      }
    } catch (e) {
      debugPrint("DB location error: $e");
    }
    return false;
  }

  // ================= USER LOCATION =================
  // ================= USER LOCATION =================
  Future<void> _getUserLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        debugPrint("Location permission denied");
        userLat = null;
        userLng = null;
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        userLat = pos.latitude;
        userLng = pos.longitude;
      });
    } catch (e) {
      debugPrint("Location error: $e");
      userLat = null;
      userLng = null;
    }
  }
  Future<void> _saveLocationToProfile() async {
    if (userLat == null || userLng == null) return;

    try {
      final userId = supabase.auth.currentUser!.id;

      await supabase.from('profiles').update({
        'latitude': userLat,
        'longitude': userLng,
      }).eq('id', userId);

      debugPrint("Location saved to DB");
    } catch (e) {
      debugPrint("Save location failed: $e");
    }
  }



  // ================= DISTANCE CALC =================
  double _distanceKm(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371;
    final dLat = _deg(lat2 - lat1);
    final dLon = _deg(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg(lat1)) *
            cos(_deg(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    return R * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  double _deg(double d) => d * pi / 180;

  // ================= FETCH PRODUCTS =================
  Future<void> fetchProducts() async {
    try {
      final data = await supabase
          .from('products')
          .select('''
            id,
            name,
            price,
            stock,
            price_unit,
            image_url,
            farmer_id,
            created_at,
            profiles(
              name,
              latitude,
              longitude
            ),
            offers!left (
              id,
              discount_type,
              discount_value,
              start_date,
              end_date
            )
          ''');

      for (var p in data) {
        quantities[p['id']] = quantities[p['id']] ?? 1;

        if (userLat != null &&
            p['profiles']?['latitude'] != null &&
            p['profiles']?['longitude'] != null) {
          p['distance'] = _distanceKm(
            userLat!,
            userLng!,
            p['profiles']['latitude'],
            p['profiles']['longitude'],
          );
        } else {
          p['distance'] = 9999.0;
        }
      }

      setState(() {
        allProducts = data;
        applyFilters();
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
    if (sortBy == 'nearest') {
      filtered.sort((a, b) =>
          (a['distance'] as double).compareTo(b['distance']));
    } else if (sortBy == 'price_low') {
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
    if (product['offers'] == null) return null;

    final List offers = product['offers'];
    if (offers.isEmpty) return null;

    final now = DateTime.now();

    for (var offer in offers) {
      if (offer['start_date'] == null || offer['end_date'] == null) continue;

      final start = DateTime.parse(offer['start_date']);

      // 🔥 Offer valid till end of expiry day (11:59 PM)
      final endRaw = DateTime.parse(offer['end_date']);
      final end = DateTime(
        endRaw.year,
        endRaw.month,
        endRaw.day,
        23,
        59,
        59,
      );

      // ✅ Ignore expired offers automatically
      if (now.isAfter(start.subtract(const Duration(seconds: 1))) &&
          now.isBefore(end)) {
        return offer;
      }
    }

    return null; // expired offers automatically removed
  }


// ================= FINAL PRICE =================
  num calculateFinalPrice(Map product) {
    final int price = product['price'];
    final offer = getActiveOffer(product);

    if (offer == null) return price;

    num finalPrice;

    if (offer['discount_type'] == 'percentage') {
      finalPrice = price - ((price * offer['discount_value']) / 100);
    } else {
      finalPrice = price - offer['discount_value'];
    }

    if (finalPrice < 0) finalPrice = 0;

    return finalPrice.round();
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
    final int availableStock = product['stock'] ?? 0;

    if (qty > availableStock) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Only $availableStock available"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }


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
                Row(
                  children: [
                    const Text("Sort by: "),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: sortBy,
                      items: const [
                        DropdownMenuItem(
                            value: 'nearest', child: Text('Nearest')),
                        DropdownMenuItem(
                            value: 'newest', child: Text('Newest')),
                        DropdownMenuItem(
                            value: 'oldest', child: Text('Oldest')),
                        DropdownMenuItem(
                            value: 'price_low',
                            child: Text('Price: Low → High')),
                        DropdownMenuItem(
                            value: 'price_high',
                            child: Text('Price: High → Low')),
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
          bool endsToday = false;

          if (offer != null) {
            final endDate = DateTime.parse(offer['end_date']);
            final now = DateTime.now();

            endsToday =
                endDate.year == now.year &&
                    endDate.month == now.month &&
                    endDate.day == now.day;
          }

          final farmerName =
              product['profiles']?['name'] ?? 'Farmer';
          final distance =
          (product['distance'] as double).toStringAsFixed(1);

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
                          "Available: ${product['stock']} ${product['price_unit'] ?? 'kg'}",
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        offer != null
                            ? Row(
                          children: [
                            Text(
                              "₹${product['price']}",
                              style: const TextStyle(
                                decoration: TextDecoration.lineThrough,
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "₹$finalPrice",
                              style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        )
                            : Text(
                          "₹${product['price']} ${product['price_unit'] ?? ''}",
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        if (offer != null)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: endsToday ? Colors.red : Colors.orange,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              endsToday ? "Offer ends today!" : "Limited time offer",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        if (offer != null)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.orangeAccent,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              offer['discount_type'] == 'percentage'
                                  ? "${offer['discount_value']}% OFF"
                                  : "₹${offer['discount_value']} OFF",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),


                        Text(
                          "Farmer: $farmerName • $distance km",
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
                                  onPressed: qty < (product['stock'] ?? 0)
                                      ? () => setState(() =>
                                  quantities[product['id']] = qty + 1)
                                      : null,
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

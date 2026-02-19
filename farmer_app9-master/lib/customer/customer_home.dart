import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';

import 'product_list.dart';
import 'order_status.dart';
import 'customer_offers.dart';
import 'cart_page.dart';
import 'customer_edit_page.dart';
import '../onboarding/onboarding_screen.dart';
import '../core/language_service.dart';

class CustomerHome extends StatefulWidget {
  const CustomerHome({super.key});

  @override
  State<CustomerHome> createState() => _CustomerHomeState();
}

class _CustomerHomeState extends State<CustomerHome> {

  // ================= INIT =================
  @override
  void initState() {
    super.initState();
    _saveCustomerLocation();
  }

  // ================= SAVE CUSTOMER LOCATION =================
  Future<void> _saveCustomerLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      await Supabase.instance.client.from('profiles').update({
        'latitude': position.latitude,
        'longitude': position.longitude,
      }).eq('id', user.id);

    } catch (e) {
      debugPrint('Location error: $e');
    }
  }

  // ================= FETCH CUSTOMER PROFILE =================
  Future<Map<String, dynamic>> _getCustomerProfile() async {
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      return {
        'name': 'Customer',
        'avatar_url': null,
      };
    }

    final data = await Supabase.instance.client
        .from('profiles')
        .select('name, avatar_url')
        .eq('id', user.id)
        .limit(1);

    if (data.isEmpty) {
      return {
        'name': 'Customer',
        'avatar_url': null,
      };
    }

    return {
      'name': data.first['name'] ?? 'Customer',
      'avatar_url': data.first['avatar_url'],
    };
  }

  // ================= FETCH ORDER COUNT =================
  Future<int> _getOrderCount() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return 0;

    final data = await Supabase.instance.client
        .from('orders')
        .select('id')
        .eq('customer_id', user.id);

    return data.length;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _getCustomerProfile(),
      builder: (context, snapshot) {
        final customerName = snapshot.data?['name'] ?? 'Customer';
        final avatarUrl = snapshot.data?['avatar_url'];

        return Scaffold(
          backgroundColor: const Color(0xFFF6F7FB),

          // ================= APP BAR =================
          appBar: AppBar(
            title: const Text("Customer Home"),
            backgroundColor: Colors.green,
            elevation: 0,
          ),

          // ================= DRAWER =================
          drawer: Drawer(
            child: Column(
              children: [
                GestureDetector(
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const  CustomerEditPage(),
                      ),
                    );
                    setState(() {});
                  },
                  child: DrawerHeader(
                    decoration: const BoxDecoration(color: Colors.green),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.white,
                          backgroundImage:
                          avatarUrl != null ? NetworkImage(avatarUrl) : null,
                          child: avatarUrl == null
                              ? const Icon(Icons.person,
                              size: 32, color: Colors.green)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              customerName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text(
                              "Tap to edit profile",
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                _drawerItem(
                  icon: Icons.home,
                  title: "Home",
                  onTap: () => Navigator.pop(context),
                ),
                _drawerItem(
                  icon: Icons.shopping_bag,
                  title: "Browse Products",
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProductListPage()),
                  ),
                ),
                _drawerItem(
                  icon: Icons.shopping_cart,
                  title: "My Cart",
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CartPage()),
                  ),
                ),
                _drawerItem(
                  icon: Icons.receipt_long,
                  title: "My Orders",
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const OrderStatusPage()),
                  ),
                ),
                _drawerItem(
                  icon: Icons.local_offer,
                  title: "Offers & Discounts",
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CustomerOffers()),
                  ),
                ),

                const Spacer(),
                const Divider(),

                _drawerItem(
                  icon: Icons.logout,
                  title: "Logout",
                  onTap: () async {
                    await Supabase.instance.client.auth.signOut();
                    await LanguageService.clearLanguage();

                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const OnboardingScreen(),
                      ),
                          (route) => false,
                    );
                  },
                ),
              ],
            ),
          ),

          // ================= BODY =================
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Welcome $customerName 👋",
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),

                _homeCard(
                  context,
                  title: "Browse Products",
                  subtitle: "Fresh items from farmers",
                  icon: Icons.shopping_bag,
                  page: const ProductListPage(),
                ),
                _homeCard(
                  context,
                  title: "My Cart",
                  subtitle: "View selected products",
                  icon: Icons.shopping_cart,
                  page: const CartPage(),
                ),

                FutureBuilder<int>(
                  future: _getOrderCount(),
                  builder: (context, snapshot) {
                    final count = snapshot.data ?? 0;
                    return _homeCard(
                      context,
                      title: "My Orders",
                      subtitle: count > 0
                          ? "You have $count orders"
                          : "No orders yet",
                      icon: Icons.receipt_long,
                      page: const OrderStatusPage(),
                      badgeCount: count,
                    );
                  },
                ),

                _homeCard(
                  context,
                  title: "Offers & Discounts",
                  subtitle: "Save more on orders",
                  icon: Icons.local_offer,
                  page: const CustomerOffers(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ================= HOME CARD =================
  Widget _homeCard(
      BuildContext context, {
        required String title,
        required String subtitle,
        required IconData icon,
        required Widget page,
        int badgeCount = 0,
      }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(14),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: Colors.green.withOpacity(0.1),
          child: Icon(icon, color: Colors.green, size: 26),
        ),
        title: Row(
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(width: 8),
            if (badgeCount > 0)
              CircleAvatar(
                radius: 10,
                backgroundColor: Colors.red,
                child: Text(
                  badgeCount.toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
          ],
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => page),
          );
        },
      ),
    );
  }

  // ================= DRAWER ITEM =================
  Widget _drawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.green),
      title: Text(title),
      onTap: onTap,
    );
  }
}

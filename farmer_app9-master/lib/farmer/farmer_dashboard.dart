import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../onboarding/onboarding_screen.dart';
import '../core/language_service.dart';

// Farmer screens
import 'add_product.dart';
import 'farmer_orders.dart';
import 'farmer_products.dart';
import 'sales_revenue.dart';
import 'show_rating.dart';
import 'offers_list.dart';
import 'assign_delivery_page.dart'; // ✅ NEW

class FarmerDashboard extends StatelessWidget {
  const FarmerDashboard({super.key});

  // 🔹 Fetch farmer profile from profiles table
  Future<Map<String, dynamic>?> _getFarmerProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return null;

    final data = await Supabase.instance.client
        .from('profiles')
        .select('name, mobile')
        .eq('id', user.id)
        .single();

    return data;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Farmer Dashboard"),
        backgroundColor: Colors.green,
      ),

      // ✅ DRAWER
      drawer: _drawer(context),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Welcome Farmer 👨‍🌾",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            _homeButton(
              context,
              "Uploaded Products",
              Icons.inventory,
              const FarmerProductsPage(),
            ),

            _homeButton(
              context,
              "Received Orders",
              Icons.receipt_long,
              const FarmerOrders(),
            ),

            // ✅ NEW: ASSIGN DELIVERY PARTNER
            _homeButton(
              context,
              "Assign Delivery Partner",
              Icons.delivery_dining,
              const AssignDeliveryPage(),
            ),

            _homeButton(
              context,
              "Sales & Revenue",
              Icons.currency_rupee,
              const SalesRevenue(),
            ),
          ],
        ),
      ),
    );
  }

  // ================= DRAWER =================

  Drawer _drawer(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          // ✅ FARMER NAME + MOBILE
          FutureBuilder<Map<String, dynamic>?>(
            future: _getFarmerProfile(),
            builder: (context, snapshot) {
              final name = snapshot.data?['name'] ?? 'Farmer';
              final mobile = snapshot.data?['mobile'] ?? '';

              return DrawerHeader(
                decoration: const BoxDecoration(color: Colors.green),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.person,
                        color: Colors.green,
                        size: 35,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          mobile,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),

          _drawerItem(
            context: context,
            title: "Home",
            icon: Icons.home,
            onTap: () => Navigator.pop(context),
          ),

          _drawerItem(
            context: context,
            title: "Uploaded Products",
            icon: Icons.inventory,
            onTap: () => _navigate(context, const FarmerProductsPage()),
          ),

          _drawerItem(
            context: context,
            title: "Orders",
            icon: Icons.receipt_long,
            onTap: () => _navigate(context, const FarmerOrders()),
          ),

          // ✅ NEW: ASSIGN DELIVERY
          _drawerItem(
            context: context,
            title: "Assign Delivery Partner",
            icon: Icons.delivery_dining,
            onTap: () => _navigate(context, const AssignDeliveryPage()),
          ),

          _drawerItem(
            context: context,
            title: "Add Product",
            icon: Icons.add_box,
            onTap: () => _navigate(context, const AddProduct()),
          ),

          _drawerItem(
            context: context,
            title: "Show Rating",
            icon: Icons.star,
            onTap: () => _navigate(context, const ShowRating()),
          ),

          _drawerItem(
            context: context,
            title: "Offers & Discount",
            icon: Icons.local_offer,
            onTap: () => _navigate(context, const OffersList()),
          ),

          const Spacer(),
          const Divider(),

          // 🔴 LOGOUT
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text("Logout"),
            onTap: () async {
              await Supabase.instance.client.auth.signOut();
              await LanguageService.clearLanguage();

              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (_) => const OnboardingScreen(),
                ),
                    (_) => false,
              );
            },
          ),
        ],
      ),
    );
  }

  // ================= HELPERS =================

  void _navigate(BuildContext context, Widget page) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }

  Widget _homeButton(
      BuildContext context,
      String title,
      IconData icon,
      Widget page,
      ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.green),
        title: Text(title),
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

  Widget _drawerItem({
    required BuildContext context,
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.green),
      title: Text(title),
      onTap: onTap,
    );
  }
}

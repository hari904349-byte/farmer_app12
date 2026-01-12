import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'product_list.dart';
import 'order_status.dart';
import 'customer_offers.dart';
import 'cart_page.dart';
import '../onboarding/onboarding_screen.dart';
import '../core/language_service.dart';

class CustomerHome extends StatelessWidget {
  const CustomerHome({super.key});

  // ================= FETCH CUSTOMER NAME =================
  Future<String> _getCustomerName() async {
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) return "Customer";

    final data = await Supabase.instance.client
        .from('profiles')
        .select('name')
        .eq('id', user.id)
        .single();

    return data['name'] ?? "Customer";
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _getCustomerName(),
      builder: (context, snapshot) {
        final customerName = snapshot.data ?? "Customer";

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
                DrawerHeader(
                  decoration: const BoxDecoration(color: Colors.green),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.person,
                            size: 32, color: Colors.green),
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
                            "Customer",
                            style: TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ],
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
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ProductListPage()),
                    );
                  },
                ),
                _drawerItem(
                  icon: Icons.shopping_cart,
                  title: "My Cart",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CartPage()),
                    );
                  },
                ),
                _drawerItem(
                  icon: Icons.receipt_long,
                  title: "My Orders",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const OrderStatusPage()),
                    );
                  },
                ),
                _drawerItem(
                  icon: Icons.local_offer,
                  title: "Offers & Discounts",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const CustomerOffers()),
                    );
                  },
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
                          builder: (_) => const OnboardingScreen()),
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
                  "Welcome $customerName ",
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
                _homeCard(
                  context,
                  title: "My Orders",
                  subtitle: "Track your orders",
                  icon: Icons.receipt_long,
                  page: const OrderStatusPage(),
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
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
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

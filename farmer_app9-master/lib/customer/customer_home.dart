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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Customer Home"),
        backgroundColor: Colors.green,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
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

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Welcome Customer 🛒",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            _homeTile(
              context,
              title: "Browse Products",
              icon: Icons.shopping_bag,
              page: const ProductListPage(),
            ),

            _homeTile(
              context,
              title: "My Cart",
              icon: Icons.shopping_cart,
              page: const CartPage(),
            ),

            // ✅ FIXED HERE
            _homeTile(
              context,
              title: "My Orders",
              icon: Icons.receipt_long,
              page: const OrderStatusPage(),
            ),

            _homeTile(
              context,
              title: "Offers & Discounts",
              icon: Icons.local_offer,
              page: const CustomerOffers(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _homeTile(
      BuildContext context, {
        required String title,
        required IconData icon,
        required Widget page,
      }) {
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
}

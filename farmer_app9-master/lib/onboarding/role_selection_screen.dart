import 'package:flutter/material.dart';
import '../auth/login_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Select Your Role")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _roleCard(
              context,
              icon: Icons.agriculture,
              title: "Farmer",
              color: Colors.green,
              role: "farmer",
            ),
            const SizedBox(height: 20),
            _roleCard(
              context,
              icon: Icons.shopping_cart,
              title: "Customer",
              color: Colors.orange,
              role: "customer",
            ),
            const SizedBox(height: 20),
            _roleCard(
              context,
              icon: Icons.delivery_dining,
              title: "Delivery Partner",
              color: Colors.blue,
              role: "delivery",
            ),
          ],
        ),
      ),
    );
  }

  Widget _roleCard(
      BuildContext context, {
        required IconData icon,
        required String title,
        required Color color,
        required String role,
      }) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LoginScreen(role: role),
          ),
        );
      },
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(icon, size: 50, color: color),
              const SizedBox(width: 20),
              Text(
                title,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

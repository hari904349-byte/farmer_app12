import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'assigned_orders.dart';
import 'delivery_requests.dart';
import 'delivery_edit_page.dart'; // ✅ USE DELIVERY EDIT PAGE
import '../onboarding/onboarding_screen.dart';

class DeliveryHome extends StatefulWidget {
  const DeliveryHome({super.key});

  @override
  State<DeliveryHome> createState() => _DeliveryHomeState();
}

class _DeliveryHomeState extends State<DeliveryHome> {
  final supabase = Supabase.instance.client;

  String name = "Delivery Partner";
  String? profileImage;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  // ================= LOAD PROFILE =================
  Future<void> _loadProfile() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final data = await supabase
          .from('profiles')
          .select('name, profile_image')
          .eq('id', user.id)
          .single();

      setState(() {
        name = data['name'] ?? "Delivery Partner";
        profileImage = data['profile_image'];
        loading = false;
      });
    } catch (e) {
      debugPrint("Profile load error: $e");
      setState(() => loading = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),

      // ================= APP BAR =================
      appBar: AppBar(
        title: const Text("Delivery Partner"),
        backgroundColor: Colors.green,
        elevation: 0,
      ),

      // ================= DRAWER =================
      drawer: Drawer(
        child: Column(
          children: [
            // ===== PROFILE HEADER =====
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DeliveryEditPage(), // ✅ UPDATED
                  ),
                ).then((_) => _loadProfile());
              },
              child: DrawerHeader(
                decoration: const BoxDecoration(color: Colors.green),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: Colors.white,
                      backgroundImage:
                      profileImage != null && profileImage!.isNotEmpty
                          ? NetworkImage(profileImage!)
                          : null,
                      child: profileImage == null
                          ? const Icon(Icons.person,
                          size: 34, color: Colors.green)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
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
                        const Text(
                          "Tap to edit profile",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
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
              icon: Icons.person,
              title: "Edit Profile",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DeliveryEditPage(), // ✅ UPDATED
                  ),
                ).then((_) => _loadProfile());
              },
            ),

            const Spacer(),
            const Divider(),

            _drawerItem(
              icon: Icons.logout,
              title: "Logout",
              onTap: () async {
                await supabase.auth.signOut();
                if (!mounted) return;

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
      ),

      // ================= BODY =================
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Welcome $name 🚚",
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            _homeCard(
              icon: Icons.notifications_active,
              title: "Delivery Requests",
              subtitle:
              "New orders waiting for delivery partner",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                    const DeliveryRequestsPage(),
                  ),
                );
              },
            ),

            _homeCard(
              icon: Icons.assignment,
              title: "Assigned Orders",
              subtitle: "Orders you have accepted",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                    const AssignedOrdersPage(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ================= HOME CARD =================
  Widget _homeCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
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
        onTap: onTap,
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

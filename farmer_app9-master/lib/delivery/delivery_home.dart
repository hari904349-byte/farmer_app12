import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../customer/profile_edit_page.dart';
import 'assigned_orders.dart';
import '../profile/profile_edit_page.dart';
import '../onboarding/onboarding_screen.dart';

class DeliveryHome extends StatefulWidget {
  const DeliveryHome({super.key});

  @override
  State<DeliveryHome> createState() => _DeliveryHomeState();
}

class _DeliveryHomeState extends State<DeliveryHome> {
  final supabase = Supabase.instance.client;

  String name = "Delivery Partner";
  String? avatarUrl;
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
          .select('name, avatar_url')
          .eq('id', user.id)
          .single();

      setState(() {
        name = data['name'] ?? "Delivery Partner";
        avatarUrl = data['avatar_url'];
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
                    builder: (_) => const ProfileEditPage(),
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
                      avatarUrl != null && avatarUrl!.isNotEmpty
                          ? NetworkImage(avatarUrl!)
                          : null,
                      child: avatarUrl == null
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
              icon: Icons.assignment,
              title: "Assigned Orders",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AssignedOrdersPage(),
                  ),
                );
              },
            ),

            _drawerItem(
              icon: Icons.person,
              title: "Edit Profile",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ProfileEditPage(),
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

            // ===== ASSIGNED ORDERS CARD =====
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(14),
                leading: CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.green.withOpacity(0.1),
                  child: const Icon(
                    Icons.assignment,
                    color: Colors.green,
                    size: 26,
                  ),
                ),
                title: const Text(
                  "Assigned Orders",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text("View and manage deliveries"),
                trailing:
                const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AssignedOrdersPage(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
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

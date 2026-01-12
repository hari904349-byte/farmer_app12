import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/supabase_helper.dart';

class RegisterCustomer extends StatelessWidget {
  RegisterCustomer({super.key});

  // 🔹 Controllers
  final usernameCtrl = TextEditingController();
  final mobileCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final locationCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  final confirmPasswordCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Customer Registration"),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _input("Username", usernameCtrl),
            _input("Mobile Number", mobileCtrl),
            _input("Email", emailCtrl),
            _inputWithIcon("Location", Icons.location_on, locationCtrl),
            _password("Password", passwordCtrl),
            _password("Confirm Password", confirmPasswordCtrl),

            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                onPressed: () => _registerCustomer(context),
                child: const Text("Register", style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= REGISTER LOGIC =================

  Future<void> _registerCustomer(BuildContext context) async {
    final name = usernameCtrl.text.trim();
    final mobile = mobileCtrl.text.trim();
    final email = emailCtrl.text.trim();
    final location = locationCtrl.text.trim();
    final password = passwordCtrl.text.trim();
    final confirmPassword = confirmPasswordCtrl.text.trim();

    // 🔐 VALIDATIONS
    if (name.isEmpty ||
        mobile.isEmpty ||
        email.isEmpty ||
        location.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      _show(context, "All fields are required");
      return;
    }

    if (!email.contains('@')) {
      _show(context, "Enter a valid email");
      return;
    }

    if (password.length < 6) {
      _show(context, "Password must be at least 6 characters");
      return;
    }

    if (password != confirmPassword) {
      _show(context, "Passwords do not match");
      return;
    }

    try {
      // 1️⃣ AUTH SIGN UP
      final auth = await SupabaseHelper.signUp(
        email: email,
        password: password,
      );

      final user = auth.user;
      if (user == null) {
        throw Exception("User creation failed");
      }

      // 2️⃣ INSERT PROFILE (NO DUPLICATE CHECK NEEDED)
      await SupabaseHelper.insertProfile({
        'id': user.id,
        'role': 'customer',
        'name': name,
        'mobile': mobile,
        'email': email,
        'location': location,
      });

      _show(context, "Customer registered successfully");
      Navigator.pop(context);

    } on AuthException catch (e) {
      _show(context, e.message);
    } catch (e) {
      _show(context, "Registration failed");
    }
  }

  // ================= UI HELPERS =================

  Widget _input(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        decoration: _inputStyle(label),
      ),
    );
  }

  Widget _inputWithIcon(
      String label, IconData icon, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        decoration: _inputStyle(label).copyWith(
          prefixIcon: Icon(icon),
        ),
      ),
    );
  }

  Widget _password(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        obscureText: true,
        decoration: _inputStyle(label),
      ),
    );
  }

  InputDecoration _inputStyle(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

  void _show(BuildContext context, String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }
}

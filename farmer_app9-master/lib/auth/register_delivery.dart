import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_helper.dart';

class RegisterDelivery extends StatefulWidget {
  const RegisterDelivery({super.key});

  @override
  State<RegisterDelivery> createState() => _RegisterDeliveryState();
}

class _RegisterDeliveryState extends State<RegisterDelivery> {
  final nameController = TextEditingController();
  final mobileController = TextEditingController();
  final emailController = TextEditingController();
  final vehicleController = TextEditingController();
  final locationController = TextEditingController();
  final aadharController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Delivery Partner Registration"),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _input("Name", nameController),
            _input("Mobile Number", mobileController,
                keyboard: TextInputType.phone),
            _inputWithIcon("Email", emailController, Icons.email),
            _input("Vehicle Details", vehicleController),
            _inputWithIcon("Location", locationController, Icons.location_on),
            _aadharInput(),
            _password("Password", passwordController),
            _password("Confirm Password", confirmPasswordController),

            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                onPressed: _registerDelivery,
                child: const Text("Register", style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= REGISTER LOGIC =================

  Future<void> _registerDelivery() async {
    final name = nameController.text.trim();
    final mobile = mobileController.text.trim();
    final email = emailController.text.trim();
    final vehicle = vehicleController.text.trim();
    final location = locationController.text.trim();
    final aadhar = aadharController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    // 🔐 VALIDATIONS
    if (name.isEmpty ||
        mobile.isEmpty ||
        email.isEmpty ||
        vehicle.isEmpty ||
        location.isEmpty ||
        aadhar.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      _showMsg("All fields are required");
      return;
    }

    if (!email.contains('@')) {
      _showMsg("Enter a valid email");
      return;
    }

    if (password.length < 6) {
      _showMsg("Password must be at least 6 characters");
      return;
    }

    if (password != confirmPassword) {
      _showMsg("Passwords do not match");
      return;
    }

    if (aadhar.length != 12) {
      _showMsg("Aadhar must be 12 digits");
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

      // 2️⃣ INSERT PROFILE (NO CHECK NEEDED)
      await SupabaseHelper.insertProfile({
        'id': user.id,
        'role': 'delivery',
        'name': name,
        'mobile': mobile,
        'email': email,
        'vehicle': vehicle,
        'location': location,
        'aadhar': aadhar,
      });

      _showMsg("Delivery partner registered successfully");
      Navigator.pop(context);

    } on AuthException catch (e) {
      _showMsg(e.message);
    } catch (e) {
      _showMsg("Registration failed");
    }
  }

  // ================= UI HELPERS =================

  Widget _input(String label, TextEditingController controller,
      {TextInputType keyboard = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        keyboardType: keyboard,
        decoration: _inputStyle(label),
      ),
    );
  }

  Widget _inputWithIcon(
      String label, TextEditingController controller, IconData icon) {
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

  Widget _aadharInput() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: aadharController,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(12),
        ],
        decoration: _inputStyle("Aadhar Number").copyWith(
          prefixIcon: const Icon(Icons.badge),
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

  void _showMsg(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }
}

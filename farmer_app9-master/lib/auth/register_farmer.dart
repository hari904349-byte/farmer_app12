import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/supabase_helper.dart';

class RegisterFarmer extends StatefulWidget {
  const RegisterFarmer({super.key});

  @override
  State<RegisterFarmer> createState() => _RegisterFarmerState();
}

class _RegisterFarmerState extends State<RegisterFarmer> {

  // 🔹 CONTROLLERS
  final nameController = TextEditingController();
  final mobileController = TextEditingController();
  final emailController = TextEditingController();
  final locationController = TextEditingController();
  final aadhaarController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Farmer Registration"),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            _input("Username", nameController),
            _input("Mobile Number", mobileController, keyboard: TextInputType.phone),
            _input("Email", emailController),
            _inputWithIcon("Location", locationController, Icons.location_on),

            // 🆔 AADHAAR
            _aadhaarInput(),

            _password("Password", passwordController),
            _password("Confirm Password", confirmPasswordController),

            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                onPressed: _registerFarmer,
                child: const Text("Register", style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= REGISTER LOGIC =================

  Future<void> _registerFarmer() async {
    if (passwordController.text != confirmPasswordController.text) {
      _showMsg("Passwords do not match");
      return;
    }

    if (aadhaarController.text.length != 12) {
      _showMsg("Aadhaar must be 12 digits");
      return;
    }

    try {
      // 1️⃣ AUTH SIGNUP
      final auth = await SupabaseHelper.signUp(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final userId = auth.user!.id;

      // 2️⃣ INSERT INTO PROFILES
      await SupabaseHelper.insertProfile({
        'id': userId,
        'role': 'farmer',
        'name': nameController.text.trim(),
        'mobile': mobileController.text.trim(),
        'email': emailController.text.trim(),
        'location': locationController.text.trim(),
        'aadhaar': aadhaarController.text.trim(),
      });

      _showMsg("Farmer Registered Successfully");
      Navigator.pop(context);

    } catch (e) {
      _showMsg(e.toString());
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

  Widget _aadhaarInput() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: aadhaarController,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(12),
        ],
        decoration: _inputStyle("Aadhaar Number").copyWith(
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

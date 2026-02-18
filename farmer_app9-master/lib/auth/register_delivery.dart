import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_helper.dart';

class RegisterDelivery extends StatefulWidget {
  const RegisterDelivery({super.key});

  @override
  State<RegisterDelivery> createState() => _RegisterDeliveryState();
}

class _RegisterDeliveryState extends State<RegisterDelivery> {
  final supabase = Supabase.instance.client;

  final nameController = TextEditingController();
  final mobileController = TextEditingController();
  final emailController = TextEditingController();
  final vehicleController = TextEditingController();
  final locationController = TextEditingController();
  final aadharController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  File? selectedImage;
  Uint8List? webImage;

  bool loading = false;

  // ================= UI =================

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

            // 🔥 PROFILE IMAGE
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 55,
                backgroundColor: Colors.grey[300],
                backgroundImage: kIsWeb
                    ? (webImage != null ? MemoryImage(webImage!) : null)
                    : (selectedImage != null
                    ? FileImage(selectedImage!)
                    : null) as ImageProvider?,
                child: (selectedImage == null && webImage == null)
                    ? const Icon(Icons.camera_alt, size: 35)
                    : null,
              ),
            ),

            const SizedBox(height: 25),

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
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
                onPressed: loading ? null : _registerDelivery,
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Register",
                    style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= IMAGE PICKER =================

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked =
    await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        setState(() {
          webImage = bytes;
        });
      } else {
        setState(() {
          selectedImage = File(picked.path);
        });
      }
    }
  }

  // ================= REGISTER =================

  Future<void> _registerDelivery() async {
    final name = nameController.text.trim();
    final mobile = mobileController.text.trim();
    final email = emailController.text.trim();
    final vehicle = vehicleController.text.trim();
    final location = locationController.text.trim();
    final aadhar = aadharController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

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

    if (password != confirmPassword) {
      _showMsg("Passwords do not match");
      return;
    }

    if (aadhar.length != 12) {
      _showMsg("Aadhar must be 12 digits");
      return;
    }

    setState(() => loading = true);

    try {
      // 1️⃣ CREATE AUTH USER
      final auth = await SupabaseHelper.signUp(
        email: email,
        password: password,
      );

      final user = auth.user;
      if (user == null) throw Exception("User creation failed");

      String? imageUrl;

      // 2️⃣ UPLOAD IMAGE IF SELECTED
      if (selectedImage != null || webImage != null) {
        final fileName =
            "${user.id}-${DateTime.now().millisecondsSinceEpoch}.jpg";

        if (kIsWeb) {
          await supabase.storage
              .from('profile_photos')
              .uploadBinary(fileName, webImage!);
        } else {
          await supabase.storage
              .from('profile_photos')
              .upload(fileName, selectedImage!);
        }

        imageUrl = supabase.storage
            .from('profile_photos')
            .getPublicUrl(fileName);
      }

      // 3️⃣ INSERT PROFILE
      await SupabaseHelper.insertProfile({
        'id': user.id,
        'role': 'delivery',
        'name': name,
        'mobile': mobile,
        'email': email,
        'vehicle': vehicle,
        'location': location,
        'aadhar': aadhar,
        'profile_image': imageUrl,
      });

      _showMsg("Delivery partner registered successfully");
      Navigator.pop(context);

    } on AuthException catch (e) {
      _showMsg(e.message);
    } catch (e) {
      _showMsg("Registration failed");
    } finally {
      setState(() => loading = false);
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

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase_helper.dart';

class RegisterCustomer extends StatefulWidget {
  const RegisterCustomer({super.key});

  @override
  State<RegisterCustomer> createState() => _RegisterCustomerState();
}

class _RegisterCustomerState extends State<RegisterCustomer> {
  final supabase = Supabase.instance.client;

  final usernameCtrl = TextEditingController();
  final mobileCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final locationCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  final confirmPasswordCtrl = TextEditingController();

  bool loadingLocation = false;
  bool loadingRegister = false;

  double? _currentLat;
  double? _currentLng;

  File? selectedImage;
  Uint8List? webImage;

  // ================= UI =================

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

            _input("Username", usernameCtrl),
            _input("Mobile Number", mobileCtrl,
                keyboard: TextInputType.phone),
            _input("Email", emailCtrl),

            _locationInput(),

            _password("Password", passwordCtrl),
            _password("Confirm Password", confirmPasswordCtrl),

            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
                onPressed: loadingRegister ? null : _registerCustomer,
                child: loadingRegister
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

  // ================= LOCATION =================

  Widget _locationInput() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: locationCtrl,
        readOnly: true,
        decoration: InputDecoration(
          labelText: "Location",
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          prefixIcon: const Icon(Icons.location_on),
          suffixIcon: loadingLocation
              ? const Padding(
            padding: EdgeInsets.all(12),
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
              : IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _getCurrentLocation,
          ),
        ),
      ),
    );
  }

  Future<void> _getCurrentLocation() async {
    setState(() => loadingLocation = true);

    try {
      LocationPermission permission =
      await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _currentLat = position.latitude;
      _currentLng = position.longitude;

      if (kIsWeb) {
        locationCtrl.text = "Location selected";
        return;
      }

      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      final place = placemarks.first;

      locationCtrl.text =
      "${place.locality}, ${place.administrativeArea}";
    } catch (_) {
      _show("Unable to fetch location");
    } finally {
      setState(() => loadingLocation = false);
    }
  }

  // ================= REGISTER =================

  Future<void> _registerCustomer() async {
    final name = usernameCtrl.text.trim();
    final mobile = mobileCtrl.text.trim();
    final email = emailCtrl.text.trim();
    final location = locationCtrl.text.trim();
    final password = passwordCtrl.text.trim();
    final confirmPassword = confirmPasswordCtrl.text.trim();

    if (name.isEmpty ||
        mobile.isEmpty ||
        email.isEmpty ||
        location.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      _show("All fields are required");
      return;
    }

    if (password != confirmPassword) {
      _show("Passwords do not match");
      return;
    }

    setState(() => loadingRegister = true);

    try {
      final auth = await SupabaseHelper.signUp(
        email: email,
        password: password,
      );

      final user = auth.user!;
      String? imageUrl;

      // 🔥 Upload image if selected
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

      await SupabaseHelper.insertProfile({
        'id': user.id,
        'role': 'customer',
        'name': name,
        'mobile': mobile,
        'email': email,
        'location': location,
        'latitude': _currentLat,
        'longitude': _currentLng,
        'profile_image': imageUrl,
      });

      _show("Customer registered successfully");
      Navigator.pop(context);

    } on AuthException catch (e) {
      _show(e.message);
    } catch (_) {
      _show("Registration failed");
    } finally {
      setState(() => loadingRegister = false);
    }
  }

  // ================= HELPERS =================

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

  void _show(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase_helper.dart';

class RegisterCustomer extends StatefulWidget {
  const RegisterCustomer({super.key});

  @override
  State<RegisterCustomer> createState() => _RegisterCustomerState();
}

class _RegisterCustomerState extends State<RegisterCustomer> {
  // 🔹 Controllers
  final usernameCtrl = TextEditingController();
  final mobileCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final locationCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  final confirmPasswordCtrl = TextEditingController();

  bool loadingLocation = false;
  bool loadingRegister = false;

  // ✅ LOCATION COORDINATES
  double? _currentLat;
  double? _currentLng;

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
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        _show("Location permission permanently denied");
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // ✅ SAVE LAT/LNG
      _currentLat = position.latitude;
      _currentLng = position.longitude;

      // 🌐 WEB FALLBACK
      if (kIsWeb) {
        locationCtrl.text = "Coimbatore, Tamil Nadu";
        return;
      }

      // 📱 MOBILE REVERSE GEOCODING
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      final place = placemarks.first;

      locationCtrl.text =
      "${place.locality}, ${place.administrativeArea}";
    } catch (e) {
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

    if (!email.contains('@')) {
      _show("Enter a valid email");
      return;
    }

    if (password.length < 6) {
      _show("Password must be at least 6 characters");
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
      await SupabaseHelper.insertProfile({
        'id': user.id,
        'role': 'customer',
        'name': name,
        'mobile': mobile,
        'email': email,
        'location': location,
        'latitude': _currentLat,
        'longitude': _currentLng,
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

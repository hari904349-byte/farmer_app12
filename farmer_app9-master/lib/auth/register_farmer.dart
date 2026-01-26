import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/supabase_helper.dart';

class RegisterFarmer extends StatefulWidget {
  const RegisterFarmer({super.key});

  @override
  State<RegisterFarmer> createState() => _RegisterFarmerState();
}

class _RegisterFarmerState extends State<RegisterFarmer> {
  final nameController = TextEditingController();
  final mobileController = TextEditingController();
  final emailController = TextEditingController();
  final locationController = TextEditingController();
  final aadhaarController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool loadingLocation = false;
  bool loadingRegister = false;

  // ✅ FIX: ADD LAT & LNG VARIABLES
  double? _currentLat;
  double? _currentLng;

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
            _input("Mobile Number", mobileController,
                keyboard: TextInputType.phone),
            _input("Email", emailController),

            _locationInput(),

            _aadhaarInput(),
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
                onPressed: loadingRegister ? null : _registerFarmer,
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
        controller: locationController,
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
        _showMsg("Location permission permanently denied");
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // ✅ SAVE LAT & LNG
      _currentLat = position.latitude;
      _currentLng = position.longitude;

      // 🌐 WEB FALLBACK (no reverse geocoding support)
      if (kIsWeb) {
        locationController.text = "Coimbatore, Tamil Nadu";
        return;
      }

      // 📱 MOBILE REVERSE GEOCODING
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      final place = placemarks.first;

      locationController.text =
      "${place.locality}, ${place.administrativeArea}";
    } catch (e) {
      _showMsg("Unable to fetch location");
    } finally {
      setState(() => loadingLocation = false);
    }
  }

  // ================= REGISTER =================

  Future<void> _registerFarmer() async {
    if (passwordController.text != confirmPasswordController.text) {
      _showMsg("Passwords do not match");
      return;
    }

    if (aadhaarController.text.length != 12) {
      _showMsg("Aadhaar must be 12 digits");
      return;
    }

    if (locationController.text.isEmpty) {
      _showMsg("Please select location");
      return;
    }

    setState(() => loadingRegister = true);

    try {
      final auth = await SupabaseHelper.signUp(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final userId = auth.user!.id;

      await SupabaseHelper.insertProfile({
        'id': userId,
        'role': 'farmer',
        'name': nameController.text.trim(),
        'mobile': mobileController.text.trim(),
        'email': emailController.text.trim(),
        'location': locationController.text.trim(),
        'latitude': _currentLat,
        'longitude': _currentLng,
        'aadhaar': aadhaarController.text.trim(),
      });

      _showMsg("Farmer registered successfully");
      Navigator.pop(context);
    } on AuthException catch (e) {
      if (e.code == 'user_already_exists') {
        _showMsg("Email already registered. Please login.");
      } else {
        _showMsg(e.message);
      }
    } catch (_) {
      _showMsg("Registration failed");
    } finally {
      setState(() => loadingRegister = false);
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
        decoration: _inputStyle("Aadhaar Number")
            .copyWith(prefixIcon: const Icon(Icons.badge)),
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

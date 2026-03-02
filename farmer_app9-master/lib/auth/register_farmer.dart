import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/supabase_helper.dart';

class RegisterFarmer extends StatefulWidget {
  const RegisterFarmer({super.key});

  @override
  State<RegisterFarmer> createState() => _RegisterFarmerState();
}

class _RegisterFarmerState extends State<RegisterFarmer> {
  final supabase = Supabase.instance.client;

  final nameController = TextEditingController();
  final mobileController = TextEditingController();
  final emailController = TextEditingController();
  final locationController = TextEditingController();
  final aadhaarController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool loadingLocation = false;
  bool loadingRegister = false;

  double? _currentLat;
  double? _currentLng;

  File? selectedImage; // mobile
  Uint8List? webImageBytes; // web

  final ImagePicker _picker = ImagePicker();
  ImageProvider? _getProfileImage() {
    if (kIsWeb && webImageBytes != null) {
      return MemoryImage(webImageBytes!);
    } else if (!kIsWeb && selectedImage != null) {
      return FileImage(selectedImage!);
    }
    return null;
  }

  // ================= UI =================

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

            // 🔥 PROFILE IMAGE
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey[300],
                backgroundImage: _getProfileImage(),
                child: (_getProfileImage() == null)
                    ? const Icon(Icons.camera_alt, size: 30)
                    : null,
              )
            ),

            const SizedBox(height: 20),

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

  // ================= IMAGE PICKER =================

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);

    if (picked == null) return;

    if (kIsWeb) {
      final bytes = await picked.readAsBytes();
      setState(() {
        webImageBytes = bytes;
      });
    } else {
      setState(() {
        selectedImage = File(picked.path);
      });
    }
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
        locationController.text = "Location selected";
        return;
      }

      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      final place = placemarks.first;
      locationController.text =
      "${place.locality}, ${place.administrativeArea}";
    } catch (_) {
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

    setState(() => loadingRegister = true);

    try {
      final auth = await SupabaseHelper.signUp(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final userId = auth.user!.id;
      String? imageUrl;

      // 🔥 Upload image if selected
      if ((kIsWeb && webImageBytes != null) ||
          (!kIsWeb && selectedImage != null)) {

        final fileName =
            "$userId-${DateTime.now().millisecondsSinceEpoch}.jpg";

        if (kIsWeb) {
          await supabase.storage
              .from('profile_photos')
              .uploadBinary(fileName, webImageBytes!,
              fileOptions: const FileOptions(upsert: true));
        } else {
          await supabase.storage
              .from('profile_photos')
              .upload(fileName, selectedImage!,
              fileOptions: const FileOptions(upsert: true));
        }

        imageUrl = supabase.storage
            .from('profile_photos')
            .getPublicUrl(fileName);
      }

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
        'profile_image': imageUrl,
      });

      _showMsg("Farmer registered successfully");
      Navigator.pop(context);
    } on AuthException catch (e) {
      _showMsg(e.message);
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
        decoration:
        _inputStyle("Aadhaar Number")
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

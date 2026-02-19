import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';


class DeliveryEditPage extends StatefulWidget {
  const DeliveryEditPage({super.key});

  @override
  State<DeliveryEditPage> createState() => _DeliveryEditPageState();
}

class _DeliveryEditPageState extends State<DeliveryEditPage> {
  final supabase = Supabase.instance.client;

  final nameController = TextEditingController();
  final mobileController = TextEditingController();
  Uint8List? selectedImageBytes;


  File? selectedImage;
  String? existingImageUrl;

  bool loading = true;
  bool saving = false;


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
          .select('name, mobile, profile_image')
          .eq('id', user.id)
          .single();

      nameController.text = data['name'] ?? '';
      mobileController.text = data['mobile'] ?? '';
      existingImageUrl = data['profile_image'];

      if (!mounted) return;
      setState(() => loading = false);
    } catch (e) {
      debugPrint("Load error: $e");
      if (!mounted) return;
      setState(() => loading = false);
    }
  }

  // ================= PICK IMAGE =================
  Future<void> _pickImage() async {
    final pickedFile =
    await ImagePicker().pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      selectedImageBytes = await pickedFile.readAsBytes();
      setState(() {});
    }
  }


  // ================= UPDATE PROFILE =================
  Future<void> _updateProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    setState(() => saving = true);

    try {
      String? imageUrl = existingImageUrl;

      // 🔥 Upload image (WEB SAFE)
      if (selectedImageBytes != null) {
        final fileName =
            "${user.id}-${DateTime.now().millisecondsSinceEpoch}.jpg";

        await supabase.storage
            .from('profile_photos')
            .uploadBinary(
          fileName,
          selectedImageBytes!,
          fileOptions: const FileOptions(upsert: true),
        );

        imageUrl = supabase.storage
            .from('profile_photos')
            .getPublicUrl(fileName);
      }


      final response = await supabase
          .from('profiles')
          .update({
        'name': nameController.text.trim(),
        'mobile': mobileController.text.trim(),
        'profile_image': imageUrl,
      })
          .eq('id', user.id)
          .select();

      if (response.isEmpty) {
        throw Exception("Update blocked by RLS");
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Profile updated successfully"),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);

    } catch (e) {
      print("UPDATE ERROR: $e"); // 🔥 See real error in console

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Update failed"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => saving = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Profile"),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            // ================= PROFILE IMAGE =================
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 55,
                backgroundColor: Colors.grey[300],
                backgroundImage: selectedImage != null
                    ? (kIsWeb
                    ? NetworkImage(selectedImage!.path)
                    : FileImage(selectedImage!) as ImageProvider)
                    : (existingImageUrl != null &&
                    existingImageUrl!.isNotEmpty)
                    ? NetworkImage(existingImageUrl!)
                    : null,
                child: selectedImage == null &&
                    (existingImageUrl == null ||
                        existingImageUrl!.isEmpty)
                    ? const Icon(Icons.camera_alt,
                    size: 30, color: Colors.black54)
                    : null,
              ),

            ),

            const SizedBox(height: 25),

            // ================= NAME =================
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: "Name",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            const SizedBox(height: 15),

            // ================= MOBILE =================
            TextField(
              controller: mobileController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: "Mobile",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            const SizedBox(height: 30),

            // ================= UPDATE BUTTON =================
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
                onPressed: saving ? null : _updateProfile,
                child: saving
                    ? const CircularProgressIndicator(
                    color: Colors.white)
                    : const Text(
                  "Update",
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

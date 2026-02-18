import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FarmerEditProfile extends StatefulWidget {
  const FarmerEditProfile({super.key});

  @override
  State<FarmerEditProfile> createState() => _FarmerEditProfileState();
}

class _FarmerEditProfileState extends State<FarmerEditProfile> {
  final supabase = Supabase.instance.client;

  final nameController = TextEditingController();
  final mobileController = TextEditingController();

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
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final data = await supabase
        .from('profiles')
        .select('name, mobile, profile_image')
        .eq('id', user.id)
        .single();

    setState(() {
      nameController.text = data['name'] ?? '';
      mobileController.text = data['mobile'] ?? '';
      existingImageUrl = data['profile_image'];
      loading = false;
    });
  }

  // ================= PICK IMAGE =================
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked =
    await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        selectedImage = File(picked.path);
      });
    }
  }

// ================= UPDATE PROFILE =================
  Future<void> _updateProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    setState(() => saving = true);

    try {
      String? imageUrl = existingImageUrl;

      // 🔥 Upload new image if selected
      if (selectedImage != null) {
        final fileName =
            "${user.id}-${DateTime.now().millisecondsSinceEpoch}.jpg";

        await supabase.storage
            .from('profile_photos')
            .upload(fileName, selectedImage!,
            fileOptions: const FileOptions(upsert: true));

        imageUrl = supabase.storage
            .from('profile_photos')
            .getPublicUrl(fileName);
      }

      // ✅ UPDATE PROFILE WITH RESPONSE CHECK
      final response = await supabase
          .from('profiles')
          .update({
        'name': nameController.text.trim(),
        'mobile': mobileController.text.trim(),
        'profile_image': imageUrl,
      })
          .eq('id', user.id)
          .select(); // 🔥 VERY IMPORTANT

      // 🚨 If no row updated → throw error
      if (response.isEmpty) {
        throw Exception("No rows updated");
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Update failed: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => saving = false);
    }
  }


  // ================= UI =================
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
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            // PROFILE IMAGE
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 60,
                backgroundColor: Colors.grey[300],
                backgroundImage: selectedImage != null
                    ? FileImage(selectedImage!)
                    : (existingImageUrl != null &&
                    existingImageUrl!.isNotEmpty)
                    ? NetworkImage(existingImageUrl!)
                as ImageProvider
                    : null,
                child: selectedImage == null &&
                    (existingImageUrl == null ||
                        existingImageUrl!.isEmpty)
                    ? const Icon(Icons.camera_alt, size: 30)
                    : null,
              ),
            ),

            const SizedBox(height: 25),

            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: "Name",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: mobileController,
              decoration: const InputDecoration(
                labelText: "Mobile",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 25),

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

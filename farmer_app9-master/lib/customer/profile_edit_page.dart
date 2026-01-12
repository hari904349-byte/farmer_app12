import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileEditPage extends StatefulWidget {
  const ProfileEditPage({super.key});

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  final supabase = Supabase.instance.client;

  final nameController = TextEditingController();
  final mobileController = TextEditingController();
  final emailController = TextEditingController();

  Uint8List? imageBytes;
  String? avatarUrl;

  bool loading = true;
  bool saving = false;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  // ================= LOAD PROFILE =================
  Future<void> _loadProfile() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw 'Not logged in';

      final res = await supabase
          .from('profiles')
          .select('name, mobile, email, avatar_url')
          .eq('id', user.id)
          .limit(1);

      if (res.isEmpty) {
        await supabase.from('profiles').insert({
          'id': user.id,
          'email': user.email,
        });
      } else {
        final data = res.first;
        nameController.text = data['name'] ?? '';
        mobileController.text = data['mobile'] ?? '';
        emailController.text = data['email'] ?? '';
        avatarUrl = data['avatar_url'];
      }
    } catch (e) {
      error = e.toString();
    }

    if (mounted) setState(() => loading = false);
  }

  // ================= PICK IMAGE (WEB SAFE) =================
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? picked =
    await picker.pickImage(source: ImageSource.gallery);

    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    setState(() {
      imageBytes = bytes;
    });
  }

  // ================= UPLOAD IMAGE =================
  Future<String?> _uploadImage() async {
    if (imageBytes == null) return avatarUrl;

    final user = supabase.auth.currentUser!;
    final path = 'customers/${user.id}.jpg';

    await supabase.storage.from('profile_photos').uploadBinary(
      path,
      imageBytes!,
      fileOptions: const FileOptions(upsert: true),
    );

    return supabase.storage.from('profile_photos').getPublicUrl(path);
  }

  // ================= SAVE PROFILE =================
  Future<void> _saveProfile() async {
    setState(() => saving = true);

    final imageUrl = await _uploadImage();
    final user = supabase.auth.currentUser!;

    await supabase.from('profiles').update({
      'name': nameController.text.trim(),
      'mobile': mobileController.text.trim(),
      'email': emailController.text.trim(),
      'avatar_url': imageUrl,
    }).eq('id', user.id);

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (error != null) {
      return Scaffold(
        appBar: AppBar(backgroundColor: Colors.green),
        body: Center(child: Text(error!)),
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
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 55,
                backgroundColor: Colors.green.shade100,
                backgroundImage: imageBytes != null
                    ? MemoryImage(imageBytes!)
                    : (avatarUrl != null
                    ? NetworkImage(avatarUrl!)
                    : null) as ImageProvider?,
                child: avatarUrl == null && imageBytes == null
                    ? const Icon(Icons.camera_alt,
                    size: 32, color: Colors.green)
                    : null,
              ),
            ),
            const SizedBox(height: 30),

            _field("Name", nameController, Icons.person),
            const SizedBox(height: 15),
            _field("Mobile", mobileController, Icons.phone),
            const SizedBox(height: 15),
            _field("Email", emailController, Icons.email),
            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: saving ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: saving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Save Changes"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController c, IconData icon) {
    return TextField(
      controller: c,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
    );
  }
}

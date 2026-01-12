import 'package:flutter/material.dart';
import '../core/language_service.dart';
import 'role_selection_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  String _selectedLanguage = 'en'; // default English

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Farm Fresh Connect"),
        backgroundColor: Colors.green,
        automaticallyImplyLeading: false,
      ),
      body: PageView(
        children: [
          _languagePage(),
          const _InfoPage(
            title: "No Intermediaries",
            description: "Direct farmer to customer connection",
            icon: Icons.agriculture,
          ),
          const _InfoPage(
            title: "Fast Delivery",
            description: "Fresh products delivered quickly",
            icon: Icons.delivery_dining,
          ),
        ],
      ),
    );
  }

  // 🌍 LANGUAGE SELECTION PAGE
  Widget _languagePage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.language, size: 100, color: Colors.green),
            const SizedBox(height: 20),

            const Text(
              "Change Language",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),
            const Text(
              "Use the app in Tamil, English & Hindi",
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 30),

            RadioListTile<String>(
              value: 'en',
              groupValue: _selectedLanguage,
              title: const Text("English"),
              onChanged: (value) {
                setState(() => _selectedLanguage = value!);
              },
            ),

            RadioListTile<String>(
              value: 'ta',
              groupValue: _selectedLanguage,
              title: const Text("தமிழ் (Tamil)"),
              onChanged: (value) {
                setState(() => _selectedLanguage = value!);
              },
            ),

            RadioListTile<String>(
              value: 'hi',
              groupValue: _selectedLanguage,
              title: const Text("हिंदी (Hindi)"),
              onChanged: (value) {
                setState(() => _selectedLanguage = value!);
              },
            ),

            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: () async {
                // 💾 Save selected language
                await LanguageService.saveLanguage(_selectedLanguage);

                // ➡️ Go to role selection
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const RoleSelectionScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding:
                const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
              ),
              child: const Text("Continue"),
            ),
          ],
        ),
      ),
    );
  }
}

// ℹ️ INFO PAGES (UNCHANGED)
class _InfoPage extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;

  const _InfoPage({
    required this.title,
    required this.description,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 100, color: Colors.green),
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(description, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

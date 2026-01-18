import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/language_provider.dart';
import '../core/utils/app_strings.dart';

class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          // ✅ FIXED: key first, language second
          AppStrings.text('change_language', langProvider.language),
        ),
        backgroundColor: Colors.green,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          RadioListTile<String>(
            value: AppStrings.english,
            groupValue: langProvider.language,
            title: const Text('English'),
            onChanged: (v) => langProvider.changeLanguage(v!),
          ),
          RadioListTile<String>(
            value: AppStrings.tamil,
            groupValue: langProvider.language,
            title: const Text('தமிழ் (Tamil)'),
            onChanged: (v) => langProvider.changeLanguage(v!),
          ),
          RadioListTile<String>(
            value: AppStrings.hindi,
            groupValue: langProvider.language,
            title: const Text('हिंदी (Hindi)'),
            onChanged: (v) => langProvider.changeLanguage(v!),
          ),
        ],
      ),
    );
  }
}

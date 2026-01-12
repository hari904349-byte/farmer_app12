import 'package:flutter/material.dart';

class FarmerHome extends StatelessWidget {
  const FarmerHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Farmer Dashboard")),
      body: const Center(
        child: Text("Welcome Farmer 👨‍🌾", style: TextStyle(fontSize: 22)),
      ),
    );
  }
}

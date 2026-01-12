import 'package:flutter/material.dart';

class OffersDiscount extends StatelessWidget {
  const OffersDiscount({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Offers & Discount"),
        backgroundColor: Colors.green,
      ),
      body: const Center(
        child: Text(
          "Offers & Discount Screen",
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}

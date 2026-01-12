import 'package:flutter/material.dart';

class ShowRating extends StatelessWidget {
  const ShowRating({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Customer Ratings"),
        backgroundColor: Colors.green,
      ),
      body: const Center(
        child: Text("⭐ 4.5 / 5\nCustomer Feedback"),
      ),
    );
  }
}

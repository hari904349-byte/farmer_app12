import 'package:flutter/material.dart';

class SalesRevenue extends StatelessWidget {
  const SalesRevenue({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sales & Revenue"),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: const [
            Card(
              child: ListTile(
                title: Text("Total Sales"),
                trailing: Text("15"),
              ),
            ),
            Card(
              child: ListTile(
                title: Text("Total Revenue"),
                trailing: Text("₹12,500"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

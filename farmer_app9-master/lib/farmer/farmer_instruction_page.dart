import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'farmer_dashboard.dart';

class FarmerInstructionPage extends StatefulWidget {
  const FarmerInstructionPage({super.key});

  @override
  State<FarmerInstructionPage> createState() =>
      _FarmerInstructionPageState();
}

class _FarmerInstructionPageState
    extends State<FarmerInstructionPage> {

  late PageController _controller;
  int currentPage = 0;

  final List<String> images = [
    "assets/instructions/upload_product.png",
    "assets/instructions/manage_orders.png",
    "assets/instructions/set_offer.png",
    "assets/instructions/earnings.png",
    "assets/instructions/view_ratings.png",
  ];

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finishInstructions() async {
    final user = Supabase.instance.client.auth.currentUser;

    if (user != null) {
      await Supabase.instance.client
          .from('profiles')
          .update({'has_seen_instruction': true})
          .eq('id', user.id);
    }

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const FarmerDashboard(),
      ),
    );
  }

  void _nextPage() {
    if (currentPage < images.length - 1) {
      _controller.animateToPage(
        currentPage + 1,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _finishInstructions();
    }
  }

  void _skip() {
    _finishInstructions();
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = currentPage == images.length - 1;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [

            /// 🔹 SKIP BUTTON (TOP RIGHT)
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _skip,
                child: const Text(
                  "Skip",
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 16,
                  ),
                ),
              ),
            ),

            /// 🔹 SLIDING IMAGES
            Expanded(
              child: PageView.builder(
                controller: _controller,
                physics: const BouncingScrollPhysics(),
                itemCount: images.length,
                onPageChanged: (index) {
                  setState(() {
                    currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOut,
                    padding: const EdgeInsets.all(20),
                    child: Image.asset(
                      images[index],
                      fit: BoxFit.contain,
                    ),
                  );
                },
              ),
            ),

            /// 🔹 DOT INDICATOR
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                images.length,
                    (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  width: currentPage == index ? 14 : 8,
                  height: currentPage == index ? 14 : 8,
                  decoration: BoxDecoration(
                    color: currentPage == index
                        ? Colors.green
                        : Colors.grey.shade400,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 25),

            /// 🔹 NEXT / GOT IT BUTTON
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: _nextPage,
                  child: Text(
                    isLastPage ? "Got It" : "Next",
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 25),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// REGISTER SCREENS
import 'register_customer.dart';
import 'register_farmer.dart';
import 'register_delivery.dart';

class LoginScreen extends StatefulWidget {
  final String role; // customer / farmer / delivery

  const LoginScreen({super.key, required this.role});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool loading = false;
  bool hidePassword = true; // 👁️ NEW

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(), // 🔽 dismiss keyboard
      child: Scaffold(
        appBar: AppBar(
          title: Text("Login - ${widget.role.toUpperCase()}"),
          backgroundColor: Colors.green,
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.account_circle, size: 90, color: Colors.green),
              const SizedBox(height: 20),

              Text(
                "Welcome ${widget.role}",
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 30),

              // EMAIL
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: "Email",
                  prefixIcon: const Icon(Icons.email),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              const SizedBox(height: 15),

              // PASSWORD
              TextField(
                controller: passwordController,
                obscureText: hidePassword,
                decoration: InputDecoration(
                  labelText: "Password",
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      hidePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() => hidePassword = !hidePassword);
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              const SizedBox(height: 25),

              // LOGIN BUTTON
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  onPressed: loading ? null : _login,
                  child: loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Login",
                      style: TextStyle(fontSize: 18)),
                ),
              ),

              const SizedBox(height: 15),

              // REGISTER
              TextButton(
                onPressed: _goToRegister,
                child: const Text("New user? Register here"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= LOGIN FUNCTION =================

  Future<void> _login() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    // 🔐 BASIC VALIDATION (NEW)
    if (email.isEmpty || password.isEmpty) {
      _showError("Email and password are required");
      return;
    }

    if (!email.contains('@')) {
      _showError("Enter a valid email");
      return;
    }

    if (password.length < 6) {
      _showError("Password must be at least 6 characters");
      return;
    }

    setState(() => loading = true);

    try {
      // SUPABASE LOGIN (UNCHANGED)
      final response =
      await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final user = response.user;
      if (user == null) {
        _showError("Invalid login credentials");
        return;
      }

      // FETCH ROLE
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .single();

      if (profile['role'] != widget.role) {
        _showError("You are not registered as ${widget.role}");
        return;
      }

      // DASHBOARD NAVIGATION (UNCHANGED)
      Navigator.pushReplacementNamed(
        context,
        '/${widget.role}_dashboard',
      );
    } on AuthException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError("Login failed");
    } finally {
      setState(() => loading = false);
    }
  }

  // ================= REGISTER NAVIGATION =================

  void _goToRegister() {
    if (widget.role == 'customer') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => RegisterCustomer()),
      );
    } else if (widget.role == 'farmer') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const RegisterFarmer()),
      );
    } else if (widget.role == 'delivery') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const RegisterDelivery()),
      );
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';

import '../core/language_provider.dart';
import '../core/utils/app_strings.dart';

import 'register_customer.dart';
import 'register_farmer.dart';
import 'register_delivery.dart';
import 'forgot_password_page.dart';

class LoginScreen extends StatefulWidget {
  final String role;

  const LoginScreen({super.key, required this.role});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final supabase = Supabase.instance.client;

  final loginController = TextEditingController();
  final passwordController = TextEditingController();

  bool loading = false;
  bool hidePassword = true;

  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            '${AppStrings.text('login', langProvider.language)} - ${widget.role.toUpperCase()}',
          ),
          backgroundColor: Colors.green,
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.account_circle,
                  size: 90, color: Colors.green),

              const SizedBox(height: 10),

              Text(
                AppStrings.text(
                  widget.role == 'customer'
                      ? 'welcome_customer'
                      : 'welcome_farmer',
                  langProvider.language,
                ),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 30),

              // EMAIL
              TextField(
                controller: loginController,
                decoration: InputDecoration(
                  labelText:
                  AppStrings.text('email', langProvider.language),
                  prefixIcon: const Icon(Icons.person),
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
                  labelText:
                  AppStrings.text('password', langProvider.language),
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      hidePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () =>
                        setState(() => hidePassword = !hidePassword),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              // ✅ FORGOT PASSWORD (FIXED)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ForgotPasswordPage(),
                      ),
                    );
                  },
                  child: Text(
                    AppStrings.text(
                        'forgot_password', langProvider.language),
                  ),
                ),
              ),

              const SizedBox(height: 10),

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
                      : Text(
                    AppStrings.text('login', langProvider.language),
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ),

              const SizedBox(height: 15),

              // ✅ NEW USER REGISTER (FIXED)
              TextButton(
                onPressed: _goToRegister,
                child: Text(
                  AppStrings.text(
                      'register', langProvider.language),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= LOGIN LOGIC =================
  Future<void> _login() async {
    final input = loginController.text.trim().replaceAll(' ', '');
    final password = passwordController.text.trim();

    if (input.isEmpty || password.isEmpty) {
      _show("All fields are required");
      return;
    }

    setState(() => loading = true);

    try {
      String email;

      if (input.contains('@')) {
        email = input;
      } else {
        String mobile = input.startsWith('+91')
            ? input.substring(3)
            : input;

        final profile = await supabase
            .from('profiles')
            .select('email')
            .eq('mobile', mobile)
            .maybeSingle();

        if (profile == null) {
          _show("Mobile number not registered");
          return;
        }

        email = profile['email'];
      }

      await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final user = supabase.auth.currentUser!;
      final roleData = await supabase
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .single();

      if (roleData['role'] != widget.role) {
        _show("You are not registered as ${widget.role}");
        return;
      }

      Navigator.pushReplacementNamed(
        context,
        '/${widget.role}_dashboard',
      );
    } on AuthException catch (e) {
      _show(e.message);
    } catch (e) {
      _show("Login failed");
    } finally {
      setState(() => loading = false);
    }
  }

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
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const RegisterDelivery()),
      );
    }
  }

  void _show(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }
}

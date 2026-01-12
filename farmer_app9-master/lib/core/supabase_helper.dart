import 'package:supabase_flutter/supabase_flutter.dart';

// ✅ SINGLE SUPABASE INSTANCE (GLOBAL & SAFE)
final SupabaseClient supabase = Supabase.instance.client;

class SupabaseHelper {

  // ================= AUTH =================

  // 🔐 SIGN UP
  static Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    return await supabase.auth.signUp(
      email: email,
      password: password,
    );
  }

  // 🔐 SIGN IN
  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // 🚪 SIGN OUT
  static Future<void> signOut() async {
    await supabase.auth.signOut();
  }

  // ================= PROFILES =================

  // 👤 INSERT PROFILE
  static Future<void> insertProfile(Map<String, dynamic> data) async {
    await supabase.from('profiles').insert(data);
  }

  // 👤 GET USER ROLE
  static Future<String> getUserRole(String userId) async {
    final res = await supabase
        .from('profiles')
        .select('role')
        .eq('id', userId)
        .single();

    return res['role'];
  }

  // 👤 GET FULL PROFILE (OPTIONAL)
  static Future<Map<String, dynamic>> getProfile(String userId) async {
    return await supabase
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();
  }
}

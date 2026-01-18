class AppStrings {
  // Language codes
  static const String english = 'en';
  static const String tamil = 'ta';
  static const String hindi = 'hi';

  // All translations
  static const Map<String, Map<String, String>> _values = {
    // ================= ENGLISH =================
    english: {
      'login': 'Login',
      'logout': 'Logout',
      'welcome_customer': 'Welcome Customer',
      'welcome_farmer': 'Welcome Farmer',
      'email': 'Email or phone number',
      'password': 'Password',
      'continue': 'Continue',
      'change_language': 'Change Language',
      'browse_products': 'Browse Products',
      'my_cart': 'My Cart',
      'my_orders': 'My Orders',

      // ✅ ADDED (FIXES YOUR BUG)
      'forgot_password': 'Forgot Password?',
      'register': 'New user? Register here',
    },

    // ================= TAMIL =================
    tamil: {
      'login': 'உள்நுழை',
      'logout': 'வெளியேறு',
      'welcome_customer': 'வாடிக்கையாளரை வரவேற்கிறோம்',
      'welcome_farmer': 'விவசாயியை வரவேற்கிறோம்',
      'email': 'மின்னஞ்சல்',
      'password': 'கடவுச்சொல்',
      'continue': 'தொடரவும்',
      'change_language': 'மொழியை மாற்று',
      'browse_products': 'பொருட்களை பார்க்க',
      'my_cart': 'என் வண்டி',
      'my_orders': 'என் ஆர்டர்கள்',

      // ✅ ADDED
      'forgot_password': 'கடவுச்சொல் மறந்துவிட்டீர்களா?',
      'register': 'புதிய பயனர்? பதிவு செய்யவும்',
    },

    // ================= HINDI =================
    hindi: {
      'login': 'लॉगिन',
      'logout': 'लॉगआउट',
      'welcome_customer': 'ग्राहक का स्वागत है',
      'welcome_farmer': 'किसान का स्वागत है',
      'email': 'ईमेल',
      'password': 'पासवर्ड',
      'continue': 'जारी रखें',
      'change_language': 'भाषा बदलें',
      'browse_products': 'उत्पाद देखें',
      'my_cart': 'मेरी कार्ट',
      'my_orders': 'मेरे ऑर्डर',

      // ✅ ADDED
      'forgot_password': 'पासवर्ड भूल गए?',
      'register': 'नया उपयोगकर्ता? पंजीकरण करें',
    },
  };

  /// Get translated text safely
  static String text(String key, String lang) {
    final languageMap = _values[lang] ?? _values[english]!;
    return languageMap[key] ?? key;
  }
}

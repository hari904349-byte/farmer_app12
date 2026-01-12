class AppStrings {
  static const Map<String, Map<String, String>> _values = {
    'en': {
      'login': 'Login',
      'logout': 'Logout',
      'welcome_customer': 'Welcome Customer',
      'welcome_farmer': 'Welcome Farmer',
      'email': 'Email',
      'password': 'Password',
      'continue': 'Continue',
      'change_language': 'Change Language',
      'browse_products': 'Browse Products',
      'my_cart': 'My Cart',
      'my_orders': 'My Orders',
    },

    'ta': {
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
    },

    'hi': {
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
    },
  };

  static String text(String lang, String key) {
    return _values[lang]?[key] ?? key;
  }
}

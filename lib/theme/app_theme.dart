import 'package:flutter/material.dart';

class AppTheme {
  // Cores Next style - Preto e Verde
  static const Color primaryColor = Color(0xFF00FF6A); // Verde Next
  static const Color primaryDark = Color(0xFF00CC55);  // Verde escuro
  static const Color secondaryColor = Color(0xFF1A1A1A); // Preto secundário
  static const Color accentColor = Color(0xFF00FF6A);
  
  static const Color textPrimary = Color(0xFF000000);
  static const Color textSecondary = Color(0xFF666666);
  static const Color textLight = Color(0xFFFFFFFF);
  
  static const Color backgroundLight = Color(0xFFF5F5F5);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  
  static const Color backgroundDark = Color(0xFF000000);
  static const Color surfaceDark = Color(0xFF1A1A1A);
  
  static const Color successColor = Color(0xFF00FF6A);
  static const Color errorColor = Color(0xFFFF3B30);
  static const Color warningColor = Color(0xFFFFCC00);
  static const Color infoColor = Color(0xFF00FF6A);
  
  static Color withCustomOpacity(Color color, double opacity) {
    return color.withOpacity(opacity);
  }
  
  // Tema claro (estilo Next - fundo branco/cinza claro com verde)
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: primaryColor,
    colorScheme: ColorScheme.light(
      primary: primaryColor,
      primaryContainer: primaryDark,
      secondary: secondaryColor,
      surface: surfaceLight,
      error: errorColor,
      onPrimary: Colors.black,
      onSecondary: Colors.white,
      onSurface: textPrimary,
      onError: Colors.white,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: backgroundLight,
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF000000),
      foregroundColor: Color(0xFF00FF6A),
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: Color(0xFF00FF6A),
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      color: surfaceLight,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.all(8),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceLight,
      labelStyle: const TextStyle(color: Color(0xFF666666)),
      hintStyle: const TextStyle(color: Color(0xFF999999)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF00FF6A), width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF00FF6A),
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFF00FF6A),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    iconTheme: const IconThemeData(color: Color(0xFF00FF6A)),
    dividerColor: const Color(0xFFEEEEEE),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: primaryColor,
      foregroundColor: Colors.black,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.black,
      selectedItemColor: Color(0xFF00FF6A),
      unselectedItemColor: Color(0xFF666666),
      type: BottomNavigationBarType.fixed,
    ),
    shadowColor: const Color.fromRGBO(0, 0, 0, 0.1),
  );
  
  // Tema escuro (estilo Next puro - preto com verde)
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: primaryColor,
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF00FF6A),
      secondary: Color(0xFF1A1A1A),
      surface: Color(0xFF1A1A1A),
      error: Color(0xFFFF3B30),
      onPrimary: Colors.black,
      onSecondary: Colors.white,
      onSurface: Colors.white,
      onError: Colors.white,
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: Colors.black,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.black,
      foregroundColor: Color(0xFF00FF6A),
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: Color(0xFF00FF6A),
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      color: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.all(8),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF1A1A1A),
      labelStyle: const TextStyle(color: Color(0xFF888888)),
      hintStyle: const TextStyle(color: Color(0xFF555555)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF333333)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF333333)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF00FF6A), width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF00FF6A),
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFF00FF6A),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    iconTheme: const IconThemeData(color: Color(0xFF00FF6A)),
    dividerColor: const Color(0xFF333333),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: primaryColor,
      foregroundColor: Colors.black,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.black,
      selectedItemColor: Color(0xFF00FF6A),
      unselectedItemColor: Color(0xFF555555),
      type: BottomNavigationBarType.fixed,
    ),
  );

  static const BorderRadius borderRadius = BorderRadius.all(Radius.circular(12));
  static const BorderRadius borderRadiusSmall = BorderRadius.all(Radius.circular(8));
  static const BorderRadius borderRadiusLarge = BorderRadius.all(Radius.circular(16));
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 48.0;

  static Color withOpacity(Color color, double opacity) => color.withOpacity(opacity);
  static const List<BoxShadow> cardShadow = [
    BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.1), blurRadius: 10, offset: Offset(0, 4)),
  ];
}

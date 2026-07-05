import 'package:flutter/material.dart';

// VitaPulse brand colors — derived from logo new.png (vibrant health green + warm gold)
const kPrimary   = Color(0xFF1B5E20); // deep forest green
const kPrimaryMid= Color(0xFF2E7D32); // medium green
const kAccent    = Color(0xFFFFB300); // amber gold
const kAccent2   = Color(0xFF43A047); // bright green
const kBg        = Color(0xFFF1F8F1); // very light green tint
const kCard      = Colors.white;
const kTextDark  = Color(0xFF1B2A1B);
const kTextGrey  = Color(0xFF6B7280);
const kSuccess   = Color(0xFF22C55E);
const kError     = Color(0xFFEF4444);
const kWarning   = Color(0xFFF59E0B);

ThemeData appTheme() => ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: kPrimary,
    primary: kPrimary,
    secondary: kAccent,
    surface: kCard,
  ),
  scaffoldBackgroundColor: kBg,
  fontFamily: 'Roboto',
  appBarTheme: const AppBarTheme(
    backgroundColor: kPrimary,
    foregroundColor: Colors.white,
    elevation: 0,
    centerTitle: false,
  ),
  navigationBarTheme: NavigationBarThemeData(
    backgroundColor: kCard,
    indicatorColor: kAccent2.withOpacity(0.18),
    labelTextStyle: WidgetStateProperty.all(
      const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: kPrimary),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: kPrimary,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFFF6FBF6),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCDE8CD))),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCDE8CD))),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kAccent2, width: 2)),
    labelStyle: const TextStyle(color: kTextGrey),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
  ),
);

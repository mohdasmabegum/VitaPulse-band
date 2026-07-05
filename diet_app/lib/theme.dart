import 'package:flutter/material.dart';

const kPrimary    = Color(0xFF0A1628);
const kPrimaryMid = Color(0xFF1A3A5C);
const kAccent     = Color(0xFFC8A96E);
const kAccent2    = Color(0xFF1A3A5C);
const kBg         = Color(0xFFF4F6FA);
const kCard       = Colors.white;
const kTextDark   = Color(0xFF0A1628);
const kTextGrey   = Color(0xFF6B7280);
const kSuccess    = Color(0xFF22C55E);
const kError      = Color(0xFFEF4444);
const kWarning    = Color(0xFFF59E0B);

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
    indicatorColor: kAccent.withOpacity(0.2),
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
    fillColor: const Color(0xFFF8F9FC),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kAccent, width: 2)),
    labelStyle: const TextStyle(color: kTextGrey),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
  ),
);

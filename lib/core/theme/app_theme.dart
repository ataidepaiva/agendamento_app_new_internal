import 'package:flutter/material.dart';

final ThemeData appTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF005A9C), // Azul corporativo
    brightness: Brightness.light,
    primary: const Color(0xFF005A9C),
    secondary: const Color(0xFF003D6B),
    surface: Colors.white,
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onSurface: const Color(0xFF333333), // Cinza escuro para texto
  ),
  scaffoldBackgroundColor: const Color(0xFFF5F5F5), // Cinza claro para o fundo
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF005A9C),
    elevation: 2,
    centerTitle: true,
    titleTextStyle: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      color: Colors.white,
    ),
    iconTheme: IconThemeData(color: Colors.white),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    labelStyle: const TextStyle(color: Color(0xFF005A9C)),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(
        color: Color(0xFFCCCCCC),
      ), // Cinza para bordas
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFFCCCCCC)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFF005A9C), width: 2),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF005A9C),
      padding: const EdgeInsets.symmetric(vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 2,
      textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      side: const BorderSide(color: Color(0xFF005A9C)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      foregroundColor: const Color(0xFF005A9C),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: const Color(0xFF005A9C), // Use primary color for text buttons
      textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
    ),
  ),
  bottomNavigationBarTheme: BottomNavigationBarThemeData(
    backgroundColor: const Color(0xFF003D6B), // Azul escuro corporativo
    selectedItemColor: Colors.amber,
    unselectedItemColor: Colors.white, // Itens não selecionados brancos
    type: BottomNavigationBarType.fixed, // Ensure all items are visible
    selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber),
    unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal, color: Colors.white),
  ),
  textTheme: const TextTheme(
    headlineSmall: TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 18,
      color: Color(0xFF333333),
    ),
    titleMedium: TextStyle(fontSize: 16, color: Color(0xFF333333)),
    bodyMedium: TextStyle(fontSize: 15, color: Color(0xFF333333)),
  ),
  cardTheme: CardThemeData(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    elevation: 1,
    shadowColor: Colors.grey.shade200,
    margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
  ),
  iconTheme: const IconThemeData(color: Color(0xFF005A9C)),
);

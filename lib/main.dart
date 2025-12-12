import 'package:flutter/material.dart';
import 'package:keutech/screens/splash_screen.dart';
import 'package:keutech/screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'KeuTech',
      theme: ThemeData(
        fontFamily: 'Poppins',
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFB79CFF)),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

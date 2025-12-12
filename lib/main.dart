import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; 
// Import semua halaman dari folder screens
import 'screens/home_screen.dart'; 
import 'screens/login_screen.dart'; 
import 'screens/register_screen.dart'; 

// URL dan Kunci Supabase Anda (Koreksi untuk penggunaan langsung tanpa String.fromEnvironment)
const supabaseUrl = 'https://cqiybwmeovopbsilkclc.supabase.co';
const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNxaXlid21lb3ZvcGJzaWxrY2xjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjU1MDk0OTMsImV4cCI6MjA4MTA4NTQ5M30.Bzz1QWrkeJZlmv9QoRQ8hE8L8ecXdA9j3SrASTfrG9s';


Future<void> main() async { 
  // 1. Wajib dilakukan sebelum memanggil Supabase.initialize
  WidgetsFlutterBinding.ensureInitialized(); 

  // 2. INISIALISASI SUPABASE dengan key yang valid
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );
  
  runApp(const AccountingApp());
}

class AccountingApp extends StatelessWidget {
  const AccountingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Accounting App',
      theme: ThemeData(
        // FONT POPPINS diterapkan di seluruh aplikasi
        fontFamily: 'Poppins',
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFB79CFF)),
        useMaterial3: true,
      ),
      
      // Definisikan Route awal aplikasi
      initialRoute: '/login', 
      
      // Definisikan semua Route yang akan digunakan
      routes: {
        // Halaman Login (Halaman awal)
        '/login': (context) => const LoginScreen(), 
        
        // Halaman Register
        '/register': (context) => const RegisterScreen(), 
        
        // Halaman Home (Setelah Login Sukses)
        '/home': (context) => const HomeScreen(), 
      },
    );
  }
}
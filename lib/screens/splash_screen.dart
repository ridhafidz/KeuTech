import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:keutech/screens/login_screen.dart'; // Pastikan import ini benar
import 'package:keutech/screens/home_screen.dart'; // Pastikan import ini benar

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController drop;
  late AnimationController expand;
  late AnimationController logoAnim;

  late Animation<double> dropY;
  late Animation<double> circleSize;
  late Animation<double> logoOpacity;
  late Animation<double> logoSlide;

  @override
  void initState() {
    super.initState();

    // 1. Animasi Jatuh
    drop = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    dropY = Tween<double>(begin: -300, end: 0).animate(
      CurvedAnimation(parent: drop, curve: Curves.bounceOut),
    );

    // 2. Animasi Melebar
    expand = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // 3. Animasi Logo
    logoAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    logoOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: logoAnim, curve: Curves.easeIn),
    );

    logoSlide = Tween<double>(begin: 30, end: 0).animate(
      CurvedAnimation(parent: logoAnim, curve: Curves.easeOut),
    );

    // --- URUTAN LOGIKA ANIMASI & NAVIGASI ---

    // Mulai Jatuh
    drop.forward();

    // Selesai Jatuh -> Mulai Melebar
    drop.addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) expand.forward();
        });
      }
    });

    // Selesai Melebar -> Mulai Logo
    expand.addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        logoAnim.forward();
      }
    });

    // Selesai Logo -> Tunggu sebentar -> PINDAH HALAMAN
    logoAnim.addStatusListener((s) async {
      if (s == AnimationStatus.completed) {
        // Tahan selama 2 detik agar logo terbaca user
        await Future.delayed(const Duration(seconds: 2));

        if (!mounted) return;

        // Cek Status Login Supabase
        final session = Supabase.instance.client.auth.currentSession;

        // if (session != null) {
        //   // Jika sudah login, langsung ke Home
        //   Navigator.pushReplacement(
        //     context,
        //     MaterialPageRoute(builder: (_) => const HomeScreen()),
        //   );
        // } else {
        // Jika belum login, ke Login Screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
        // }
      }
    });
  }

  @override
  void dispose() {
    drop.dispose();
    expand.dispose();
    logoAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double finalSize = size.height * 2.5;

    circleSize = Tween<double>(begin: 80, end: finalSize).animate(
      CurvedAnimation(parent: expand, curve: Curves.easeInOut),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: AnimatedBuilder(
        animation: Listenable.merge([drop, expand, logoAnim]),
        builder: (_, __) {
          return Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                top: (size.height / 2) - (circleSize.value / 2) + dropY.value,
                child: Container(
                  width: circleSize.value,
                  height: circleSize.value,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFBAB5F7),
                        Color(0xFF9B94F3),
                      ],
                    ),
                  ),
                ),
              ),
              FadeTransition(
                opacity: logoOpacity,
                child: Transform.translate(
                  offset: Offset(0, logoSlide.value),
                  child: Center(
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 150,
                      height: 150,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.account_balance_wallet,
                          size: 100,
                          color: Colors.white,
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

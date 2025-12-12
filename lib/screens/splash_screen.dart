import 'package:flutter/material.dart';
import 'dart:async';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {

  late AnimationController dropController;
  late AnimationController expandController;
  late AnimationController logoController;
  late AnimationController typingController;

  late Animation<double> dropAnimation;
  late Animation<double> expandAnimation;
  late Animation<double> logoSlideAnimation;
  String typedText = "";
  final String fullText = "Solusi Akuntansi Digitalmu";

  @override
  void initState() {
    super.initState();

    // ---------------------------------------------
    // 1. DROP ANIMATION (lingkaran jatuh bounce)
    // ---------------------------------------------
    dropController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    dropAnimation = Tween<double>(begin: -150, end: 0).animate(
      CurvedAnimation(
        parent: dropController,
        curve: Curves.bounceOut,
      ),
    );

    dropController.forward();

    // ---------------------------------------------
    // 2. EXPAND ANIMATION (lingkaran membesar)
    // ---------------------------------------------
    expandController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    expandAnimation = Tween<double>(begin: 120, end: 2000).animate(
      CurvedAnimation(
        parent: expandController,
        curve: Curves.easeInOut,
      ),
    );

    // Start expand after circle lands
    dropController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        expandController.forward();
      }
    });

    // ---------------------------------------------
    // 3. LOGO ANIMATION (fade + geser ke kiri)
    // ---------------------------------------------
    logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    logoSlideAnimation = Tween<double>(begin: 0, end: -20).animate(
      CurvedAnimation(parent: logoController, curve: Curves.easeOut),
    );

    expandController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        logoController.forward();
      }
    });

    // ---------------------------------------------
    // 4. TYPING ANIMATION
    // ---------------------------------------------
    typingController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: fullText.length * 60),
    );

    logoController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        typingController.forward();
      }
    });

    typingController.addListener(() {
      final count = (fullText.length * typingController.value).floor();
      setState(() {
        typedText = fullText.substring(0, count);
      });
    });
  }

  @override
  void dispose() {
    dropController.dispose();
    expandController.dispose();
    logoController.dispose();
    typingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: AnimatedBuilder(
        animation: Listenable.merge([
          dropController,
          expandController,
          logoController,
          typingController
        ]),
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // -------------------------------
              // EXPANDING CIRCLE BACKGROUND
              // -------------------------------
              Positioned(
                top: MediaQuery.of(context).size.height / 2 + dropAnimation.value,
                child: Container(
                  width: expandAnimation.value,
                  height: expandAnimation.value,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFFBAB5F7),
                        Color(0xFF9B94F3),
                      ],
                    ),
                  ),
                ),
              ),

              // -------------------------------
              // LOGO + TEXT
              // -------------------------------
              Positioned(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Transform.translate(
                      offset: Offset(logoSlideAnimation.value, 0),
                      child: Opacity(
                        opacity: logoController.value,
                        child: Column(
                          children: [
                            // Ganti dengan asset logo kamu
                            Icon(Icons.account_balance_wallet,
                                size: 64, color: Colors.white),
                            const SizedBox(height: 18),
                            Text(
                              "Keutech",
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // TYPING TEXT
                    Text(
                      typedText,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    )
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:medisense_app/services/auth.dart';
import 'package:medisense_app/views/onboarding_screen.dart';
import 'package:medisense_app/views/tabs_screen.dart';

class SplashScreenPage extends StatefulWidget {
  const SplashScreenPage({super.key});

  @override
  State<SplashScreenPage> createState() => _SplashScreenPageState();
}

class _SplashScreenPageState extends State<SplashScreenPage> {

  @override
  void initState() {
    var currentUser = Auth().currentUser;
    Future.delayed(const Duration(seconds: 3)).then((value) {
      if (currentUser != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const TabsScreen())
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const SigninOrSignupScreen()),
        );
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
          child:Image.asset("assets/splash_screen/Medisense.png")
      ),
    );
  }
}

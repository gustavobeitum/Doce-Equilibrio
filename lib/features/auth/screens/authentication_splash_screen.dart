import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:doce_equilibrio/core/theme/app_colors.dart';
import 'package:doce_equilibrio/features/auth/screens/login_screen.dart';
import 'package:doce_equilibrio/features/home/screens/main_screen.dart';

class AuthenticationSplashScreen extends StatefulWidget {
  const AuthenticationSplashScreen({super.key});

  @override
  State<AuthenticationSplashScreen> createState() => _SplashVerificacaoState();
}

class _SplashVerificacaoState extends State<AuthenticationSplashScreen> {
  final _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    final savedId = await _storage.read(key: 'usuario_id');

    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    if (savedId != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.primaryColor,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Doce Equilíbrio',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 24),
            CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}

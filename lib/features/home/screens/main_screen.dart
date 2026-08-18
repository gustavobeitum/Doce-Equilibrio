import 'package:doce_equilibrio/core/theme/app_colors.dart';
import 'package:doce_equilibrio/features/activity/screens/activity_screen.dart';
import 'package:doce_equilibrio/features/meals/screens/meals_screen.dart';
import 'package:doce_equilibrio/features/insulin/screens/insulin_calculator_screen.dart';
import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:doce_equilibrio/features/home/screens/home_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  void _irParaAbaInsulina() {
    setState(() => _currentIndex = 1);
  }

  @override
  Widget build(BuildContext context) {
    final telas = [
      HomeScreen(onNavegarParaInsulina: _irParaAbaInsulina),
      const InsulinCalculatorScreen(),
      const MealsScreen(),
      const ActivityScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColors.primaryColor,

      body: SafeArea(
        child: Container(
          color: Colors.white,
          child: IndexedStack(index: _currentIndex, children: telas),
        ),
      ),

      bottomNavigationBar: SafeArea(
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.primaryColor,
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: true,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.normal,
            fontSize: 12,
          ),
          elevation: 10,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(PhosphorIcons.house),
              activeIcon: Icon(PhosphorIcons.houseFill),
              label: 'Início',
            ),
            BottomNavigationBarItem(
              icon: Icon(PhosphorIcons.drop),
              activeIcon: Icon(PhosphorIcons.dropFill),
              label: 'Insulina',
            ),
            BottomNavigationBarItem(
              icon: Icon(PhosphorIcons.forkKnife),
              activeIcon: Icon(PhosphorIcons.forkKnifeFill),
              label: 'Alimentos',
            ),
            BottomNavigationBarItem(
              icon: Icon(PhosphorIcons.heartbeat),
              activeIcon: Icon(PhosphorIcons.heartbeatFill),
              label: 'Atividade',
            ),
          ],
        ),
      ),
    );
  }
}

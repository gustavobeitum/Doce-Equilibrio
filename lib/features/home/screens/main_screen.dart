import 'package:doce_equilibrio/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:doce_equilibrio/features/home/screens/home_screen.dart'; 

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _telas = [
    const HomeScreen(), 
    const Center(child: Text('Tela Insulina em construção', style: TextStyle(color: Colors.black))),
    const Center(child: Text('Tela Alimentos em construção', style: TextStyle(color: Colors.black))),
    const Center(child: Text('Tela Atividade em construção', style: TextStyle(color: Colors.black))),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryColor,
      
      body: SafeArea(
        child: Container(
          color: Colors.white,
          child: IndexedStack(
            index: _currentIndex,
            children: _telas,
          ),
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
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 12),
          elevation: 10, 
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Início',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.water_drop_outlined),
              activeIcon: Icon(Icons.water_drop),
              label: 'Insulina',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.restaurant_outlined),
              activeIcon: Icon(Icons.restaurant),
              label: 'Alimentos',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.monitor_heart_outlined), 
              activeIcon: Icon(Icons.monitor_heart),
              label: 'Atividade',
            ),
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';

void main() {
  runApp(const DoceEquilibrioApp());
}

class DoceEquilibrioApp extends StatelessWidget {
  const DoceEquilibrioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Doce Equilíbrio',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const Scaffold(
        body: Center(child: Text('Setup Inicial Concluído!')),
      ),
    );
  }
}

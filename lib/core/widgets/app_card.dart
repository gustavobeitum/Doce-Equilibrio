import 'package:flutter/material.dart';

/// Card padrão do app: fundo branco, cantos arredondados e sombra suave.
/// Usa o mesmo visual dos cards da Home (`HomeDashboardSection`), para que
/// as telas do sistema fiquem consistentes entre si em vez de usar o
/// `Card` padrão do Flutter (que tem elevação/cor diferentes).
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
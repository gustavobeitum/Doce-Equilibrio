import 'package:flutter/material.dart';

/// Estado vazio padrão do app: ícone apagado + mensagem centralizada.
/// Usado quando uma lista (refeições, atividades, aplicações de
/// insulina, etc.) ainda não tem nenhum registro, ou quando algo deu
/// errado ao carregar (com [action] para uma ação de recuperação, como
/// "Tentar novamente").
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: compact ? 24 : 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: compact ? 36 : 48, color: Colors.grey.shade300),
          SizedBox(height: compact ? 8 : 12),
          Text(
            subtitle == null ? title : '$title\n$subtitle',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600),
          ),
          if (action != null) ...[
            const SizedBox(height: 16),
            action!,
          ],
        ],
      ),
    );
  }
}
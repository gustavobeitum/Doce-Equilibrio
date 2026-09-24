import 'dart:async';

import 'package:doce_equilibrio/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

enum _AppSnackbarType { success, error, warning }

/// Mensagem flutuante padronizada do app (sucesso / erro / aviso).
///
/// Diferente do `SnackBar` padrão do Flutter (que fica preso ao
/// `Scaffold` de baixo e some atrás de modais/diálogos abertos), esta
/// usa o [Overlay] raiz — por isso sempre aparece por cima de tudo,
/// inclusive com um modal aberto na tela.
class AppSnackbar {
  AppSnackbar._();

  static OverlayEntry? _current;
  static Timer? _timer;

  /// Mensagem de sucesso (verde), ex.: "Registro salvo com sucesso.".
  static void showSuccess(BuildContext context, String message) =>
      _show(context, message, _AppSnackbarType.success);

  /// Mensagem de erro (vermelho), ex.: "Não foi possível salvar.".
  static void showError(BuildContext context, String message) =>
      _show(context, message, _AppSnackbarType.error);

  /// Aviso/validação (âmbar), ex.: "Preencha os campos obrigatórios.".
  static void showWarning(BuildContext context, String message) =>
      _show(context, message, _AppSnackbarType.warning);

  static void _show(
    BuildContext context,
    String message,
    _AppSnackbarType type,
  ) {
    _timer?.cancel();
    _current?.remove();
    _current = null;

    final overlay = Overlay.of(context, rootOverlay: true);
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _AppSnackbarView(
        message: message,
        type: type,
        onDismiss: () => _dismissEntry(entry),
      ),
    );
    _current = entry;
    overlay.insert(entry);

    _timer = Timer(const Duration(seconds: 3), () => _dismissEntry(entry));
  }

  static void _dismissEntry(OverlayEntry entry) {
    if (_current != entry) return;
    _timer?.cancel();
    _timer = null;
    entry.remove();
    _current = null;
  }

  /// Remove qualquer mensagem visível e cancela o fechamento automático.
  /// Chame em `tearDown` nos testes de widget que passam por telas onde o
  /// `AppSnackbar` pode aparecer — sem isso, o `Timer` de 3s de auto-fechar
  /// pode ficar pendente e o Flutter acusa erro ao final do teste.
  @visibleForTesting
  static void dismissAll() {
    _timer?.cancel();
    _timer = null;
    _current?.remove();
    _current = null;
  }
}

class _AppSnackbarView extends StatelessWidget {
  const _AppSnackbarView({
    required this.message,
    required this.type,
    required this.onDismiss,
  });

  final String message;
  final _AppSnackbarType type;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final (Color background, IconData icon, Color foreground) = switch (type) {
      _AppSnackbarType.success => (
        AppColors.normalColor,
        PhosphorIcons.checkCircleFill,
        Colors.white,
      ),
      _AppSnackbarType.error => (
        AppColors.dangerColor,
        PhosphorIcons.warningCircleFill,
        Colors.white,
      ),
      _AppSnackbarType.warning => (
        AppColors.warningColor,
        PhosphorIcons.warningFill,
        Colors.black87,
      ),
    };

    final mediaQuery = MediaQuery.of(context);
    final bottomInset = mediaQuery.viewInsets.bottom > 0
        ? mediaQuery.viewInsets.bottom
        : mediaQuery.padding.bottom;

    return Positioned(
      left: 24,
      right: 24,
      bottom: 24 + bottomInset,
      child: _EntranceAnimation(
        child: Material(
          color: Colors.transparent,
          child: GestureDetector(
            onTap: onDismiss,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(icon, color: foreground),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      message,
                      style: TextStyle(
                        color: foreground,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Pequena animação de entrada (fade + leve deslize de baixo pra cima),
/// sem precisar de um `AnimationController` dedicado.
class _EntranceAnimation extends StatelessWidget {
  const _EntranceAnimation({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, (1 - value) * 16),
          child: child,
        ),
      ),
      child: child,
    );
  }
}
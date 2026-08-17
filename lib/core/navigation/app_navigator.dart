import 'package:flutter/material.dart';

/// Chave global do Navigator, usada quando é preciso navegar a partir de
/// um lugar sem `BuildContext` de nenhuma tela — como os callbacks do
/// `NotificationService`, que podem disparar com o app em segundo plano.
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

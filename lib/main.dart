import 'package:doce_equilibrio/core/di/service_locator.dart';
import 'package:doce_equilibrio/core/navigation/app_navigator.dart';
import 'package:doce_equilibrio/core/services/notification_service.dart';
import 'package:doce_equilibrio/features/auth/screens/authentication_splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setupServiceLocator();
  await getIt<NotificationService>().init();
  runApp(const SweetBalanceApp());
}

class SweetBalanceApp extends StatefulWidget {
  const SweetBalanceApp({super.key});

  @override
  State<SweetBalanceApp> createState() => _SweetBalanceAppState();
}

class _SweetBalanceAppState extends State<SweetBalanceApp> {
  @override
  void initState() {
    super.initState();
    // Só depois do primeiro frame o Navigator já está anexado à
    // appNavigatorKey — daí dá pra navegar caso o app tenha sido aberto
    // (inclusive a frio, totalmente fechado) por causa de um alarme.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (getIt.isRegistered<NotificationService>()) {
        getIt<NotificationService>().tratarLancamentoPorNotificacao();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: appNavigatorKey,
      title: 'Doce Equilíbrio',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      // Sem isso, diálogos nativos do Flutter (como os seletores de Data e
      // Hora usados no registro de glicemia) caem no inglês por padrão,
      // independentemente do idioma do aparelho.
      locale: const Locale('pt', 'BR'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('pt', 'BR')],
      home: const AuthenticationSplashScreen(),
    );
  }
}

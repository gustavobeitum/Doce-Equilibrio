import 'package:doce_equilibrio/core/di/service_locator.dart';
import 'package:doce_equilibrio/features/auth/models/user_model.dart';
import 'package:doce_equilibrio/features/glycemia/controllers/glycemia_controller.dart';
import 'package:doce_equilibrio/features/glycemia/models/glycemia_record_model.dart';
import 'package:doce_equilibrio/features/home/controllers/home_controller.dart';
import 'package:doce_equilibrio/features/home/widgets/home_header.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onNavegarParaInsulina;

  const HomeScreen({super.key, required this.onNavegarParaInsulina});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final HomeController _controller;
  late final GlycemiaController _glycemiaController;

  String _saudacao = 'Olá,';
  String _nomeUsuario = 'Carregando...';
  UserModel? _loggedInUser;
  GlycemiaRecordModel? _ultimaLeitura;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = getIt<HomeController>();
    _glycemiaController = getIt<GlycemiaController>();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final saudacaoCalculada = _controller.getGreeting();
    final loggedInUser = await _controller.findLoggedInUser();
    final latestReading = await _glycemiaController.findLatestReading();

    final formattedName = loggedInUser != null
        ? _controller.nameFormatted(loggedInUser.name)
        : '';

    if (!mounted) return;

    setState(() {
      _saudacao = saudacaoCalculada;
      _nomeUsuario = formattedName.isNotEmpty ? formattedName : 'Usuário';
      _loggedInUser = loggedInUser;
      _ultimaLeitura = latestReading;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            HomeHeader(
              saudacao: _saudacao,
              userName: _nomeUsuario,
              latestReading: _ultimaLeitura,
              user: _loggedInUser,
              onAtualizarDados: _loadInitialData,
              onNavegarParaInsulina: widget.onNavegarParaInsulina,
            ),

            const SizedBox(height: 24),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text('Conteúdo abaixo do header...'),
            ),
          ],
        ),
      ),
    );
  }
}

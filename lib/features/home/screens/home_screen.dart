import 'package:doce_equilibrio/features/home/controllers/home_controller.dart';
import 'package:doce_equilibrio/features/home/widgets/home_header.dart';
import 'package:flutter/material.dart';
import 'package:doce_equilibrio/core/database/database_connection.dart';
import 'package:doce_equilibrio/features/auth/repositories/usuario_repository.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final HomeController _controller;

  String _saudacao = 'Olá,';
  String _nomeUsuario = 'Carregando...';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    final repo = UsuarioRepository(DatabaseConnection());
    _controller = HomeController(repo);

    _carregarDadosIniciais();
  }

  Future<void> _carregarDadosIniciais() async {
    final saudacaoCalculada = _controller.getGreeting();

    await Future.delayed(const Duration(milliseconds: 500));

    final nomeBuscadoDoBanco = 'Gustavo Henrique';

    final nomeFormatado = _controller.nameFormatted(nomeBuscadoDoBanco);

    setState(() {
      _saudacao = saudacaoCalculada;
      _nomeUsuario = nomeFormatado;
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
            HomeHeader(saudacao: _saudacao, nomeUsuario: _nomeUsuario),

            const SizedBox(height: 48),

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

import 'package:doce_equilibrio/features/auth/repositories/i_usuario_repository.dart';
import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:doce_equilibrio/core/theme/app_colors.dart';
import 'package:doce_equilibrio/core/widgets/custom_text_field.dart';
import 'package:doce_equilibrio/core/database/database_connection.dart';
import 'package:doce_equilibrio/features/auth/repositories/usuario_repository.dart';
import 'package:doce_equilibrio/features/auth/controllers/cadastro_controller.dart';
import 'package:doce_equilibrio/features/home/screens/home_screen.dart';

class CadastroScreen extends StatefulWidget {
  final IUsuarioRepository? repository;

  const CadastroScreen({super.key, this.repository});

  @override
  State<CadastroScreen> createState() => _CadastroScreenState();
}

class _CadastroScreenState extends State<CadastroScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _anoController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();

  bool _obscureSenha = true;
  bool _obscureConfirmarSenha = true;
  String? _tipoDiabetesSelecionado;
  bool _isLoading = false;

  final List<String> _tiposDiabetes = ['Tipo 1', 'Tipo 2', 'Gestacional'];
  late final CadastroController _controller;

  @override
  void initState() {
    super.initState();
    final repo =
        widget.repository ?? UsuarioRepository(DatabaseConnection());
    _controller = CadastroController(repo);
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _anoController.dispose();
    _senhaController.dispose();
    _confirmarSenhaController.dispose();
    super.dispose();
  }

  Future<void> _realizarCadastro() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final mensagemErro = await _controller.registrar(
        nome: _nomeController.text,
        email: _emailController.text,
        tipoDiabetes: _tipoDiabetesSelecionado!,
        anoDiagnostico: int.parse(_anoController.text),
        senha: _senhaController.text,
      );

      setState(() => _isLoading = false);

      if (mensagemErro == null && mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (Route<dynamic> route) => false,
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(PhosphorIcons.xCircle, color: AppColors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    mensagemErro ?? 'Erro desconhecido.',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.dangerColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            margin: const EdgeInsets.all(24),
            elevation: 6,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryColor,
      appBar: AppBar(
        title: const Text('Criar Conta'),
        leading: IconButton(
          icon: Icon(PhosphorIcons.caretLeft),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Text(
              'Cadastre-se para começar a gerenciar sua diabetes.',
              style: TextStyle(color: AppColors.white, fontSize: 16),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(24.0),
              decoration: const BoxDecoration(
                color: AppColors.backgroundColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Cadastrar Conta',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      CustomTextField(
                        controller: _nomeController,
                        labelText: 'Nome Completo',
                        hintText: 'Seu nome completo',
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'O nome é obrigatório.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _emailController,
                        labelText: 'Email',
                        hintText: 'seu@email.com',
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'O email é obrigatório.';
                          }
                          if (!value.contains('@') || !value.contains('.')) {
                            return 'Por favor, insira um endereço de email válido.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Tipo de Diabetes',
                          filled: true,
                          fillColor: AppColors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.dangerColor,
                              width: 2,
                            ),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.dangerColor,
                              width: 2,
                            ),
                          ),
                        ),
                        value: _tipoDiabetesSelecionado,
                        items: _tiposDiabetes.map((String tipo) {
                          return DropdownMenuItem<String>(
                            value: tipo,
                            child: Text(tipo),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _tipoDiabetesSelecionado = newValue;
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'A seleção do tipo de diabetes é obrigatória.';
                          }
                          return null;
                        },
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _anoController,
                        labelText: 'Ano do Diagnóstico',
                        hintText: 'Ex: 2020',
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'O ano do diagnóstico é obrigatório.';
                          }
                          final ano = int.tryParse(value);
                          if (ano == null) {
                            return 'Por favor, insira apenas números.';
                          }
                          if (ano < 1900) {
                            return 'O ano inserido é muito antigo.';
                          }
                          if (ano > DateTime.now().year) {
                            return 'O ano não pode estar no futuro.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _senhaController,
                        labelText: 'Senha',
                        obscureText: _obscureSenha,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'A senha é obrigatória.';
                          }
                          if (value.length < 8) {
                            return 'A senha deve ter no mínimo 8 caracteres.';
                          }
                          if (!value.contains(RegExp(r'[A-Z]'))) {
                            return 'A senha deve conter ao menos uma letra maiúscula.';
                          }
                          if (!value.contains(RegExp(r'[a-z]'))) {
                            return 'A senha deve conter ao menos uma letra minúscula.';
                          }
                          if (!value.contains(RegExp(r'[0-9]'))) {
                            return 'A senha deve conter ao menos um número.';
                          }
                          if (!value.contains(RegExp(r'[\W_]'))) {
                            return 'A senha deve conter ao menos um caractere especial (!@#\$%^&*).';
                          }
                          return null;
                        },
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureSenha
                                ? PhosphorIcons.eye
                                : PhosphorIcons.eyeClosed,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureSenha = !_obscureSenha;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _confirmarSenhaController,
                        labelText: 'Confirmar Senha',
                        obscureText: _obscureConfirmarSenha,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'A confirmação de senha é obrigatória.';
                          }
                          if (value != _senhaController.text) {
                            return 'As senhas informadas não coincidem. Verifique novamente.';
                          }
                          return null;
                        },
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmarSenha
                                ? PhosphorIcons.eye
                                : PhosphorIcons.eyeClosed,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureConfirmarSenha = !_obscureConfirmarSenha;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _realizarCadastro,
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: AppColors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Cadastrar'),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Já tem uma conta?'),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text(
                              'Entrar',
                              style: TextStyle(
                                color: AppColors.primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

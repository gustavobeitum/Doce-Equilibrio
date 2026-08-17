import 'package:doce_equilibrio/core/utils/color_extensions.dart';
import 'package:doce_equilibrio/features/auth/models/user_model.dart';
import 'package:doce_equilibrio/features/glycemia/models/glycemia_record_model.dart';
import 'package:doce_equilibrio/features/glycemia/widgets/glycemia_record_modal.dart';
import 'package:doce_equilibrio/features/home/widgets/last_reading_card.dart';
import 'package:doce_equilibrio/features/settings/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:doce_equilibrio/core/theme/app_colors.dart';

class HomeHeader extends StatelessWidget {
  final String saudacao;
  final String userName;
  final GlycemiaRecordModel? latestReading;
  final UserModel? user;
  final VoidCallback onAtualizarDados;
  final VoidCallback onNavegarParaInsulina;

  const HomeHeader({
    super.key,
    required this.saudacao,
    required this.userName,
    required this.latestReading,
    required this.user,
    required this.onAtualizarDados,
    required this.onNavegarParaInsulina,
  });

  Future<void> _openGlycemiaRecordModal(BuildContext context) async {
    final saved = await GlycemiaRecordModal.exibir(context);
    if (saved == true) {
      onAtualizarDados();
    }
  }

  Future<void> _openSettings(BuildContext context) async {
    // A Home não sabe o que aconteceu dentro de Configurações — o usuário
    // pode ter registrado ou editado uma glicemia pelo Histórico, por
    // exemplo. Por isso, sempre recarregamos os dados ao voltar de lá.
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
    onAtualizarDados();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          decoration: const BoxDecoration(color: AppColors.primaryColor),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        saudacao,
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      Text(
                        userName,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: () => _openSettings(context),
                      icon: const Icon(
                        PhosphorIcons.gear,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              LastReadingCard(latestReading: latestReading, user: user),

              const SizedBox(height: 12),
            ],
          ),
        ),

        // Os botões flutuam meio sobre o card verde, meio sobre o fundo
        // branco. Em vez de usar Positioned(bottom: -36) dentro de um Stack
        // (que deixa a parte "vazada" fora dos limites do Stack sem
        // resposta a toque), usamos Transform.translate: o botão continua
        // no fluxo normal do layout, então toda a área visível responde ao
        // toque corretamente.
        Transform.translate(
          offset: const Offset(0, -16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _openGlycemiaRecordModal(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor.darken(0.08),
                      foregroundColor: Colors.white,
                      elevation: 4,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('+ Registrar Glicemia'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onNavegarParaInsulina,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primaryColor,
                      elevation: 4,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('+ Calcular Insulina'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

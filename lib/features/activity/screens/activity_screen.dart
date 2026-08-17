import 'package:doce_equilibrio/core/di/service_locator.dart';
import 'package:doce_equilibrio/core/theme/app_colors.dart';
import 'package:doce_equilibrio/features/activity/controllers/activity_controller.dart';
import 'package:doce_equilibrio/features/activity/models/activity_model.dart';
import 'package:doce_equilibrio/features/activity/widgets/activity_card.dart';
import 'package:doce_equilibrio/features/activity/widgets/activity_modal.dart';
import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _AtividadeScreenState();
}

class _AtividadeScreenState extends State<ActivityScreen> {
  late final ActivityController _controller;

  bool _isLoading = true;
  List<ActivityModel> _atividades = [];

  @override
  void initState() {
    super.initState();
    _controller = getIt<ActivityController>();
    _loadActivities();
  }

  Future<void> _loadActivities() async {
    setState(() => _isLoading = true);
    final atividades = await _controller.listar();

    if (!mounted) return;
    setState(() {
      _atividades = atividades;
      _isLoading = false;
    });
  }

  Future<void> _openModal({ActivityModel? existingActivity}) async {
    final salvou = await ActivityModal.exibir(
      context,
      existingActivity: existingActivity,
    );
    if (salvou == true) {
      await _loadActivities();
    }
  }

  Future<void> _confirmDeletion(ActivityModel atividade) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.backgroundColor,
          title: const Text('Excluir Registro'),
          content: Text(
            'Deseja realmente excluir esta atividade (${atividade.tipo.rotulo})?',
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 48),
                      foregroundColor: Colors.grey.shade700,
                      backgroundColor: Colors.white,
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(0, 48),
                      backgroundColor: AppColors.dangerColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Excluir',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );

    if (confirmou == true && atividade.id != null) {
      final excluiu = await _controller.excluir(atividade.id!);
      if (!mounted) return;

      if (excluiu) {
        await _loadActivities();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível excluir o registro.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryColor,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              color: AppColors.primaryColor,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                    child: const Icon(
                      PhosphorIcons.heartbeat,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Atividade Física',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Registre seus exercícios',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                color: AppColors.backgroundColor,
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primaryColor,
                        ),
                      )
                    : RefreshIndicator(
                        color: AppColors.primaryColor,
                        onRefresh: _loadActivities,
                        child: ListView(
                          padding: const EdgeInsets.all(24),
                          children: [
                            ElevatedButton.icon(
                              onPressed: () => _openModal(),
                              icon: const Icon(PhosphorIcons.plus, size: 18),
                              label: const Text('Registrar Atividade'),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(0, 52),
                                backgroundColor: AppColors.primaryColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            if (_atividades.isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 48,
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      PhosphorIcons.heartbeat,
                                      size: 48,
                                      color: Colors.grey.shade300,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Nenhuma atividade registrada.\nToque em "Registrar Atividade" para começar.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              ..._atividades.map(
                                (atividade) => ActivityCard(
                                  atividade: atividade,
                                  onEditar: () =>
                                      _openModal(existingActivity: atividade),
                                  onExcluir: () => _confirmDeletion(atividade),
                                ),
                              ),
                          ],
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

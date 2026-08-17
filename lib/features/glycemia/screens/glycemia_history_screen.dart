import 'package:doce_equilibrio/core/di/service_locator.dart';
import 'package:doce_equilibrio/core/services/session_service.dart';
import 'package:doce_equilibrio/core/theme/app_colors.dart';
import 'package:doce_equilibrio/features/auth/models/user_model.dart';
import 'package:doce_equilibrio/features/auth/repositories/user_repository_interface.dart';
import 'package:doce_equilibrio/features/glycemia/controllers/glycemia_controller.dart';
import 'package:doce_equilibrio/features/glycemia/models/glycemia_statistics.dart';
import 'package:doce_equilibrio/features/glycemia/models/glycemia_record_model.dart';
import 'package:doce_equilibrio/features/glycemia/widgets/glycemia_record_card.dart';
import 'package:doce_equilibrio/features/glycemia/widgets/glycemia_record_modal.dart';
import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

class GlycemiaHistoryScreen extends StatefulWidget {
  const GlycemiaHistoryScreen({super.key});

  @override
  State<GlycemiaHistoryScreen> createState() => _HistoricoGlicemiaScreenState();
}

class _HistoricoGlicemiaScreenState extends State<GlycemiaHistoryScreen> {
  late final GlycemiaController _controller;

  bool _isLoading = true;
  List<GlycemiaRecordModel> _records = [];
  GlycemiaStatistics _estatisticas = GlycemiaStatistics.empty();
  UserModel? _user;

  @override
  void initState() {
    super.initState();
    _controller = getIt<GlycemiaController>();
    _loadHistory();
  }

  Future<UserModel?> _buscarUsuarioLogado() async {
    final id = await getIt<SessionService>().getCurrentUserId();
    if (id == null) return null;

    return getIt<UserRepositoryInterface>().find(id);
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);

    final user = await _buscarUsuarioLogado();
    final records = await _controller.listHistory();
    final estatisticas = _controller.calculateStatistics(records);

    if (!mounted) return;
    setState(() {
      _user = user;
      _records = records;
      _estatisticas = estatisticas;
      _isLoading = false;
    });
  }

  Future<void> _openRecordModal({GlycemiaRecordModel? existingRecord}) async {
    final saved = await GlycemiaRecordModal.exibir(
      context,
      existingRecord: existingRecord,
    );
    if (saved == true) {
      await _loadHistory();
    }
  }

  Future<void> _confirmDeletion(GlycemiaRecordModel record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.backgroundColor,
          title: const Text('Excluir Registro'),
          content: Text(
            'Deseja realmente excluir a leitura de ${record.value} mg/dL '
            'registrada em ${record.dateTime.day.toString().padLeft(2, '0')}/'
            '${record.dateTime.month.toString().padLeft(2, '0')}/'
            '${record.dateTime.year}? Essa ação não pode ser desfeita.',
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
                      side: BorderSide(color: Colors.grey.shade300, width: 1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
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
                      padding: const EdgeInsets.symmetric(vertical: 12),
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

    if (confirmed == true && record.id != null) {
      final deleted = await _controller.delete(record.id!);
      if (!mounted) return;

      if (deleted) {
        await _loadHistory();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível excluir o registro.')),
        );
      }
    }
  }

  Widget _circularIcon({required IconData icone, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.3),
          shape: BoxShape.circle,
        ),
        child: Icon(icone, color: Colors.white, size: 22),
      ),
    );
  }

  Widget _statisticsColumn(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
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
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              color: AppColors.primaryColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _circularIcon(
                    icone: PhosphorIcons.caretLeft,
                    onTap: () => Navigator.pop(context),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                        child: const Icon(
                          PhosphorIcons.clockCounterClockwise,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Histórico de Glicemia',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Todos os seus registros',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        _statisticsColumn(
                          _estatisticas.average > 0
                              ? '${_estatisticas.average} mg/dL'
                              : '--',
                          'Média',
                        ),
                        _statisticsColumn(
                          '${_estatisticas.totalReadings}',
                          'Total de Leituras',
                        ),
                        _statisticsColumn(
                          '${_estatisticas.lastSevenDays}',
                          'Últimos 7 dias',
                        ),
                      ],
                    ),
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
                        onRefresh: _loadHistory,
                        child: ListView(
                          padding: const EdgeInsets.all(24),
                          children: [
                            ElevatedButton.icon(
                              onPressed: () => _openRecordModal(),
                              icon: const Icon(PhosphorIcons.plus, size: 18),
                              label: const Text('Registrar Glicemia'),
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
                            if (_records.isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 48,
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      PhosphorIcons.drop,
                                      size: 48,
                                      color: Colors.grey.shade300,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Nenhum registro encontrado.\nToque em "Registrar Glicemia" para começar.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              ..._records.map(
                                (record) => GlycemiaRecordCard(
                                  record: record,
                                  user: _user!,
                                  onEditar: () =>
                                      _openRecordModal(existingRecord: record),
                                  onExcluir: () => _confirmDeletion(record),
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

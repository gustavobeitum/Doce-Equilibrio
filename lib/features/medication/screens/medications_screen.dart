import 'package:doce_equilibrio/core/di/service_locator.dart';
import 'package:doce_equilibrio/core/theme/app_colors.dart';
import 'package:doce_equilibrio/features/medication/controllers/medication_controller.dart';
import 'package:doce_equilibrio/features/medication/models/medication_model.dart';
import 'package:doce_equilibrio/features/medication/widgets/medication_card.dart';
import 'package:doce_equilibrio/features/medication/widgets/medication_modal.dart';
import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

class MedicationsScreen extends StatefulWidget {
  const MedicationsScreen({super.key});

  @override
  State<MedicationsScreen> createState() => _MedicamentosScreenState();
}

class _MedicamentosScreenState extends State<MedicationsScreen> {
  late final MedicationController _controller;

  bool _isLoading = true;
  List<MedicationModel> _medicamentos = [];

  @override
  void initState() {
    super.initState();
    _controller = getIt<MedicationController>();
    _loadMedications();
  }

  Future<void> _loadMedications() async {
    setState(() => _isLoading = true);
    final medicamentos = await _controller.listar();

    if (!mounted) return;
    setState(() {
      _medicamentos = medicamentos;
      _isLoading = false;
    });
  }

  Future<void> _openModal({MedicationModel? existingMedication}) async {
    final salvou = await MedicationModal.exibir(
      context,
      existingMedication: existingMedication,
    );
    if (salvou == true) {
      await _loadMedications();
    }
  }

  Future<void> _confirmDeletion(MedicationModel medicamento) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.backgroundColor,
          title: const Text('Excluir Registro'),
          content: Text(
            'Deseja realmente excluir o registro de "${medicamento.nome}"?',
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

    if (confirmou == true && medicamento.id != null) {
      final excluiu = await _controller.excluir(medicamento.id!);
      if (!mounted) return;

      if (excluiu) {
        await _loadMedications();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível excluir o registro.')),
        );
      }
    }
  }

  Widget _iconeCircular({
    required IconData icone,
    required VoidCallback onTap,
  }) {
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
                  _iconeCircular(
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
                          PhosphorIcons.pill,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Medicamentos',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Registre os medicamentos tomados',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
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
                        onRefresh: _loadMedications,
                        child: ListView(
                          padding: const EdgeInsets.all(24),
                          children: [
                            ElevatedButton.icon(
                              onPressed: () => _openModal(),
                              icon: const Icon(PhosphorIcons.plus, size: 18),
                              label: const Text('Registrar Medicamento'),
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
                            if (_medicamentos.isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 48,
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      PhosphorIcons.pill,
                                      size: 48,
                                      color: Colors.grey.shade300,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Nenhum medicamento registrado.\nToque em "Registrar Medicamento" para começar.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              ..._medicamentos.map(
                                (medicamento) => MedicationCard(
                                  medicamento: medicamento,
                                  onEditar: () => _openModal(
                                    existingMedication: medicamento,
                                  ),
                                  onExcluir: () =>
                                      _confirmDeletion(medicamento),
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

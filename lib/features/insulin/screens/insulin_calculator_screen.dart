import 'package:doce_equilibrio/core/di/service_locator.dart';
import 'package:doce_equilibrio/core/theme/app_colors.dart';
import 'package:doce_equilibrio/core/widgets/app_card.dart';
import 'package:doce_equilibrio/features/insulin/controllers/insulin_application_controller.dart';
import 'package:doce_equilibrio/features/insulin/models/insulin_application_model.dart';
import 'package:doce_equilibrio/features/meals/models/meal_item_model.dart';
import 'package:doce_equilibrio/features/meals/widgets/meal_food_selection_modal.dart';
import 'package:doce_equilibrio/features/settings/widgets/edit_insulin_parameters_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

class InsulinCalculatorScreen extends StatefulWidget {
  const InsulinCalculatorScreen({super.key, this.isActive = true});
  final bool isActive;
  @override
  State<InsulinCalculatorScreen> createState() =>
      _InsulinCalculatorScreenState();
}

class _InsulinCalculatorScreenState extends State<InsulinCalculatorScreen> {
  late final InsulinApplicationController _controller;
  final _glycemia = TextEditingController();
  final _carbohydrates = TextEditingController();
  final _appliedDose = TextEditingController();
  final _observation = TextEditingController();

  // Alimentos individuais escolhidos para compor os carboidratos da
  // aplicação atual (ex.: bolo + suco), somados automaticamente no campo
  // de carboidratos. Não são persistidos como uma refeição; servem só
  // para o cálculo desta aplicação.
  final List<MealItemModel> _selectedFoodItems = [];

  @override
  void initState() {
    super.initState();
    _controller = getIt<InsulinApplicationController>()..addListener(_refresh);
    _controller.load();
  }

  @override
  void dispose() {
    _controller.removeListener(_refresh);
    _controller.dispose();
    for (final controller in [
      _glycemia,
      _carbohydrates,
      _appliedDose,
      _observation,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant InsulinCalculatorScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) _controller.load();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  String _format(double value) => value
      .toStringAsFixed(2)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '')
      .replaceAll('.', ',');

  void _calculate() {
    final error = _controller.calculate(
      glycemia: _glycemia.text,
      carbohydrates: _carbohydrates.text,
    );
    if (error == null) {
      _appliedDose.text = _format(_controller.calculation!.totalDose);
    }
  }

  Future<void> _save() async {
    final saved = await _controller.save(
      glycemia: _glycemia.text,
      carbohydrates: _carbohydrates.text,
      appliedDose: _appliedDose.text,
      observation: _observation.text,
    );
    if (!mounted || !saved) return;
    final message = _controller.successMessage ?? 'Aplicação salva.';
    _clearFields();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _clearFields() {
    _glycemia.clear();
    _carbohydrates.clear();
    _appliedDose.clear();
    _observation.clear();
    _selectedFoodItems.clear();
  }

  void _cancel() {
    _controller.cancelEditing();
    _clearFields();
  }

  void _edit(InsulinApplicationModel item) {
    _controller.startEditing(item);
    _glycemia.text = item.glycemia.toString();
    _carbohydrates.text = _format(item.carbohydrates);
    _appliedDose.text = _format(item.appliedDose);
    _observation.text = item.observation ?? '';
    // O detalhamento por alimento não é salvo junto da aplicação (só o
    // total de carboidratos), então ao editar um registro antigo os chips
    // começam vazios — o valor total continua correto no campo acima.
    _selectedFoodItems.clear();
  }

  Future<void> _delete(InsulinApplicationModel item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir aplicação?'),
        content: const Text('Esta ação removerá o registro selecionado.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final deleted = await _controller.delete(item);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          deleted
              ? 'Aplicação excluída com sucesso.'
              : (_controller.errorMessage ?? 'Não foi possível excluir.'),
        ),
      ),
    );
  }

  /// Abre o seletor de alimentos da biblioteca (o mesmo já usado no
  /// registro de refeições) e adiciona o item escolhido à lista local,
  /// recalculando o total de carboidratos.
  Future<void> _addFood() async {
    final item = await MealFoodSelectionModal.exibir(context);
    if (item == null || !mounted) return;
    setState(() {
      _selectedFoodItems.add(item);
      _recalculateCarbsFromFoods();
    });
  }

  void _removeFood(MealItemModel item) {
    setState(() {
      _selectedFoodItems.remove(item);
      _recalculateCarbsFromFoods();
    });
  }

  void _recalculateCarbsFromFoods() {
    final total = _selectedFoodItems.fold<double>(
      0,
      (sum, item) => sum + item.carbohydrates,
    );
    _carbohydrates.text = _format(total);
    _controller.invalidateCalculation();
  }

  void _onCarbohydratesEditedManually() {
    _controller.invalidateCalculation();
    if (_selectedFoodItems.isNotEmpty) {
      setState(() => _selectedFoodItems.clear());
    }
  }

  Future<void> _editParameters() async {
    final user = _controller.user;
    if (user == null) return;
    final saved = await EditInsulinParametersModal.exibir(
      context,
      currentUser: user,
    );
    if (saved == true) {
      _cancel();
      await _controller.load();
    }
  }

  InputDecoration _decoration(String label, {String? suffix}) =>
      InputDecoration(
        labelText: label,
        suffixText: suffix,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      );

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
                      PhosphorIcons.drop,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Aplicação de Insulina',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Calcule, revise e registre',
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
                child: _controller.isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primaryColor,
                        ),
                      )
                    : _controller.loadErrorMessage != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                PhosphorIcons.warningCircle,
                                color: AppColors.dangerColor,
                                size: 48,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _controller.loadErrorMessage!,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _controller.load,
                                child: const Text('Tentar novamente'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _controller.load,
                        child: ListView(
                          padding: const EdgeInsets.all(20),
                          children: [
                            if (_controller.user != null) _parametersCard(),
                            const SizedBox(height: 16),
                            _formCard(),
                            const SizedBox(height: 16),
                            _medicalWarning(),
                            const SizedBox(height: 20),
                            _history(),
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

  Widget _parametersCard() {
    final user = _controller.user!;
    return AppCard(
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Seus Parâmetros Atuais',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              TextButton.icon(
                onPressed: _editParameters,
                icon: const Icon(PhosphorIcons.pencilSimple, size: 16),
                label: const Text('Editar'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          _row('Meta Glicêmica', '${user.glycemiaTarget} mg/dL'),
          _row('Fator de Correção', '1 UI / ${_format(user.correctionFactor)}'),
          _row(
            'Razão Insulina/Carbo',
            '1 UI / ${_format(user.sensitivityFactor)}g',
          ),
        ],
      ),
    );
  }

  Widget _formCard() {
    final calculation = _controller.calculation;
    final editing = _controller.editingApplication != null;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            editing ? 'Editar Aplicação' : 'Nova Aplicação',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _glycemia,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(3),
            ],
            decoration: _decoration(
              'Glicemia Atual',
              suffix: 'mg/dL',
            ).copyWith(filled: true, fillColor: AppColors.backgroundColor),
            onChanged: (_) => _controller.invalidateCalculation(),
          ),
          const SizedBox(height: 16),
          const Text(
            'Carboidratos da Refeição',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            'Digite manualmente ou selecione alimentos da sua biblioteca.',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _carbohydrates,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: _decoration(
              'Carboidratos',
              suffix: 'g',
            ).copyWith(filled: true, fillColor: AppColors.backgroundColor),
            onChanged: (_) => _onCarbohydratesEditedManually(),
          ),
          if (_selectedFoodItems.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _selectedFoodItems.map((item) {
                return InputChip(
                  key: Key('selected-food-${item.foodId}-${item.hashCode}'),
                  label: Text(
                    '${item.foodName} • ${_format(item.carbohydrates)}g',
                  ),
                  labelStyle: const TextStyle(
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                  backgroundColor: AppColors.primaryColor.withValues(
                    alpha: 0.08,
                  ),
                  deleteIconColor: AppColors.primaryColor,
                  side: BorderSide.none,
                  onDeleted: () => _removeFood(item),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              key: const Key('select-foods-button'),
              onPressed: _addFood,
              icon: const Icon(PhosphorIcons.plus, size: 18),
              label: const Text('Selecionar Alimentos'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryColor,
                backgroundColor: AppColors.primaryColor.withValues(alpha: 0.08),
                side: BorderSide.none,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _calculate,
              icon: const Icon(PhosphorIcons.calculator),
              label: const Text('Calcular Dose'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          if (calculation != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Dose recomendada'),
                  Text(
                    '${_format(calculation.totalDose)} UI',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryColor,
                    ),
                  ),
                  Text(
                    'Glicemia: ${_glycemia.text} mg/dL • Carboidratos: ${_carbohydrates.text} g',
                  ),
                  _row(
                    'Dose alimentar',
                    '${_format(calculation.carbohydrateDose)} UI',
                  ),
                  _row(
                    'Dose de correção',
                    '${_format(calculation.correctionDose)} UI',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _appliedDose,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: _decoration(
                'Dose efetivamente aplicada',
                suffix: 'UI',
              ).copyWith(filled: true, fillColor: AppColors.backgroundColor),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _observation,
              maxLines: 3,
              decoration: _decoration(
                'Observação (opcional)',
              ).copyWith(filled: true, fillColor: AppColors.backgroundColor),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _controller.isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _controller.isSaving
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        editing ? 'Salvar alterações' : 'Registrar aplicação',
                      ),
              ),
            ),
          ],
          if (_controller.errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              _controller.errorMessage!,
              style: const TextStyle(color: AppColors.dangerColor),
            ),
          ],
          if (editing)
            TextButton(
              onPressed: _cancel,
              child: const Text('Cancelar edição'),
            ),
        ],
      ),
    );
  }

  Widget _history() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Aplicações registradas',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 8),
      if (_controller.applications.isEmpty)
        const AppCard(
          padding: EdgeInsets.all(16),
          child: Text('Nenhuma aplicação registrada.'),
        )
      else
        ..._controller.applications.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AppCard(
              padding: EdgeInsets.zero,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                title: Text(
                  '${_formatDateTime(item.dateTime)}\n'
                  '${_format(item.appliedDose)} UI aplicada',
                ),
                subtitle: Text(
                  'Recomendada: ${_format(item.recommendedDose)} UI • ${item.glycemia} mg/dL • ${_format(item.carbohydrates)} g',
                ),
                trailing: Wrap(
                  children: [
                    IconButton(
                      tooltip: 'Editar',
                      onPressed: () => _edit(item),
                      icon: const Icon(PhosphorIcons.pencilSimple),
                    ),
                    IconButton(
                      tooltip: 'Excluir',
                      onPressed: () => _delete(item),
                      icon: const Icon(PhosphorIcons.trash),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
    ],
  );

  String _formatDateTime(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$day/$month/${value.year} • $hour:$minute';
  }

  Widget _medicalWarning() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.amber.shade50,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.amber.shade200),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(PhosphorIcons.warning, color: Colors.amber.shade800, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'A dose é uma recomendação. Revise e informe quanto foi '
            'efetivamente aplicado, seguindo a orientação da sua equipe de saúde.',
            style: TextStyle(color: Colors.amber.shade900, height: 1.4),
          ),
        ),
      ],
    ),
  );

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Row(
      children: [
        Expanded(
          child: Text(label, style: TextStyle(color: Colors.grey.shade600)),
        ),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    ),
  );
}

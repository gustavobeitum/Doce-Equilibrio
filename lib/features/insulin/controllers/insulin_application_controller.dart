import 'package:doce_equilibrio/core/services/session_service.dart';
import 'package:doce_equilibrio/core/utils/validators.dart';
import 'package:doce_equilibrio/features/auth/models/user_model.dart';
import 'package:doce_equilibrio/features/auth/repositories/user_repository_interface.dart';
import 'package:doce_equilibrio/features/insulin/controllers/insulin_calculation_controller.dart';
import 'package:doce_equilibrio/features/insulin/models/insulin_application_model.dart';
import 'package:doce_equilibrio/features/insulin/models/insulin_calculation_result.dart';
import 'package:doce_equilibrio/features/insulin/repositories/insulin_application_repository_interface.dart';
import 'package:doce_equilibrio/features/meals/models/meal_model.dart';
import 'package:doce_equilibrio/features/meals/repositories/meal_repository_interface.dart';
import 'package:flutter/foundation.dart';

class InsulinApplicationController extends ChangeNotifier {
  final InsulinApplicationRepositoryInterface repository;
  final MealRepositoryInterface _mealRepository;
  final UserRepositoryInterface _userRepository;
  final SessionService _sessionService;
  final DateTime Function() _now;

  InsulinApplicationController(
    this.repository,
    this._mealRepository,
    this._userRepository,
    this._sessionService, {
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  bool isLoading = false;
  bool isLoadingMeals = false;
  String? mealsErrorMessage;
  bool isSaving = false;
  String? errorMessage;
  String? loadErrorMessage;
  String? successMessage;
  UserModel? user;
  List<MealModel> meals = const [];
  List<InsulinApplicationModel> applications = const [];
  MealModel? selectedMeal;
  InsulinCalculationResult? calculation;
  InsulinApplicationModel? editingApplication;

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    loadErrorMessage = null;
    notifyListeners();
    try {
      final userId = await _sessionService.getCurrentUserId();
      if (userId == null) {
        loadErrorMessage = 'Sessão expirada. Faça login novamente.';
        return;
      }
      user = await _userRepository.find(userId);
      if (user == null) {
        loadErrorMessage = 'Não foi possível carregar o usuário.';
        return;
      }
      await Future.wait([loadMeals(userId: userId), _loadApplications(userId)]);
    } catch (_) {
      loadErrorMessage = 'Não foi possível carregar as aplicações de insulina.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadApplications(int userId) async {
    applications = await repository.listByUser(userId);
  }

  Future<void> loadMeals({int? userId}) async {
    isLoadingMeals = true;
    mealsErrorMessage = null;
    notifyListeners();
    try {
      final currentUserId = userId ?? await _sessionService.getCurrentUserId();
      if (currentUserId == null) {
        meals = const [];
        mealsErrorMessage = 'Sessão expirada. Faça login novamente.';
        return;
      }
      meals = await _mealRepository.listByUser(currentUserId);
    } catch (_) {
      meals = const [];
      mealsErrorMessage = 'Não foi possível carregar as refeições.';
    } finally {
      isLoadingMeals = false;
      notifyListeners();
    }
  }

  double selectMeal(MealModel meal) {
    selectedMeal = meal;
    calculation = null;
    errorMessage = null;
    notifyListeners();
    return meal.totalCarbohydrates;
  }

  void clearMealSelection() {
    selectedMeal = null;
    calculation = null;
    notifyListeners();
  }

  void invalidateCalculation() {
    calculation = null;
    errorMessage = null;
    notifyListeners();
  }

  String? calculate({required String glycemia, required String carbohydrates}) {
    errorMessage = _validateCalculation(glycemia, carbohydrates);
    if (errorMessage != null) {
      calculation = null;
      notifyListeners();
      return errorMessage;
    }
    final currentUser = user!;
    calculation = InsulinCalculationController.calculate(
      currentGlycemia: int.parse(glycemia.trim()),
      carbohydratesGrams: _parseDouble(carbohydrates),
      glycemiaTarget: currentUser.glycemiaTarget,
      correctionFactor: currentUser.correctionFactor,
      sensitivityFactor: currentUser.sensitivityFactor,
    );
    errorMessage = null;
    notifyListeners();
    return null;
  }

  Future<bool> save({
    required String glycemia,
    required String carbohydrates,
    required String appliedDose,
    String? observation,
  }) async {
    successMessage = null;
    var validation = _validateCalculation(glycemia, carbohydrates);
    validation ??= _validateAppliedDose(appliedDose);
    if (validation != null) {
      errorMessage = validation;
      notifyListeners();
      return false;
    }

    calculate(glycemia: glycemia, carbohydrates: carbohydrates);
    final currentUser = user!;
    final result = calculation!;
    final application = InsulinApplicationModel(
      id: editingApplication?.id,
      userId: currentUser.id!,
      glycemia: int.parse(glycemia.trim()),
      carbohydrates: _parseDouble(carbohydrates),
      carbohydrateDose: result.carbohydrateDose,
      correctionDose: result.correctionDose,
      recommendedDose: result.totalDose,
      appliedDose: _parseDouble(appliedDose),
      dateTime: editingApplication?.dateTime ?? _now(),
      observation: observation?.trim().isEmpty == true
          ? null
          : observation?.trim(),
      mealId: selectedMeal?.id,
    );

    isSaving = true;
    errorMessage = null;
    notifyListeners();
    try {
      if (application.id == null) {
        await repository.create(application);
      } else {
        await repository.update(application);
      }
      successMessage = application.id == null
          ? 'Aplicação registrada com sucesso.'
          : 'Aplicação atualizada com sucesso.';
      editingApplication = null;
      selectedMeal = null;
      calculation = null;
      applications = await repository.listByUser(currentUser.id!);
      return true;
    } catch (_) {
      errorMessage = 'Não foi possível salvar a aplicação. Tente novamente.';
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  void startEditing(InsulinApplicationModel application) {
    editingApplication = application;
    selectedMeal = application.mealId == null
        ? null
        : meals.where((meal) => meal.id == application.mealId).firstOrNull;
    calculation = InsulinCalculationResult(
      correctionDose: application.correctionDose,
      carbohydrateDose: application.carbohydrateDose,
      totalDose: application.recommendedDose,
    );
    errorMessage = null;
    successMessage = null;
    notifyListeners();
  }

  void cancelEditing() {
    editingApplication = null;
    selectedMeal = null;
    calculation = null;
    errorMessage = null;
    notifyListeners();
  }

  Future<bool> delete(InsulinApplicationModel application) async {
    final userId = user?.id;
    if (application.id == null || userId == null) return false;
    try {
      final deleted = await repository.delete(application.id!, userId) > 0;
      if (deleted) {
        applications = await repository.listByUser(userId);
        successMessage = 'Aplicação excluída com sucesso.';
        if (editingApplication?.id == application.id) cancelEditing();
      }
      notifyListeners();
      return deleted;
    } catch (_) {
      errorMessage = 'Não foi possível excluir a aplicação.';
      notifyListeners();
      return false;
    }
  }

  String? _validateCalculation(String glycemia, String carbohydrates) {
    if (user == null) return 'Sessão expirada. Faça login novamente.';
    final glycemiaError = Validators.validateInsulinCalculationGlycemia(
      glycemia,
    );
    if (glycemiaError != null) return glycemiaError;
    final carbohydratesValue = _tryParseDouble(carbohydrates);
    if (carbohydratesValue == null || carbohydratesValue < 0) {
      return 'Informe uma quantidade de carboidratos maior ou igual a zero.';
    }
    return null;
  }

  String? _validateAppliedDose(String value) {
    final dose = _tryParseDouble(value);
    if (dose == null || dose < 0) {
      return 'Informe uma dose aplicada maior ou igual a zero.';
    }
    final doubled = dose * 2;
    if ((doubled - doubled.round()).abs() > 1e-9) {
      return 'A dose aplicada deve usar incrementos de 0,5 UI.';
    }
    return null;
  }

  static double? _tryParseDouble(String value) {
    return double.tryParse(value.trim().replaceAll(',', '.'));
  }

  static double _parseDouble(String value) => _tryParseDouble(value)!;
}

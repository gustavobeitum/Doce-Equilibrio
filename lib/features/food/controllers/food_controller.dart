import 'package:doce_equilibrio/core/services/session_service.dart';
import 'package:doce_equilibrio/features/food/models/food_model.dart';
import 'package:doce_equilibrio/features/food/repositories/food_repository_interface.dart';
import 'package:flutter/foundation.dart';

class FoodController {
  final FoodRepositoryInterface repository;
  final SessionService _sessionService;

  FoodController(this.repository, this._sessionService);

  Future<List<FoodModel>> list() async {
    final userId = await _sessionService.getCurrentUserId();
    if (userId == null) return [];
    return repository.listByUser(userId);
  }

  Future<String?> save({
    int? id,
    required String name,
    required double carbohydratesPer100g,
  }) async {
    if (name.trim().isEmpty) {
      return 'Informe o nome do alimento.';
    }

    try {
      final userId = await _sessionService.getCurrentUserId();
      if (userId == null) {
        return 'Sessão expirada. Faça login novamente.';
      }

      final food = FoodModel(
        id: id,
        userId: userId,
        name: name.trim(),
        carbohydratesPer100g: carbohydratesPer100g,
      );

      if (id == null) {
        await repository.create(food);
      } else {
        await repository.update(food);
      }
      return null;
    } catch (e) {
      debugPrint('ERRO AO SALVAR ALIMENTO: $e');
      return 'Não foi possível salvar o alimento. Tente novamente.';
    }
  }

  Future<bool> delete(int id) async {
    try {
      final affectedRows = await repository.delete(id);
      return affectedRows > 0;
    } catch (e) {
      debugPrint('ERRO AO EXCLUIR ALIMENTO: $e');
      return false;
    }
  }
}

import 'package:doce_equilibrio/core/services/session_service.dart';
import 'package:doce_equilibrio/features/food/models/meal_item_model.dart';
import 'package:doce_equilibrio/features/food/models/meal_model.dart';
import 'package:doce_equilibrio/features/food/models/meal_type.dart';
import 'package:doce_equilibrio/features/food/repositories/meal_repository_interface.dart';
import 'package:flutter/foundation.dart';

class MealController {
  final MealRepositoryInterface repository;
  final SessionService _sessionService;

  MealController(this.repository, this._sessionService);

  Future<List<MealModel>> list() async {
    final userId = await _sessionService.getCurrentUserId();
    if (userId == null) return [];
    return repository.listByUser(userId);
  }

  /// Refeições marcadas como favoritas (UC-14), pra reaproveitar depois.
  Future<List<MealModel>> listarFavoritas() async {
    final meals = await list();
    return meals.where((meal) => meal.favorite).toList();
  }

  Future<String?> save({
    int? id,
    required MealType type,
    required DateTime dateTime,
    required List<MealItemModel> items,
    bool favorite = false,
  }) async {
    if (items.isEmpty) {
      return 'Adicione ao menos um alimento à refeição.';
    }

    try {
      final userId = await _sessionService.getCurrentUserId();
      if (userId == null) {
        return 'Sessão expirada. Faça login novamente.';
      }

      final meal = MealModel(
        id: id,
        userId: userId,
        type: type,
        dateTime: dateTime,
        favorite: favorite,
        items: items,
      );

      if (id == null) {
        await repository.create(meal);
      } else {
        await repository.update(meal);
      }
      return null;
    } catch (e) {
      debugPrint('ERRO AO SALVAR REFEIÇÃO: $e');
      return 'Não foi possível salvar a refeição. Tente novamente.';
    }
  }

  Future<bool> delete(int id) async {
    try {
      final affectedRows = await repository.delete(id);
      return affectedRows > 0;
    } catch (e) {
      debugPrint('ERRO AO EXCLUIR REFEIÇÃO: $e');
      return false;
    }
  }
}

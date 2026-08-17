import 'package:doce_equilibrio/features/food/models/meal_item_model.dart';
import 'package:doce_equilibrio/features/food/models/meal_model.dart';
import 'package:doce_equilibrio/features/food/models/meal_type.dart';
import 'package:doce_equilibrio/features/food/repositories/meal_repository_interface.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class MealController {
  final MealRepositoryInterface repository;
  final FlutterSecureStorage _storage;

  MealController(this.repository, {FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  Future<int?> _userIdLogado() async {
    final idString = await _storage.read(key: 'usuario_id');
    if (idString == null) return null;
    return int.tryParse(idString);
  }

  Future<List<MealModel>> list() async {
    final userId = await _userIdLogado();
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
      final userId = await _userIdLogado();
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

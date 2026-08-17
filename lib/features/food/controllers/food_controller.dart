import 'package:doce_equilibrio/features/food/models/food_model.dart';
import 'package:doce_equilibrio/features/food/repositories/food_repository_interface.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class FoodController {
  final FoodRepositoryInterface repository;
  final FlutterSecureStorage _storage;

  FoodController(this.repository, {FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  Future<int?> _userIdLogado() async {
    final idString = await _storage.read(key: 'usuario_id');
    if (idString == null) return null;
    return int.tryParse(idString);
  }

  Future<List<FoodModel>> list() async {
    final userId = await _userIdLogado();
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
      final userId = await _userIdLogado();
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

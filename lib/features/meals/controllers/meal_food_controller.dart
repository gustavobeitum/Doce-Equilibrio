import 'package:doce_equilibrio/core/services/session_service.dart';
import 'package:doce_equilibrio/features/food/models/food_model.dart';
import 'package:doce_equilibrio/features/food/navigation/food_library_navigator.dart';
import 'package:doce_equilibrio/features/food/repositories/food_repository_interface.dart';
import 'package:flutter/material.dart';

class MealFoodController {
  final FoodRepositoryInterface _foodRepository;
  final SessionService _sessionService;
  final FoodLibraryNavigator _foodLibraryNavigator;

  MealFoodController(
    this._foodRepository,
    this._sessionService,
    this._foodLibraryNavigator,
  );

  Future<List<FoodModel>> listFoods() async {
    final userId = await _sessionService.getCurrentUserId();
    if (userId == null) return [];
    return _foodRepository.listByUser(userId);
  }

  Future<List<FoodModel>> searchFoods(String query) async {
    if (query.trim().isEmpty) return listFoods();
    final userId = await _sessionService.getCurrentUserId();
    if (userId == null) return [];
    return _foodRepository.searchByName(userId, query);
  }

  Future<void> openFoodLibrary(BuildContext context) {
    return _foodLibraryNavigator.open(context);
  }
}

import 'package:doce_equilibrio/features/food/models/meal_model.dart';

abstract class MealRepositoryInterface {
  Future<int> create(MealModel meal);
  Future<int> update(MealModel meal);
  Future<int> delete(int id);
  Future<List<MealModel>> listByUser(int userId);
}

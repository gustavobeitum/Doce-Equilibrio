import 'package:doce_equilibrio/features/meals/models/meal_model.dart';

abstract class MealRepositoryInterface {
  Future<int> create(MealModel meal);
  Future<int> update(MealModel meal);
  Future<int> setFavorite(int id, bool favorite);
  Future<int> delete(int id);
  Future<List<MealModel>> listByUser(int userId);
}

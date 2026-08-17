import 'package:doce_equilibrio/features/food/models/food_model.dart';

abstract class FoodRepositoryInterface {
  Future<int> create(FoodModel food);
  Future<int> update(FoodModel food);
  Future<int> delete(int id);
  Future<List<FoodModel>> listByUser(int userId);
}

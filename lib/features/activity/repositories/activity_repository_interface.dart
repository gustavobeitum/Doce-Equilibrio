import 'package:doce_equilibrio/features/activity/models/activity_model.dart';

abstract class ActivityRepositoryInterface {
  Future<int> create(ActivityModel atividade);
  Future<int> update(ActivityModel atividade);
  Future<int> delete(int id);

  Future<List<ActivityModel>> listByUser(
    int usuarioId, {
    int? limit,
    int? offset,
  });
}
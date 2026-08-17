import 'package:doce_equilibrio/features/activity/models/activity_model.dart';

abstract class ActivityRepositoryInterface {
  Future<int> criar(ActivityModel atividade);
  Future<int> atualizar(ActivityModel atividade);
  Future<int> excluir(int id);
  Future<List<ActivityModel>> listByUser(int usuarioId);
}

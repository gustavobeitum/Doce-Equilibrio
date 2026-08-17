import 'package:doce_equilibrio/features/glycemia/models/glycemia_record_model.dart';

abstract class GlycemiaRepositoryInterface {
  Future<int> create(GlycemiaRecordModel record);
  Future<int> update(GlycemiaRecordModel record);
  Future<int> delete(int id);

  /// Lista os registros do usuário, do mais recente para o mais antigo.
  Future<List<GlycemiaRecordModel>> listByUser(int userId);

  /// Busca a leitura mais recente do usuário, ou `null` se ele ainda não
  /// tiver nenhum registro.
  Future<GlycemiaRecordModel?> findLatestReading(int userId);
}

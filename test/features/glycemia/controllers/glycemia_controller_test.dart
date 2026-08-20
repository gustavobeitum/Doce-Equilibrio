import 'package:doce_equilibrio/core/services/session_service.dart';
import 'package:doce_equilibrio/features/glycemia/controllers/glycemia_controller.dart';
import 'package:doce_equilibrio/features/glycemia/models/glycemia_record_model.dart';
import 'package:doce_equilibrio/features/glycemia/repositories/glycemia_repository_interface.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'histórico por período usa usuário atual e limites informados',
    () async {
      final repository = _Repository();
      final controller = GlycemiaController(repository, _Session(3));
      final start = DateTime(2026, 8, 1);
      final end = DateTime(2026, 8, 31, 23, 59, 59, 999, 999);

      await controller.listHistoryByPeriod(start, end);

      expect(repository.query, (userId: 3, start: start, end: end));
    },
  );

  test('ausência de sessão não consulta repository', () async {
    final repository = _Repository();
    final controller = GlycemiaController(repository, _Session(null));

    expect(
      await controller.listHistoryByPeriod(DateTime(2026), DateTime(2027)),
      isEmpty,
    );
    expect(repository.query, isNull);
  });
}

class _Repository implements GlycemiaRepositoryInterface {
  ({int userId, DateTime start, DateTime end})? query;

  @override
  Future<List<GlycemiaRecordModel>> listByPeriod(
    int userId,
    DateTime start,
    DateTime end,
  ) async {
    query = (userId: userId, start: start, end: end);
    return const [];
  }

  @override
  Future<int> create(GlycemiaRecordModel record) => throw UnimplementedError();
  @override
  Future<int> update(GlycemiaRecordModel record) => throw UnimplementedError();
  @override
  Future<int> delete(int id) => throw UnimplementedError();
  @override
  Future<GlycemiaRecordModel?> findLatestReading(int userId) =>
      throw UnimplementedError();
  @override
  Future<List<GlycemiaRecordModel>> listByUser(int userId) =>
      throw UnimplementedError();
}

class _Session implements SessionService {
  _Session(this.id);
  final int? id;
  @override
  Future<int?> getCurrentUserId() async => id;
  @override
  Future<void> startSession(int userId) async {}
  @override
  Future<void> endSession() async {}
}

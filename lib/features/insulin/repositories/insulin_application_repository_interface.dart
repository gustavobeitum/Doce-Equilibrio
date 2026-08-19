import 'package:doce_equilibrio/features/insulin/models/insulin_application_model.dart';

abstract interface class InsulinApplicationRepositoryInterface {
  Future<int> create(InsulinApplicationModel application);
  Future<int> update(InsulinApplicationModel application);
  Future<int> delete(int id, int userId);
  Future<InsulinApplicationModel?> findById(int id, int userId);
  Future<List<InsulinApplicationModel>> listByUser(int userId);
  Future<List<InsulinApplicationModel>> listByPeriod(
    int userId,
    DateTime start,
    DateTime end,
  );
}

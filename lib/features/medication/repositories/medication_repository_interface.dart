import 'package:doce_equilibrio/features/medication/models/medication_model.dart';

abstract class MedicationRepositoryInterface {
  Future<int> create(MedicationModel medicamento);
  Future<int> update(MedicationModel medicamento);
  Future<int> delete(int id);
  Future<List<MedicationModel>> listByUser(int usuarioId);
}

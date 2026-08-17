import 'package:doce_equilibrio/features/medication/models/medication_model.dart';

abstract class MedicationRepositoryInterface {
  Future<int> criar(MedicationModel medicamento);
  Future<int> atualizar(MedicationModel medicamento);
  Future<int> excluir(int id);
  Future<List<MedicationModel>> listByUser(int usuarioId);
}

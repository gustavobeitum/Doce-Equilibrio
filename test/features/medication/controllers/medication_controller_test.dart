import 'package:doce_equilibrio/core/services/session_service.dart';
import 'package:doce_equilibrio/features/medication/controllers/medication_controller.dart';
import 'package:doce_equilibrio/features/medication/models/medication_model.dart';
import 'package:doce_equilibrio/features/medication/repositories/medication_repository_interface.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('normaliza e salva medicamento para o usuário autenticado', () async {
    final repository = _FakeMedicationRepository();
    final controller = MedicationController(repository, _FakeSessionService());

    final error = await controller.salvar(
      nome: '  Metformina ',
      dosagem: ' 500 mg ',
      dataHora: DateTime(2026, 8, 20),
    );

    expect(error, isNull);
    expect(repository.created?.usuarioId, 7);
    expect(repository.created?.nome, 'Metformina');
    expect(repository.created?.dosagem, '500 mg');
  });
}

class _FakeMedicationRepository implements MedicationRepositoryInterface {
  MedicationModel? created;

  @override
  Future<int> criar(MedicationModel medicamento) async {
    created = medicamento;
    return 1;
  }

  @override
  Future<int> atualizar(MedicationModel medicamento) async => 1;

  @override
  Future<int> excluir(int id) async => 1;

  @override
  Future<List<MedicationModel>> listByUser(int usuarioId) async => [];
}

class _FakeSessionService implements SessionService {
  @override
  Future<void> endSession() async {}

  @override
  Future<int?> getCurrentUserId() async => 7;

  @override
  Future<void> startSession(int userId) async {}
}

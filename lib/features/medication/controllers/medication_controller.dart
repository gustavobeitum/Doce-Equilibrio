import 'package:doce_equilibrio/features/medication/models/medication_model.dart';
import 'package:doce_equilibrio/features/medication/repositories/medication_repository_interface.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class MedicationController {
  final MedicationRepositoryInterface repository;
  final FlutterSecureStorage _storage;

  MedicationController(this.repository, {FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  Future<int?> _usuarioIdLogado() async {
    final idString = await _storage.read(key: 'usuario_id');
    if (idString == null) return null;
    return int.tryParse(idString);
  }

  Future<List<MedicationModel>> listar() async {
    final usuarioId = await _usuarioIdLogado();
    if (usuarioId == null) return [];
    return repository.listByUser(usuarioId);
  }

  Future<String?> salvar({
    int? id,
    required String nome,
    required String dosagem,
    required DateTime dataHora,
    String? observacao,
  }) async {
    if (nome.trim().isEmpty) {
      return 'Informe o nome do medicamento.';
    }
    if (dosagem.trim().isEmpty) {
      return 'Informe a dosagem.';
    }

    try {
      final usuarioId = await _usuarioIdLogado();
      if (usuarioId == null) {
        return 'Sessão expirada. Faça login novamente.';
      }

      final observacaoTratada = observacao?.trim();

      final medicamento = MedicationModel(
        id: id,
        usuarioId: usuarioId,
        nome: nome.trim(),
        dosagem: dosagem.trim(),
        dataHora: dataHora,
        observacao: (observacaoTratada == null || observacaoTratada.isEmpty)
            ? null
            : observacaoTratada,
      );

      if (id == null) {
        await repository.criar(medicamento);
      } else {
        await repository.atualizar(medicamento);
      }
      return null;
    } catch (e) {
      debugPrint('ERRO AO SALVAR MEDICAMENTO: $e');
      return 'Não foi possível salvar o registro. Tente novamente.';
    }
  }

  Future<bool> excluir(int id) async {
    try {
      final linhasAfetadas = await repository.excluir(id);
      return linhasAfetadas > 0;
    } catch (e) {
      debugPrint('ERRO AO EXCLUIR MEDICAMENTO: $e');
      return false;
    }
  }
}

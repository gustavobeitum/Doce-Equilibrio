import 'package:doce_equilibrio/features/activity/models/activity_model.dart';
import 'package:doce_equilibrio/features/activity/models/activity_type.dart';
import 'package:doce_equilibrio/features/activity/repositories/activity_repository_interface.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ActivityController {
  final ActivityRepositoryInterface repository;
  final FlutterSecureStorage _storage;

  ActivityController(this.repository, {FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  Future<int?> _usuarioIdLogado() async {
    final idString = await _storage.read(key: 'usuario_id');
    if (idString == null) return null;
    return int.tryParse(idString);
  }

  Future<List<ActivityModel>> listar() async {
    final usuarioId = await _usuarioIdLogado();
    if (usuarioId == null) return [];
    return repository.listByUser(usuarioId);
  }

  Future<String?> salvar({
    int? id,
    required ActivityType tipo,
    required int duracaoMinutos,
    required DateTime dataHora,
    String? observacao,
  }) async {
    if (duracaoMinutos <= 0) {
      return 'Informe uma duração válida.';
    }

    try {
      final usuarioId = await _usuarioIdLogado();
      if (usuarioId == null) {
        return 'Sessão expirada. Faça login novamente.';
      }

      final observacaoTratada = observacao?.trim();

      final atividade = ActivityModel(
        id: id,
        usuarioId: usuarioId,
        tipo: tipo,
        duracaoMinutos: duracaoMinutos,
        dataHora: dataHora,
        observacao: (observacaoTratada == null || observacaoTratada.isEmpty)
            ? null
            : observacaoTratada,
      );

      if (id == null) {
        await repository.criar(atividade);
      } else {
        await repository.atualizar(atividade);
      }
      return null;
    } catch (e) {
      debugPrint('ERRO AO SALVAR ATIVIDADE: $e');
      return 'Não foi possível salvar o registro. Tente novamente.';
    }
  }

  Future<bool> excluir(int id) async {
    try {
      final linhasAfetadas = await repository.excluir(id);
      return linhasAfetadas > 0;
    } catch (e) {
      debugPrint('ERRO AO EXCLUIR ATIVIDADE: $e');
      return false;
    }
  }
}

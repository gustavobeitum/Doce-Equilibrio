import 'package:doce_equilibrio/core/services/session_service.dart';
import 'package:doce_equilibrio/features/activity/models/activity_model.dart';
import 'package:doce_equilibrio/features/activity/models/activity_type.dart';
import 'package:doce_equilibrio/features/activity/models/activity_intensity.dart';
import 'package:doce_equilibrio/features/activity/repositories/activity_repository_interface.dart';
import 'package:flutter/foundation.dart';

class ActivityController {
  final ActivityRepositoryInterface repository;
  final SessionService _sessionService;

  ActivityController(this.repository, this._sessionService);

  Future<List<ActivityModel>> listar() async {
    final usuarioId = await _sessionService.getCurrentUserId();
    if (usuarioId == null) return [];
    return repository.listByUser(usuarioId);
  }

  Future<String?> salvar({
    int? id,
    required ActivityType tipo,
    required int duracaoMinutos,
    required DateTime dataHora,
    required ActivityIntensity intensidade,
    String? observacao,
  }) async {
    if (duracaoMinutos <= 0) {
      return 'Informe uma duração válida.';
    }

    try {
      final usuarioId = await _sessionService.getCurrentUserId();
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
        intensidade: intensidade,
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

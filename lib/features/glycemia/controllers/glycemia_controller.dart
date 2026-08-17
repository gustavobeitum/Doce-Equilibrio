import 'package:doce_equilibrio/core/errors/auth_exceptions.dart';
import 'package:doce_equilibrio/features/glycemia/models/glycemia_statistics.dart';
import 'package:doce_equilibrio/features/glycemia/models/glycemia_record_model.dart';
import 'package:doce_equilibrio/features/glycemia/repositories/glycemia_repository_interface.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class GlycemiaController {
  final GlycemiaRepositoryInterface repository;
  final FlutterSecureStorage _storage;

  GlycemiaController(this.repository, {FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  Future<int?> _userIdLogado() async {
    final idString = await _storage.read(key: 'usuario_id');
    if (idString == null) return null;
    return int.tryParse(idString);
  }

  /// Lista o histórico do usuário logado, do mais recente para o mais
  /// antigo. Retorna lista vazia se não houver sessão ativa.
  Future<List<GlycemiaRecordModel>> listHistory() async {
    final userId = await _userIdLogado();
    if (userId == null) return [];
    return repository.listByUser(userId);
  }

  /// Busca a última leitura do usuário logado, para exibir na Home.
  Future<GlycemiaRecordModel?> findLatestReading() async {
    final userId = await _userIdLogado();
    if (userId == null) return null;
    return repository.findLatestReading(userId);
  }

  /// Calcula as estatísticas do cabeçalho do Histórico a partir de uma
  /// lista já carregada, evitando uma nova consulta ao banco.
  GlycemiaStatistics calculateStatistics(List<GlycemiaRecordModel> records) {
    if (records.isEmpty) return GlycemiaStatistics.empty();

    final sum = records.fold<int>(0, (sum, r) => sum + r.value);
    final average = (sum / records.length).round();

    final seteDiasAtras = DateTime.now().subtract(const Duration(days: 7));
    final lastSevenDays = records
        .where((r) => r.dateTime.isAfter(seteDiasAtras))
        .length;

    return GlycemiaStatistics(
      average: average,
      totalReadings: records.length,
      lastSevenDays: lastSevenDays,
    );
  }

  /// Cria um novo registro (quando [id] é `null`) ou atualiza um existente.
  /// Retorna `null` em caso de sucesso, ou uma mensagem de erro.
  Future<String?> save({
    int? id,
    required int value,
    required String period,
    required DateTime dateTime,
    String? notes,
  }) async {
    try {
      final userId = await _userIdLogado();
      if (userId == null) {
        return 'Sessão expirada. Faça login novamente.';
      }

      final normalizedNotes = notes?.trim();

      final record = GlycemiaRecordModel(
        id: id,
        userId: userId,
        value: value,
        period: period,
        dateTime: dateTime,
        notes: (normalizedNotes == null || normalizedNotes.isEmpty)
            ? null
            : normalizedNotes,
      );

      if (id == null) {
        await repository.create(record);
      } else {
        await repository.update(record);
      }
      return null;
    } catch (e) {
      debugPrint('ERRO AO SALVAR GLICEMIA: $e');
      return const DatabaseConnectionException(
        'Não foi possível salvar o registro. Tente novamente.',
      ).message;
    }
  }

  /// Exclui um registro. Retorna `true` se a exclusão foi bem-sucedida.
  Future<bool> delete(int id) async {
    try {
      final affectedRows = await repository.delete(id);
      return affectedRows > 0;
    } catch (e) {
      debugPrint('ERRO AO EXCLUIR GLICEMIA: $e');
      return false;
    }
  }
}

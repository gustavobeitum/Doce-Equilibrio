import 'package:doce_equilibrio/core/errors/auth_exceptions.dart';
import 'package:doce_equilibrio/features/auth/models/user_model.dart';
import 'package:doce_equilibrio/features/auth/repositories/user_repository_interface.dart';
import 'package:flutter/foundation.dart';

/// Controller responsável pelas configurações de perfil que não são o
/// cadastro/login em si: Metas Glicêmicas (RF-010) e Parâmetros de
/// Insulina (RF-002 / UC-05, UC-06, UC-07).
class ProfileController {
  final UserRepositoryInterface repository;

  ProfileController(this.repository);

  /// Atualiza os 4 limiares de classificação de glicemia do usuário.
  /// Retorna `null` em caso de sucesso, ou uma mensagem de erro.
  Future<String?> updateGlycemiaTargets({
    required UserModel currentUser,
    required int lowDangerThreshold,
    required int normalMinimumThreshold,
    required int normalMaximumThreshold,
    required int highDangerThreshold,
  }) async {
    if (!(lowDangerThreshold < normalMinimumThreshold &&
        normalMinimumThreshold < normalMaximumThreshold &&
        normalMaximumThreshold < highDangerThreshold)) {
      return 'Os valores precisam estar em ordem crescente: Perigo Baixo < '
          'Normal Mínimo < Normal Máximo < Perigo Alto.';
    }

    try {
      final updated = UserModel(
        id: currentUser.id,
        name: currentUser.name,
        email: currentUser.email,
        diabetesType: currentUser.diabetesType,
        diagnosisYear: currentUser.diagnosisYear,
        password: currentUser.password,
        salt: currentUser.salt,
        weight: currentUser.weight,
        height: currentUser.height,
        lowDangerThreshold: lowDangerThreshold,
        normalMinimumThreshold: normalMinimumThreshold,
        normalMaximumThreshold: normalMaximumThreshold,
        highDangerThreshold: highDangerThreshold,
        sensitivityFactor: currentUser.sensitivityFactor,
        correctionFactor: currentUser.correctionFactor,
        glycemiaTarget: currentUser.glycemiaTarget,
      );
      await repository.update(updated);
      return null;
    } catch (e) {
      debugPrint('ERRO AO SALVAR METAS GLICÊMICAS: $e');
      return const DatabaseConnectionException(
        'Não foi possível salvar as metas. Tente novamente.',
      ).message;
    }
  }

  /// Atualiza os parâmetros usados no cálculo de insulina.
  /// Retorna `null` em caso de sucesso, ou uma mensagem de erro.
  Future<String?> updateInsulinParameters({
    required UserModel currentUser,
    required double sensitivityFactor,
    required double correctionFactor,
    required int glycemiaTarget,
  }) async {
    try {
      final updated = UserModel(
        id: currentUser.id,
        name: currentUser.name,
        email: currentUser.email,
        diabetesType: currentUser.diabetesType,
        diagnosisYear: currentUser.diagnosisYear,
        password: currentUser.password,
        salt: currentUser.salt,
        weight: currentUser.weight,
        height: currentUser.height,
        lowDangerThreshold: currentUser.lowDangerThreshold,
        normalMinimumThreshold: currentUser.normalMinimumThreshold,
        normalMaximumThreshold: currentUser.normalMaximumThreshold,
        highDangerThreshold: currentUser.highDangerThreshold,
        sensitivityFactor: sensitivityFactor,
        correctionFactor: correctionFactor,
        glycemiaTarget: glycemiaTarget,
      );
      await repository.update(updated);
      return null;
    } catch (e) {
      debugPrint('ERRO AO SALVAR PARÂMETROS DE INSULINA: $e');
      return const DatabaseConnectionException(
        'Não foi possível salvar os parâmetros. Tente novamente.',
      ).message;
    }
  }
}

import 'dart:async';

import 'package:doce_equilibrio/core/history/history_period.dart';
import 'package:doce_equilibrio/core/services/session_service.dart';
import 'package:doce_equilibrio/features/auth/models/user_model.dart';
import 'package:doce_equilibrio/features/auth/repositories/user_repository_interface.dart';
import 'package:doce_equilibrio/features/charts/controllers/charts_controller.dart';
import 'package:doce_equilibrio/features/glycemia/controllers/glycemia_controller.dart';
import 'package:doce_equilibrio/features/glycemia/models/glycemia_record_model.dart';
import 'package:doce_equilibrio/features/glycemia/repositories/glycemia_repository_interface.dart';
import 'package:doce_equilibrio/features/settings/controllers/profile_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

void main() {
  late _GlycemiaRepository repository;
  late _UserRepository users;
  late _Session session;
  late ChartsController controller;

  setUp(() {
    repository = _GlycemiaRepository();
    users = _UserRepository();
    session = _Session();
    when(() => session.getCurrentUserId()).thenAnswer((_) async => 7);
    when(() => users.find(7)).thenAnswer((_) async => _user);
    controller = ChartsController(
      GlycemiaController(repository, session),
      ProfileController(users, session),
    );
  });

  test(
    'carrega período personalizado e preserva isolamento por usuário',
    () async {
      final range = HistoryDateRange.forPeriod(
        HistoryPeriod.custom,
        customStart: DateTime(2026, 8, 1),
        customEnd: DateTime(2026, 8, 5),
      );
      when(
        () => repository.listByPeriod(7, range.start, range.end),
      ).thenAnswer((_) async => [_record(100)]);

      await controller.changePeriod(HistoryPeriod.custom, range: range);

      expect(controller.period, HistoryPeriod.custom);
      expect(controller.data?.records.single.value, 100);
      verify(
        () => repository.listByPeriod(7, range.start, range.end),
      ).called(1);
    },
  );

  test('distingue loading, sucesso e vazio', () async {
    final range = HistoryDateRange.forPeriod(HistoryPeriod.last7Days);
    final completer = Completer<List<GlycemiaRecordModel>>();
    when(
      () => repository.listByPeriod(7, range.start, range.end),
    ).thenAnswer((_) => completer.future);

    final loading = controller.changePeriod(HistoryPeriod.last7Days);
    expect(controller.isLoading, isTrue);
    completer.complete(const []);
    await loading;

    expect(controller.isLoading, isFalse);
    expect(controller.errorMessage, isNull);
    expect(controller.data?.isEmpty, isTrue);
  });

  test('mantém erro separado de estado vazio', () async {
    final range = HistoryDateRange.forPeriod(HistoryPeriod.last90Days);
    when(
      () => repository.listByPeriod(7, range.start, range.end),
    ).thenThrow(Exception('falha'));

    await controller.changePeriod(HistoryPeriod.last90Days);

    expect(controller.isLoading, isFalse);
    expect(controller.data, isNull);
    expect(controller.errorMessage, isNotNull);
  });
}

class _GlycemiaRepository extends Mock implements GlycemiaRepositoryInterface {}

class _UserRepository extends Mock implements UserRepositoryInterface {}

class _Session extends Mock implements SessionService {}

final _user = UserModel(
  id: 7,
  name: 'Pessoa',
  email: 'pessoa@teste.com',
  diabetesType: 'Tipo 1',
  diagnosisYear: 2020,
  password: 'hash',
  salt: 'salt',
  normalMinimumThreshold: 70,
  highDangerThreshold: 180,
);

GlycemiaRecordModel _record(int value) => GlycemiaRecordModel(
  userId: 7,
  value: value,
  period: 'Jejum',
  dateTime: DateTime(2026, 8, 2),
);

import 'dart:async';

import 'package:doce_equilibrio/core/history/history_period.dart';
import 'package:doce_equilibrio/core/services/session_service.dart';
import 'package:doce_equilibrio/features/glycemia/controllers/glycemia_controller.dart';
import 'package:doce_equilibrio/features/glycemia/models/glycemia_record_model.dart';
import 'package:doce_equilibrio/features/glycemia/repositories/glycemia_repository_interface.dart';
import 'package:doce_equilibrio/features/hba1c/controllers/hba1c_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

void main() {
  late _Repository repository;
  late _Session session;
  late HbA1cController controller;
  final now = DateTime(2026, 8, 19, 14, 30);
  final expectedRange = HistoryDateRange.forPeriod(
    HistoryPeriod.last90Days,
    now: now,
  );

  setUp(() {
    repository = _Repository();
    session = _Session();
    when(() => session.getCurrentUserId()).thenAnswer((_) async => 7);
    controller = HbA1cController(
      GlycemiaController(repository, session),
      now: () => now,
    );
  });

  test('consulta usuário atual nos 90 dias incluindo dias completos', () async {
    when(
      () => repository.listByPeriod(7, expectedRange.start, expectedRange.end),
    ).thenAnswer((_) async => [_record(140)]);

    await controller.load();

    expect(expectedRange.start, DateTime(2026, 5, 22));
    expect(expectedRange.end, DateTime(2026, 8, 19, 23, 59, 59, 999, 999));
    expect(controller.estimate?.averageGlycemiaMgDl, 140);
    verify(
      () => repository.listByPeriod(7, expectedRange.start, expectedRange.end),
    ).called(1);
  });

  test('distingue loading, sucesso e vazio', () async {
    final completer = Completer<List<GlycemiaRecordModel>>();
    when(
      () => repository.listByPeriod(7, expectedRange.start, expectedRange.end),
    ).thenAnswer((_) => completer.future);

    final loading = controller.load();
    expect(controller.isLoading, isTrue);
    completer.complete(const []);
    await loading;

    expect(controller.isLoading, isFalse);
    expect(controller.errorMessage, isNull);
    expect(controller.estimate, isNull);
    expect(controller.analyzedRange?.start, expectedRange.start);
    expect(controller.analyzedRange?.end, expectedRange.end);
  });

  test('mantém erro separado da ausência de registros', () async {
    when(
      () => repository.listByPeriod(7, expectedRange.start, expectedRange.end),
    ).thenThrow(Exception('falha'));

    await controller.load();

    expect(controller.isLoading, isFalse);
    expect(controller.estimate, isNull);
    expect(controller.analyzedRange, isNull);
    expect(controller.errorMessage, isNotNull);
  });
}

class _Repository extends Mock implements GlycemiaRepositoryInterface {}

class _Session extends Mock implements SessionService {}

GlycemiaRecordModel _record(int value) => GlycemiaRecordModel(
  userId: 7,
  value: value,
  period: 'Jejum',
  dateTime: DateTime(2026, 8, 1),
);

import 'dart:async';
import 'dart:typed_data';

import 'package:doce_equilibrio/core/history/history_period.dart';
import 'package:doce_equilibrio/features/auth/models/user_model.dart';
import 'package:doce_equilibrio/features/glycemia/controllers/glycemia_controller.dart';
import 'package:doce_equilibrio/features/glycemia/models/glycemia_record_model.dart';
import 'package:doce_equilibrio/features/insulin/controllers/insulin_application_controller.dart';
import 'package:doce_equilibrio/features/insulin/models/insulin_application_model.dart';
import 'package:doce_equilibrio/features/meals/controllers/meal_controller.dart';
import 'package:doce_equilibrio/features/meals/models/meal_model.dart';
import 'package:doce_equilibrio/features/meals/models/meal_type.dart';
import 'package:doce_equilibrio/features/reports/controllers/report_controller.dart';
import 'package:doce_equilibrio/features/reports/models/report_data.dart';
import 'package:doce_equilibrio/features/reports/services/report_pdf_service.dart';
import 'package:doce_equilibrio/features/reports/services/report_share_service.dart';
import 'package:doce_equilibrio/features/settings/controllers/profile_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

void main() {
  setUpAll(() {
    registerFallbackValue(_ReportDataFake());
    registerFallbackValue(Uint8List(0));
  });
  late _GlycemiaController glycemia;
  late _InsulinController insulin;
  late _MealController meals;
  late _ProfileController profile;
  late _PdfService pdf;
  late _ShareService share;
  late ReportController controller;
  final now = DateTime(2026, 8, 19, 14);
  final reportRange = HistoryDateRange.forPeriod(
    HistoryPeriod.last30Days,
    now: now,
  );
  final hba1cRange = HistoryDateRange.forPeriod(
    HistoryPeriod.last90Days,
    now: now,
  );

  setUp(() {
    glycemia = _GlycemiaController();
    insulin = _InsulinController();
    meals = _MealController();
    profile = _ProfileController();
    pdf = _PdfService();
    share = _ShareService();
    controller = ReportController(
      glycemia,
      insulin,
      meals,
      profile,
      pdf,
      share,
      now: () => now,
    );
    when(() => profile.loadCurrentUser()).thenAnswer((_) async => _user);
    when(
      () => glycemia.listHistoryByPeriod(hba1cRange.start, hba1cRange.end),
    ).thenAnswer((_) async => [_glycemia(126)]);
    when(
      () => pdf.generate(any()),
    ).thenAnswer((_) async => Uint8List.fromList([1, 2, 3]));
  });

  void stubPeriod(
    HistoryDateRange range,
    List<GlycemiaRecordModel> records,
    List<InsulinApplicationModel> applications,
    List<MealModel> mealRecords,
  ) {
    when(
      () => glycemia.listHistoryByPeriod(range.start, range.end),
    ).thenAnswer((_) async => records);
    when(
      () => insulin.listByPeriod(range.start, range.end),
    ).thenAnswer((_) async => applications);
    when(
      () => meals.listByPeriod(range.start, range.end),
    ).thenAnswer((_) async => mealRecords);
  }

  test(
    'coleta período, usuário, aplicações e refeições e reutiliza HbA1c',
    () async {
      final record = _glycemia(140);
      final application = _application();
      final meal = _meal();
      stubPeriod(reportRange, [record], [application], [meal]);

      await controller.generate();

      expect(controller.data?.user.id, 7);
      expect(controller.data?.glycemia.records.single.value, 140);
      expect(controller.data?.insulinApplications, [application]);
      expect(controller.data?.meals, [meal]);
      expect(controller.data?.hba1c?.averageGlycemiaMgDl, 126);
      expect(controller.pdfBytes, [1, 2, 3]);
      verify(
        () => glycemia.listHistoryByPeriod(reportRange.start, reportRange.end),
      ).called(1);
      verify(
        () => glycemia.listHistoryByPeriod(hba1cRange.start, hba1cRange.end),
      ).called(1);
    },
  );

  test('distingue loading e período sem dados sem gerar PDF', () async {
    final completer = Completer<List<GlycemiaRecordModel>>();
    when(
      () => glycemia.listHistoryByPeriod(reportRange.start, reportRange.end),
    ).thenAnswer((_) => completer.future);
    when(
      () => insulin.listByPeriod(reportRange.start, reportRange.end),
    ).thenAnswer((_) async => const []);
    when(
      () => meals.listByPeriod(reportRange.start, reportRange.end),
    ).thenAnswer((_) async => const []);

    final generating = controller.generate();
    expect(controller.isGenerating, isTrue);
    completer.complete(const []);
    await generating;

    expect(controller.isGenerating, isFalse);
    expect(controller.hasNoData, isTrue);
    expect(controller.pdfBytes, isNull);
    verifyNever(() => pdf.generate(any()));
  });

  test('mantém erro de repository separado do estado vazio', () async {
    when(
      () => glycemia.listHistoryByPeriod(reportRange.start, reportRange.end),
    ).thenThrow(Exception('falha'));

    await controller.generate();

    expect(controller.hasNoData, isFalse);
    expect(controller.errorMessage, isNotNull);
    expect(controller.pdfBytes, isNull);
  });

  test('usa período personalizado e compartilha somente após gerar', () async {
    final custom = HistoryDateRange.forPeriod(
      HistoryPeriod.custom,
      customStart: DateTime(2026, 8, 1),
      customEnd: DateTime(2026, 8, 3),
    );
    controller.changePeriod(HistoryPeriod.custom);
    stubPeriod(custom, [_glycemia(100)], const [], const []);
    when(() => share.share(any(), any())).thenAnswer((_) async => true);

    await controller.generate(range: custom);
    await controller.share();

    verify(() => share.share(any(), 'doce_equilibrio_20260819.pdf')).called(1);
  });
}

class _GlycemiaController extends Mock implements GlycemiaController {}

class _InsulinController extends Mock implements InsulinApplicationController {}

class _MealController extends Mock implements MealController {}

class _ProfileController extends Mock implements ProfileController {}

class _PdfService extends Mock implements ReportPdfService {}

class _ShareService extends Mock implements ReportShareService {}

class _ReportDataFake extends Fake implements ReportData {}

final _user = UserModel(
  id: 7,
  name: 'Pessoa',
  email: 'pessoa@teste.com',
  diabetesType: 'Tipo 1',
  diagnosisYear: 2020,
  password: 'hash',
  salt: 'salt',
);

GlycemiaRecordModel _glycemia(int value) => GlycemiaRecordModel(
  userId: 7,
  value: value,
  period: 'Jejum',
  dateTime: DateTime(2026, 8, 2),
);

InsulinApplicationModel _application() => InsulinApplicationModel(
  userId: 7,
  glycemia: 140,
  carbohydrates: 30,
  carbohydrateDose: 2,
  correctionDose: 1,
  recommendedDose: 3,
  appliedDose: 2.5,
  dateTime: DateTime(2026, 8, 2),
);

MealModel _meal() =>
    MealModel(userId: 7, type: MealType.almoco, dateTime: DateTime(2026, 8, 2));

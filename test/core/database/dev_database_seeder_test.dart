import 'package:doce_equilibrio/core/database/database_connection.dart';
import 'package:doce_equilibrio/core/database/dev_database_seeder.dart';
import 'package:doce_equilibrio/core/utils/encryption_utils.dart';
import 'package:doce_equilibrio/features/glycemia/domain/services/glycemia_classifier.dart';
import 'package:doce_equilibrio/features/hba1c/domain/hba1c_calculator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

class _DatabaseExecutorMock extends Mock implements DatabaseExecutor {}

void main() {
  test('gera cenário completo, relacionado e idempotente de 90 dias', () async {
    final db = _DatabaseExecutorMock();
    final rows = <(String, Map<String, Object?>)>[];
    final ids = <String, int>{};

    when(
      () => db.query(
        any(),
        columns: any(named: 'columns'),
        where: any(named: 'where'),
        whereArgs: any(named: 'whereArgs'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer((invocation) async {
      final table = invocation.positionalArguments.first as String;
      if (table != 'Usuario') return const [];
      return _table(rows, table).map((row) => {'id': row['id']}).toList();
    });
    when(() => db.insert(any(), any())).thenAnswer((invocation) async {
      final table = invocation.positionalArguments[0] as String;
      final values = Map<String, Object?>.from(
        invocation.positionalArguments[1] as Map<String, Object?>,
      );
      final id = (ids[table] ?? 0) + 1;
      ids[table] = id;
      values['id'] = id;
      rows.add((table, values));
      return id;
    });

    final seeder = DevDatabaseSeeder(DatabaseConnection());
    final reference = DateTime(2026, 8, 20, 14);
    final result = await seeder.seed(executor: db, referenceDate: reference);

    expect(result.status, DevSeedStatus.created);
    expect(result.glycemias, 248);
    expect(result.foods, 12);
    expect(result.meals, 151);
    expect(result.mealItems, 302);
    expect(result.insulinApplications, 45);
    expect(result.medications, 3);
    expect(result.reminders, 4);
    expect(result.activities, 30);
    for (final table in [
      'Usuario',
      'Glicemia',
      'Alimento',
      'Refeicao',
      'RefeicaoItem',
      'AplicacaoInsulina',
      'Medicamento',
      'Lembrete',
      'Atividade',
    ]) {
      expect(_table(rows, table), isNotEmpty, reason: table);
    }

    final user = _table(rows, 'Usuario').single;
    final userId = user['id'];
    expect(user['email'], DevDatabaseSeeder.email);
    expect(
      EncryptionUtils.validatePassword(
        enteredPassword: DevDatabaseSeeder.password,
        storedHash: user['senha']! as String,
        salt: user['salt']! as String,
      ),
      isTrue,
    );
    for (final table in [
      'Glicemia',
      'Alimento',
      'Refeicao',
      'AplicacaoInsulina',
      'Medicamento',
      'Lembrete',
      'Atividade',
    ]) {
      expect(
        _table(rows, table).every((row) => row['usuarioId'] == userId),
        isTrue,
        reason: table,
      );
    }

    final mealIds = _table(rows, 'Refeicao').map((row) => row['id']).toSet();
    final foodIds = _table(rows, 'Alimento').map((row) => row['id']).toSet();
    final medicationIds = _table(
      rows,
      'Medicamento',
    ).map((row) => row['id']).toSet();
    expect(
      _table(rows, 'RefeicaoItem').every(
        (row) =>
            mealIds.contains(row['refeicaoId']) &&
            foodIds.contains(row['alimentoId']),
      ),
      isTrue,
    );
    expect(
      _table(rows, 'AplicacaoInsulina').every(
        (row) =>
            row['refeicaoId'] == null || mealIds.contains(row['refeicaoId']),
      ),
      isTrue,
    );
    expect(
      _table(rows, 'Lembrete').every(
        (row) =>
            row['medicamentoId'] == null ||
            medicationIds.contains(row['medicamentoId']),
      ),
      isTrue,
    );

    final glycemias = _table(rows, 'Glicemia');
    final values = glycemias.map((row) => row['valor']! as int).toList();
    expect(
      values.map(GlycemiaClassifier.classify).toSet(),
      GlycemiaLevel.values.toSet(),
    );
    expect(const HbA1cCalculator().calculate(values), isNotNull);
    final dates =
        glycemias
            .map((row) => DateTime.parse(row['dataHora']! as String))
            .toList()
          ..sort();
    expect(dates.last.difference(dates.first).inDays, greaterThanOrEqualTo(89));
    expect(_table(rows, 'Refeicao').any((row) => row['favorita'] == 1), isTrue);
    expect(_table(rows, 'Refeicao').map((row) => row['tipo']).toSet(), {
      'cafeDaManha',
      'almoco',
      'jantar',
      'lanche',
    });
    expect(_table(rows, 'Lembrete').map((row) => row['ativo']).toSet(), {0, 1});
    expect(result.hba1cPercentage, isNotNull);

    final rowCount = rows.length;
    final second = await seeder.seed(executor: db, referenceDate: reference);
    expect(second.status, DevSeedStatus.alreadyExists);
    expect(rows, hasLength(rowCount));
  });
}

List<Map<String, Object?>> _table(
  List<(String, Map<String, Object?>)> rows,
  String table,
) {
  return rows
      .where((entry) => entry.$1 == table)
      .map((entry) => entry.$2)
      .toList();
}

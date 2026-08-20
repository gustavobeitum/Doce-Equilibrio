import 'package:doce_equilibrio/core/database/migrations/final_features_migration.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

class _DatabaseExecutorMock extends Mock implements DatabaseExecutor {}

void main() {
  test('versão 13 adiciona colunas opcionais sem remover dados', () async {
    final db = _DatabaseExecutorMock();
    final statements = <String>[];
    when(() => db.rawQuery(any())).thenAnswer((_) async => []);
    when(() => db.execute(any())).thenAnswer((invocation) async {
      statements.add(invocation.positionalArguments.first as String);
    });

    await FinalFeaturesMigration.migrate(db, oldVersion: 12, newVersion: 13);

    final sql = statements.join('\n');
    expect(sql, contains('Atividade ADD COLUMN intensidade TEXT'));
    expect(sql, contains('Lembrete ADD COLUMN medicamentoId INTEGER'));
    expect(sql, contains('ON DELETE SET NULL'));
    expect(sql.toUpperCase(), isNot(contains('DROP TABLE')));
    expect(sql.toUpperCase(), isNot(contains('DELETE FROM')));
  });

  test('não repete migration em banco já atualizado', () async {
    final db = _DatabaseExecutorMock();

    await FinalFeaturesMigration.migrate(db, oldVersion: 13, newVersion: 13);

    verifyNever(() => db.rawQuery(any()));
    verifyNever(() => db.execute(any()));
  });
}

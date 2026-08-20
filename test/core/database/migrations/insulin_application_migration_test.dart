import 'package:doce_equilibrio/core/database/migrations/insulin_application_migration.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

class _DatabaseExecutorMock extends Mock implements DatabaseExecutor {}

void main() {
  late _DatabaseExecutorMock db;
  late List<String> statements;

  setUp(() {
    db = _DatabaseExecutorMock();
    statements = [];
    when(() => db.execute(any())).thenAnswer((invocation) async {
      statements.add(invocation.positionalArguments.first as String);
    });
  });

  test('migra da versão anterior para 12 somente com SQL aditivo', () async {
    await InsulinApplicationMigration.migrate(
      db,
      oldVersion: 11,
      newVersion: 12,
    );

    expect(statements, hasLength(3));
    expect(statements.first, contains('CREATE TABLE IF NOT EXISTS'));
    expect(statements.first, contains('AplicacaoInsulina'));
    expect(statements.first, contains('ON DELETE SET NULL'));
    expect(statements.join('\n').toUpperCase(), isNot(contains('DROP TABLE')));
    expect(statements.join('\n').toUpperCase(), isNot(contains('DELETE FROM')));
  });

  test('migration é idempotente para banco que já está na versão 12', () async {
    await InsulinApplicationMigration.migrate(
      db,
      oldVersion: 12,
      newVersion: 12,
    );

    verifyNever(() => db.execute(any()));
  });
}

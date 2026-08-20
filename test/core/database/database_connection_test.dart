import 'package:doce_equilibrio/core/database/database_connection.dart';
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

  void expectColumns(String table, List<String> columns) {
    final sql = statements.firstWhere(
      (statement) => statement.contains('CREATE TABLE $table ('),
    );
    for (final column in columns) {
      expect(sql, contains(RegExp('\\b$column\\b')));
    }
  }

  test('habilita foreign keys na configuração da conexão', () async {
    await DatabaseConnection().configureForTesting(db);

    expect(statements, ['PRAGMA foreign_keys = ON']);
  });

  test(
    'instalação limpa cria todas as tabelas na ordem das dependências',
    () async {
      await DatabaseConnection().createSchemaForTesting(db);

      final tables = statements
          .where((sql) => sql.trimLeft().startsWith('CREATE TABLE'))
          .map(_createdObjectName)
          .toList();

      expect(tables, [
        'Usuario',
        'Alimento',
        'Refeicao',
        'RefeicaoItem',
        'Glicemia',
        'Atividade',
        'Medicamento',
        'Lembrete',
        'AplicacaoInsulina',
      ]);
    },
  );

  test('schema consolidado contém todas as colunas finais', () async {
    await DatabaseConnection().createSchemaForTesting(db);

    expectColumns('Usuario', [
      'id',
      'nome',
      'email',
      'tipoDiabetes',
      'anoDiagnostico',
      'senha',
      'salt',
      'peso',
      'altura',
      'limitePerigoBaixo',
      'limiteNormalMinimo',
      'limiteNormalMaximo',
      'limitePerigoAlto',
      'fatorSensibilidade',
      'fatorCorrecao',
      'metaGlicemica',
    ]);
    expectColumns('Glicemia', [
      'id',
      'usuarioId',
      'valor',
      'periodo',
      'dataHora',
      'observacao',
    ]);
    expectColumns('Alimento', [
      'id',
      'usuarioId',
      'nome',
      'carboidratosPor100g',
      'porcaoQuantidade',
      'porcaoUnidade',
      'carboidratosPorPorcao',
    ]);
    expectColumns('Refeicao', [
      'id',
      'usuarioId',
      'tipo',
      'dataHora',
      'favorita',
    ]);
    expectColumns('RefeicaoItem', [
      'id',
      'refeicaoId',
      'alimentoId',
      'nomeAlimento',
      'carboidratosPor100g',
      'quantidadeGramas',
      'porcaoQuantidade',
      'porcaoUnidade',
      'carboidratosPorPorcao',
      'quantidadeConsumida',
    ]);
    expectColumns('Atividade', [
      'id',
      'usuarioId',
      'tipo',
      'duracaoMinutos',
      'dataHora',
      'intensidade',
      'observacao',
    ]);
    expectColumns('Medicamento', [
      'id',
      'usuarioId',
      'nome',
      'dosagem',
      'dataHora',
      'observacao',
    ]);
    expectColumns('Lembrete', [
      'id',
      'usuarioId',
      'tipo',
      'titulo',
      'hora',
      'minuto',
      'repetir',
      'diasSemana',
      'data',
      'ativo',
      'medicamentoId',
    ]);
    expectColumns('AplicacaoInsulina', [
      'id',
      'usuarioId',
      'glicemia',
      'carboidratos',
      'doseAlimentar',
      'doseCorrecao',
      'doseRecomendada',
      'doseAplicada',
      'dataHora',
      'observacao',
      'refeicaoId',
    ]);
  });

  test('cria todas as foreign keys e índices finais', () async {
    await DatabaseConnection().createSchemaForTesting(db);
    final sql = statements.join('\n');
    final indexes = statements
        .where((statement) => statement.startsWith('CREATE INDEX'))
        .map(_createdObjectName)
        .toSet();

    expect(RegExp(r'FOREIGN KEY').allMatches(sql), hasLength(11));
    expect(sql, contains('ON DELETE CASCADE'));
    expect(sql, contains('ON DELETE SET NULL'));
    expect(indexes, {
      'idx_glicemia_user_data',
      'idx_alimento_user',
      'idx_refeicao_user_data',
      'idx_refeicaoitem_refeicao',
      'idx_atividade_user_data',
      'idx_medicamento_user_data',
      'idx_lembrete_user',
      'idx_lembrete_medicamento',
      'idx_aplicacao_insulina_user_data',
      'idx_aplicacao_insulina_refeicao',
    });
    expect(sql.toUpperCase(), isNot(contains('ALTER TABLE')));
    expect(sql.toUpperCase(), isNot(contains('DROP TABLE')));
  });
}

String _createdObjectName(String sql) {
  final tokens = sql.trim().split(RegExp(r'\s+'));
  return tokens[2];
}

// Classe criada pela IA para testar o calculo do saldo provisorio do modo offline.
import 'package:flutter_test/flutter_test.dart';
import 'package:iceibank_mobile/modelos/operacao_pendente.dart';
import 'package:iceibank_mobile/servicos/regras_offline.dart';

OperacaoPendente op(TipoOperacao tipo, double valor, [StatusOperacao status = StatusOperacao.pendente]) =>
    OperacaoPendente(
      idLocal: '$tipo$valor',
      idConta: 1,
      tipo: tipo,
      valor: valor,
      vetorConhecido: const [0, 0, 0],
      criadoEm: DateTime(2026),
      status: status,
    );

void main() {
  test('soma depositos e subtrai saques pendentes', () {
    final fila = [op(TipoOperacao.deposito, 50), op(TipoOperacao.saque, 20)];

    expect(saldoProvisorio(100, fila), 130);
  });

  test('operacoes em conflito ou que falharam nao entram no saldo provisorio', () {
    final fila = [
      op(TipoOperacao.deposito, 50, StatusOperacao.conflito),
      op(TipoOperacao.saque, 20, StatusOperacao.falhou),
      op(TipoOperacao.deposito, 5),
    ];

    expect(saldoProvisorio(100, fila), 105);
  });

  test('operacao sobrevive a ida e volta pelo mapa do Hive', () {
    final original = op(TipoOperacao.saque, 12.5);
    final lida = OperacaoPendente.deMapa(Map<dynamic, dynamic>.from(original.paraMapa()));

    expect(lida.tipo, TipoOperacao.saque);
    expect(lida.valor, 12.5);
    expect(lida.vetorConhecido, [0, 0, 0]);
    expect(lida.status, StatusOperacao.pendente);
  });
}

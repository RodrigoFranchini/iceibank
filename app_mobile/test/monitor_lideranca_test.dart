// Classe criada pela IA para testar o fallback entre agencias do MonitorLideranca.
import 'package:flutter_test/flutter_test.dart';
import 'package:iceibank_mobile/servicos/api_excecao.dart';
import 'package:iceibank_mobile/servicos/monitor_lideranca.dart';

void main() {
  test('ordem comeca pela ultima agencia que respondeu', () {
    expect(ordemDeTentativa(0), [0, 1, 2]);
    expect(ordemDeTentativa(2), [2, 0, 1]);
  });

  test('tenta as outras agencias e passa a comecar pela que respondeu', () async {
    final tentadas = <int>[];
    var foraDoAr = {0};
    final monitor = MonitorLideranca((agencia) async {
      tentadas.add(agencia);
      if (foraDoAr.contains(agencia)) throw SemConexaoExcecao(agencia);
      return 2;
    });

    await monitor.verificar();
    expect(tentadas, [0, 1]);
    expect(monitor.agenciaQueRespondeu, 1);
    expect(monitor.lider, 2);

    tentadas.clear();
    foraDoAr = {};
    await monitor.verificar();
    expect(tentadas, [1]);
  });

  test('nenhuma agencia respondendo deixa agenciaQueRespondeu nula', () async {
    final monitor = MonitorLideranca((agencia) async => throw SemConexaoExcecao(agencia));

    await monitor.verificar();
    expect(monitor.verificou, isTrue);
    expect(monitor.agenciaQueRespondeu, isNull);
  });

  test('lider nulo significa eleicao em andamento', () async {
    final monitor = MonitorLideranca((_) async => null);

    await monitor.verificar();
    expect(monitor.agenciaQueRespondeu, 0);
    expect(monitor.lider, isNull);
  });
}

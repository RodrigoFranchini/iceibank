// Classe criada pela IA para testar a fila offline: enfileiramento, encadeamento do vetor e conflito 409.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:iceibank_mobile/modelos/operacao_pendente.dart';
import 'package:iceibank_mobile/servicos/api_cliente.dart';
import 'package:iceibank_mobile/servicos/api_excecao.dart';
import 'package:iceibank_mobile/servicos/contas_offline.dart';

import 'apoio_hive.dart';

http.Response json(Object corpo, [int status = 200]) => http.Response.bytes(utf8.encode(jsonEncode(corpo)), status);

void main() {
  late ContasOffline contas;
  late List<Map<String, dynamic>> enviados;
  late bool agenciaNoAr;
  late http.Response Function(Map<String, dynamic> corpo) responderSincronizar;

  setUp(() async {
    enviados = [];
    agenciaNoAr = true;
    final api = ApiCliente(
      host: () => 'localhost',
      token: () => 't',
      cliente: MockClient((req) async {
        if (!agenciaNoAr) throw http.ClientException('recusado');
        if (req.url.path.endsWith('/sincronizar')) {
          final corpo = jsonDecode(req.body) as Map<String, dynamic>;
          enviados.add(corpo);
          return responderSincronizar(corpo);
        }
        return json({'id': 1, 'nomeAluno': 'Ana', 'saldo': 100, 'vetorAtual': [0, 4, 0]});
      }),
    );
    contas = ContasOffline(api: api, armazenamento: await abrirArmazenamentoTemporario());
    await contas.consultar(1);
    agenciaNoAr = false;
  });

  test('sem resposta da agencia o deposito vai para a fila com o vetor do cache', () async {
    await contas.depositar(1, 30);

    final fila = contas.fila;
    expect(fila.single.tipo, TipoOperacao.deposito);
    expect(fila.single.vetorConhecido, [0, 4, 0]);
  });

  test('conta nunca consultada nao pode operar offline', () async {
    await expectLater(contas.depositar(2, 10), throwsA(isA<OfflineExcecao>()));
  });

  test('saque offline respeita o saldo provisorio', () async {
    await contas.depositar(1, 30);

    await expectLater(contas.sacar(1, 131), throwsA(isA<OfflineExcecao>()));
    await contas.sacar(1, 130);
    expect(contas.fila, hasLength(2));
  });

  test('a segunda operacao usa o vetor devolvido pela primeira', () async {
    await contas.depositar(1, 30);
    await contas.sacar(1, 10);
    var vetor = [0, 4, 0];
    responderSincronizar = (corpo) {
      vetor = [0, vetor[1] + 1, 0];
      return json({'id': 1, 'nomeAluno': 'Ana', 'saldo': 0, 'vetorAtual': vetor});
    };
    agenciaNoAr = true;

    await contas.sincronizar();

    expect(enviados.map((c) => c['vetorConhecido']), [
      [0, 4, 0],
      [0, 5, 0],
    ]);
    expect(contas.fila, isEmpty);
    expect(contas.contaEmCache(1)!.conta.vetorAtual, [0, 6, 0]);
  });

  test('conflito marca a operacao, guarda o estado real e segura as seguintes', () async {
    await contas.depositar(1, 30);
    await contas.depositar(1, 5);
    responderSincronizar = (_) => json({
          'erro': 'Conflito detectado: o estado da conta mudou desde a última sincronização do app.',
          'vetorConhecido': [0, 4, 0],
          'vetorAtual': [0, 9, 0],
          'contaAtual': {'id': 1, 'nomeAluno': 'Ana', 'saldo': 70, 'vetorAtual': [0, 9, 0]},
        }, 409);
    agenciaNoAr = true;

    await contas.sincronizar();

    expect(enviados, hasLength(1));
    final conflito = contas.fila.first;
    expect(conflito.status, StatusOperacao.conflito);
    expect(conflito.contaAtual!.saldo, 70);
    expect(contas.contaEmCache(1)!.conta.saldo, 70);

    responderSincronizar = (corpo) => json({'id': 1, 'nomeAluno': 'Ana', 'saldo': 100, 'vetorAtual': [0, 10, 0]});
    await contas.reenviar(conflito);
    expect(enviados[1]['vetorConhecido'], [0, 9, 0]);
  });

  test('erro 400 na sincronizacao marca a operacao como falhou', () async {
    await contas.sacar(1, 50);
    responderSincronizar = (_) => json({'erro': 'Saldo insuficiente.'}, 400);
    agenciaNoAr = true;

    await contas.sincronizar();

    expect(contas.fila.single.status, StatusOperacao.falhou);
    expect(contas.fila.single.erro, 'Saldo insuficiente.');
  });
}

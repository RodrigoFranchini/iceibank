// Classe criada pela IA para testar o roteamento e o tratamento de erros do ApiCliente com um cliente HTTP falso.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:iceibank_mobile/servicos/api_cliente.dart';
import 'package:iceibank_mobile/servicos/api_excecao.dart';

http.Response json(Object corpo, int status) => http.Response.bytes(utf8.encode(jsonEncode(corpo)), status);

ApiCliente criar(MockClientHandler responder, {void Function(String)? aoExpirar}) => ApiCliente(
      host: () => 'localhost',
      token: () => 'abc',
      aoExpirarSessao: aoExpirar,
      cliente: MockClient(responder),
    );

void main() {
  test('consulta vai para a porta da agencia dona da conta e envia o token', () async {
    late http.Request recebida;
    final api = criar((req) async {
      recebida = req;
      return json({'id': 5, 'nomeAluno': 'Ana', 'saldo': 10, 'vetorAtual': [0, 0, 3]}, 200);
    });

    final conta = await api.consultarConta(5);

    expect(recebida.url.port, 4002);
    expect(recebida.headers['Authorization'], 'Bearer abc');
    expect(conta.saldo, 10.0);
    expect(conta.vetorAtual, [0, 0, 3]);
  });

  test('login cai para a proxima agencia quando a anterior nao responde', () async {
    final portas = <int>[];
    final api = criar((req) async {
      portas.add(req.url.port);
      if (req.url.port == 4000) throw http.ClientException('recusado');
      return json({'token': 't1'}, 200);
    });

    expect(await api.login('admin', 'admin123'), 't1');
    expect(portas, [4000, 4001]);
  });

  test('erro da API vira ApiExcecao com a mensagem do campo erro', () async {
    final api = criar((_) async => json({'erro': 'Saldo insuficiente.'}, 400));

    expect(
      () => api.sacar(1, 50),
      throwsA(isA<ApiExcecao>().having((e) => e.mensagem, 'mensagem', 'Saldo insuficiente.')),
    );
  });

  test('401 numa rota autenticada avisa a sessao', () async {
    String? aviso;
    final api = criar((_) async => json({'erro': 'Token inválido ou expirado.'}, 401), aoExpirar: (m) => aviso = m);

    await expectLater(api.consultarConta(3), throwsA(isA<SessaoExpiradaExcecao>()));
    expect(aviso, 'Token inválido ou expirado.');
  });

  test('falha de conexao vira SemConexaoExcecao com a agencia', () async {
    final api = criar((_) async => throw http.ClientException('recusado'));

    expect(
      () => api.depositar(7, 10),
      throwsA(isA<SemConexaoExcecao>().having((e) => e.mensagem, 'mensagem', 'Agência 1 fora do ar.')),
    );
  });
}

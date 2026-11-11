// Classe criada pela IA para acessar a API REST das agencias, enviando cada chamada para a agencia dona da conta.
import 'dart:async';
import 'dart:convert';
import 'dart:io' show SocketException;

import 'package:http/http.dart' as http;

import '../config.dart';
import '../modelos/conta.dart';
import '../modelos/operacao_pendente.dart';
import 'api_excecao.dart';

class ApiCliente {
  ApiCliente({
    required this.host,
    required this.token,
    this.aoExpirarSessao,
    http.Client? cliente,
  }) : _http = cliente ?? http.Client();

  final String Function() host;
  final String? Function() token;

  /// Chamado com a mensagem da API quando uma rota autenticada devolve 401.
  final void Function(String mensagem)? aoExpirarSessao;

  final http.Client _http;

  /// Tenta a agencia 0 e cai para 1 e 2 se ela nao responder; o JWT vale em todas.
  Future<String> login(String usuario, String senha) async {
    for (var agencia = 0; agencia < totalAgencias; agencia++) {
      try {
        final corpo = await _enviar(agencia, 'POST', '/auth/login',
            corpo: {'usuario': usuario, 'senha': senha}, autenticado: false);
        return corpo['token'] as String;
      } on SemConexaoExcecao {
        continue;
      }
    }
    throw const SemConexaoExcecao();
  }

  Future<Conta> consultarConta(int id) async =>
      Conta.deJson(await _enviar(agenciaDaConta(id), 'GET', '/contas/$id'));

  Future<Conta> depositar(int id, double valor) async => Conta.deJson(
      await _enviar(agenciaDaConta(id), 'POST', '/contas/$id/depositar', corpo: {'valor': valor}));

  Future<Conta> sacar(int id, double valor) async => Conta.deJson(
      await _enviar(agenciaDaConta(id), 'POST', '/contas/$id/sacar', corpo: {'valor': valor}));

  /// Vai para a agencia da conta de origem; devolve a mensagem da API.
  Future<String> transferir(int idOrigem, int idDestino, double valor) async {
    final corpo = await _enviar(agenciaDaConta(idOrigem), 'POST', '/transferencias',
        corpo: {'idOrigem': idOrigem, 'idDestino': idDestino, 'valor': valor});
    return corpo['mensagem'] as String? ?? 'Transferência realizada.';
  }

  /// Aplica uma operacao feita offline; 409 vira ConflitoExcecao com o estado real da conta.
  Future<Conta> sincronizar(OperacaoPendente op) async {
    try {
      return Conta.deJson(await _enviar(agenciaDaConta(op.idConta), 'POST', '/contas/${op.idConta}/sincronizar',
          corpo: {'tipo': op.tipo.api, 'valor': op.valor, 'vetorConhecido': op.vetorConhecido}));
    } on ApiExcecao catch (e) {
      final contaAtual = e.corpo['contaAtual'];
      if (e.status == 409 && contaAtual is Map<String, dynamic>) {
        throw ConflitoExcecao(e.mensagem, Conta.deJson(contaAtual));
      }
      rethrow;
    }
  }

  /// Lider que a [agencia] conhece; null quando ha eleicao em andamento.
  Future<int?> consultarLider(int agencia) async {
    final corpo = await _enviar(agencia, 'GET', '/bully/lider', autenticado: false);
    return (corpo['liderAtual'] as num?)?.toInt();
  }

  Future<Map<String, dynamic>> _enviar(
    int agencia,
    String metodo,
    String caminho, {
    Map<String, Object?>? corpo,
    bool autenticado = true,
  }) async {
    final requisicao = http.Request(metodo, Uri.http('${host()}:${portaDaAgencia(agencia)}', caminho));
    final tokenAtual = token();
    if (autenticado && tokenAtual != null) {
      requisicao.headers['Authorization'] = 'Bearer $tokenAtual';
    }
    if (corpo != null) {
      requisicao.headers['Content-Type'] = 'application/json';
      requisicao.body = jsonEncode(corpo);
    }

    final http.Response resposta;
    try {
      resposta = await _http.send(requisicao).then(http.Response.fromStream).timeout(tempoLimiteRequisicao);
    } on TimeoutException {
      throw SemConexaoExcecao(agencia);
    } on SocketException {
      throw SemConexaoExcecao(agencia);
    } on http.ClientException {
      throw SemConexaoExcecao(agencia);
    }

    final dados = _decodificar(resposta);
    if (resposta.statusCode >= 200 && resposta.statusCode < 300) return dados;

    final mensagem = dados['erro'] as String? ?? 'Erro HTTP ${resposta.statusCode} na agência $agencia.';
    if (resposta.statusCode == 401 && autenticado) {
      aoExpirarSessao?.call(mensagem);
      throw SessaoExpiradaExcecao(mensagem);
    }
    throw ApiExcecao(resposta.statusCode, mensagem, dados);
  }

  /// O corpo e lido como UTF-8 porque as mensagens tem acento.
  Map<String, dynamic> _decodificar(http.Response resposta) {
    try {
      final json = jsonDecode(utf8.decode(resposta.bodyBytes));
      return json is Map<String, dynamic> ? json : {};
    } on FormatException {
      return {};
    }
  }
}

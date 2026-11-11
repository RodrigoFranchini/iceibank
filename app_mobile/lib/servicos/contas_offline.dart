// Classe criada pela IA para o modo offline-first: cache das contas, fila de operacoes pendentes e sincronizacao automatica.
import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import '../config.dart';
import '../modelos/conta.dart';
import '../modelos/conta_em_cache.dart';
import '../modelos/operacao_pendente.dart';
import '../util/formato.dart';
import 'api_cliente.dart';
import 'api_excecao.dart';
import 'armazenamento_local.dart';
import 'regras_offline.dart';

class ContasOffline extends ChangeNotifier {
  ContasOffline({
    required this.api,
    required this.armazenamento,
    this.intervaloRetentativa = const Duration(seconds: 5),
  });

  final ApiCliente api;
  final ArmazenamentoLocal armazenamento;

  /// Retentativa enquanto houver fila: cobre "rede ok mas agencia fora do ar",
  /// que o connectivity_plus nao enxerga.
  final Duration intervaloRetentativa;

  /// Ultimo estado informado pelo connectivity_plus.
  bool online = true;
  bool sincronizando = false;

  bool _descartado = false;
  Timer? _retentativa;
  StreamSubscription<List<ConnectivityResult>>? _assinatura;

  List<OperacaoPendente> get fila => armazenamento.fila();

  ContaEmCache? contaEmCache(int id) => armazenamento.conta(id);

  List<OperacaoPendente> operacoesDaConta(int id) => fila.where((op) => op.idConta == id).toList();

  Future<void> iniciar(Connectivity conectividade) async {
    _assinatura = conectividade.onConnectivityChanged.listen(_aoMudarConexao);
    _retentativa = Timer.periodic(intervaloRetentativa, (_) {
      if (fila.isNotEmpty) sincronizar();
    });
    _aoMudarConexao(await conectividade.checkConnectivity());
    // Ao abrir o app (ou voltar do login) ja tenta esvaziar a fila.
    await sincronizar();
  }

  void _aoMudarConexao(List<ConnectivityResult> resultados) {
    final conectado = resultados.any((r) => r != ConnectivityResult.none);
    final voltou = conectado && !online;
    online = conectado;
    _avisar();
    if (voltou) sincronizar();
  }

  /// Online consulta a agencia e atualiza o cache; sem resposta usa o cache.
  Future<({ContaEmCache conta, bool emCache})> consultar(int id) async {
    if (online) {
      try {
        return (conta: await _salvarConta(await api.consultarConta(id)), emCache: false);
      } on SemConexaoExcecao {
        // Agencia nao respondeu: segue para o cache.
      }
    }
    final cache = armazenamento.conta(id);
    if (cache == null) {
      throw OfflineExcecao('${_motivo(id)} e a conta $id ainda não foi consultada neste aparelho.');
    }
    return (conta: cache, emCache: true);
  }

  Future<String> depositar(int id, double valor) => _operar(id, TipoOperacao.deposito, valor);

  Future<String> sacar(int id, double valor) => _operar(id, TipoOperacao.saque, valor);

  Future<String> _operar(int id, TipoOperacao tipo, double valor) async {
    // Se a conta ja tem operacao na fila, a nova entra atras dela para manter a ordem.
    if (online && operacoesDaConta(id).isEmpty) {
      try {
        final conta = tipo == TipoOperacao.deposito ? await api.depositar(id, valor) : await api.sacar(id, valor);
        await _atualizarAposEscrita(conta);
        return '${tipo.rotulo} realizado. Novo saldo: ${formatarMoeda(conta.saldo)}.';
      } on SemConexaoExcecao {
        // Agencia nao respondeu: guarda na fila. Erros 4xx sobem normalmente.
      }
    }
    return _enfileirar(id, tipo, valor);
  }

  /// As rotas de escrita nao devolvem vetorAtual; relemos a conta para o cache ficar com a versao certa.
  Future<void> _atualizarAposEscrita(Conta daEscrita) async {
    try {
      await _salvarConta(await api.consultarConta(daEscrita.id));
    } on SemConexaoExcecao {
      // Sem a releitura fica o saldo novo com o vetor antigo; uma operacao offline
      // posterior dara conflito e mostrara o estado real, nunca aplica as cegas.
      final vetorAntigo = armazenamento.conta(daEscrita.id)?.conta.vetorAtual;
      await _salvarConta(Conta(
          id: daEscrita.id, nomeAluno: daEscrita.nomeAluno, saldo: daEscrita.saldo, vetorAtual: vetorAntigo));
    }
  }

  Future<String> _enfileirar(int id, TipoOperacao tipo, double valor) async {
    final cache = armazenamento.conta(id);
    final vetor = cache?.conta.vetorAtual;
    if (cache == null || vetor == null) {
      throw OfflineExcecao(
          '${_motivo(id)}. Consulte o saldo da conta $id enquanto estiver online para poder operar offline.');
    }
    if (tipo == TipoOperacao.saque) {
      final provisorio = saldoProvisorio(cache.conta.saldo, operacoesDaConta(id));
      if (valor > provisorio) {
        throw OfflineExcecao('Saldo insuficiente (saldo provisório: ${formatarMoeda(provisorio)}).');
      }
    }
    final agora = DateTime.now();
    final op = OperacaoPendente(
      idLocal: '${agora.microsecondsSinceEpoch}',
      idConta: id,
      tipo: tipo,
      valor: valor,
      vetorConhecido: vetor,
      criadoEm: agora,
    );
    await armazenamento.salvarOperacao(op);
    _avisar();
    return '${op.descricao} guardado na fila; será sincronizado automaticamente.';
  }

  /// Envia a fila em ordem (FIFO por conta). Uma rodada por vez.
  Future<void> sincronizar() async {
    if (sincronizando || _descartado || !online || fila.isEmpty) return;
    sincronizando = true;
    _avisar();
    try {
      for (final idConta in {for (final op in fila) op.idConta}) {
        if (!await _sincronizarConta(idConta)) break;
      }
    } finally {
      sincronizando = false;
      _avisar();
    }
  }

  /// Devolve false so quando a sessao expirou (a fila fica guardada para depois do login).
  Future<bool> _sincronizarConta(int idConta) async {
    List<int>? vetorDaAnterior;
    for (var op in operacoesDaConta(idConta)) {
      // Conflito ou falha segura as operacoes seguintes da conta ate o usuario decidir.
      if (op.status != StatusOperacao.pendente) return true;
      // A mudanca no vetor foi causada pela nossa propria operacao anterior,
      // entao encadear o vetor devolvido e seguro. Grava antes de enviar para a
      // cadeia sobreviver a uma queda no meio.
      if (vetorDaAnterior != null) {
        op = op.comVetor(vetorDaAnterior);
        await armazenamento.salvarOperacao(op);
      }
      try {
        final conta = await api.sincronizar(op);
        await armazenamento.removerOperacao(op.idLocal);
        await _salvarConta(conta);
        vetorDaAnterior = conta.vetorAtual;
      } on ConflitoExcecao catch (e) {
        // Escolha de projeto: nao reaplica sozinho. Num banco, repetir a operacao
        // sobre um saldo que mudou poderia, por exemplo, deixar a conta negativa;
        // o usuario ve o saldo real e decide entre descartar e reenviar.
        await _salvarConta(e.contaAtual);
        await armazenamento.salvarOperacao(op.comConflito(e.mensagem, e.contaAtual));
        return true;
      } on SessaoExpiradaExcecao {
        return false;
      } on ApiExcecao catch (e) {
        await armazenamento.salvarOperacao(op.comFalha(e.mensagem));
        return true;
      } on SemConexaoExcecao {
        // Agencia fora do ar: tenta de novo na proxima rodada; as outras contas seguem.
        return true;
      } finally {
        _avisar();
      }
    }
    return true;
  }

  Future<void> descartar(OperacaoPendente op) async {
    await armazenamento.removerOperacao(op.idLocal);
    _avisar();
    await sincronizar();
  }

  /// O usuario confirmou aplicar a operacao sobre o saldo real que viu no conflito.
  Future<void> reenviar(OperacaoPendente op) async {
    await armazenamento.salvarOperacao(op.paraReenvio());
    _avisar();
    await sincronizar();
  }

  Future<ContaEmCache> _salvarConta(Conta conta) async {
    final cache = ContaEmCache(conta, DateTime.now());
    await armazenamento.salvarConta(cache);
    return cache;
  }

  String _motivo(int id) => online ? 'Agência ${agenciaDaConta(id)} fora do ar' : 'Sem conexão';

  void _avisar() {
    if (!_descartado) notifyListeners();
  }

  @override
  void dispose() {
    _descartado = true;
    _retentativa?.cancel();
    _assinatura?.cancel();
    super.dispose();
  }
}

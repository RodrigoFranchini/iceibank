// Classe criada pela IA para separar os erros HTTP devolvidos pela agencia dos erros de conexao.
import '../modelos/conta.dart';

/// A agencia respondeu com status de erro; [mensagem] vem do campo "erro".
class ApiExcecao implements Exception {
  const ApiExcecao(this.status, this.mensagem, [this.corpo = const {}]);

  final int status;
  final String mensagem;

  /// Corpo JSON completo da resposta de erro (o 409 traz contaAtual).
  final Map<String, dynamic> corpo;

  @override
  String toString() => mensagem;
}

/// 401 numa rota autenticada: o token foi descartado e o app volta ao login.
class SessaoExpiradaExcecao extends ApiExcecao {
  const SessaoExpiradaExcecao(String mensagem) : super(401, mensagem);
}

/// 409 do /sincronizar: a conta mudou na agencia desde a leitura do app.
class ConflitoExcecao extends ApiExcecao {
  const ConflitoExcecao(String mensagem, this.contaAtual) : super(409, mensagem);

  final Conta contaAtual;
}

/// Operacao que nem pode ser guardada na fila (ex.: conta nunca consultada).
class OfflineExcecao implements Exception {
  const OfflineExcecao(this.mensagem);

  final String mensagem;

  @override
  String toString() => mensagem;
}

/// Nao houve resposta (agencia fora do ar, timeout, sem rede).
class SemConexaoExcecao implements Exception {
  const SemConexaoExcecao([this.agencia]);

  /// Null quando nenhuma das agencias tentadas respondeu.
  final int? agencia;

  String get mensagem =>
      agencia == null ? 'Nenhuma agência respondeu.' : 'Agência $agencia fora do ar.';

  @override
  String toString() => mensagem;
}

/// Converte qualquer erro em texto para a interface.
String mensagemDeErro(Object erro) {
  if (erro is ApiExcecao) return erro.mensagem;
  if (erro is SemConexaoExcecao) return erro.mensagem;
  if (erro is OfflineExcecao) return erro.mensagem;
  if (erro is FormatException) return erro.message;
  return 'Erro inesperado: $erro';
}

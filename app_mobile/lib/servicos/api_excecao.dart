// Classe criada pela IA para separar os erros HTTP devolvidos pela agencia dos erros de conexao.

/// A agencia respondeu com status de erro; [mensagem] vem do campo "erro".
class ApiExcecao implements Exception {
  const ApiExcecao(this.status, this.mensagem);

  final int status;
  final String mensagem;

  @override
  String toString() => mensagem;
}

/// 401 numa rota autenticada: o token foi descartado e o app volta ao login.
class SessaoExpiradaExcecao extends ApiExcecao {
  const SessaoExpiradaExcecao(String mensagem) : super(401, mensagem);
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
  if (erro is FormatException) return erro.message;
  return 'Erro inesperado: $erro';
}

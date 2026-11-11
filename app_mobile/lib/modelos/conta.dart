// Classe criada pela IA para representar a conta devolvida pelas rotas /contas da agencia.
class Conta {
  const Conta({
    required this.id,
    required this.nomeAluno,
    required this.saldo,
    this.vetorAtual,
  });

  final int id;
  final String nomeAluno;
  final double saldo;

  /// So vem no GET /contas/{id}; as rotas de deposito e saque nao devolvem.
  final List<int>? vetorAtual;

  factory Conta.deJson(Map<String, dynamic> json) {
    final vetor = json['vetorAtual'] as List?;
    return Conta(
      id: (json['id'] as num).toInt(),
      nomeAluno: json['nomeAluno'] as String? ?? '',
      saldo: (json['saldo'] as num).toDouble(),
      vetorAtual: vetor?.map((v) => (v as num).toInt()).toList(),
    );
  }

  Map<String, Object?> paraMapa() =>
      {'id': id, 'nomeAluno': nomeAluno, 'saldo': saldo, 'vetorAtual': vetorAtual};
}

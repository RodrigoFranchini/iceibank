// Classe criada pela IA para representar a ultima leitura de uma conta guardada no aparelho.
import 'conta.dart';

class ContaEmCache {
  const ContaEmCache(this.conta, this.atualizadoEm);

  final Conta conta;
  final DateTime atualizadoEm;

  /// Mapa simples para o Hive: {id, nomeAluno, saldo, vetorAtual, atualizadoEm}.
  Map<String, Object?> paraMapa() => {...conta.paraMapa(), 'atualizadoEm': atualizadoEm.toIso8601String()};

  factory ContaEmCache.deMapa(Map mapa) => ContaEmCache(
        Conta.deJson(Map<String, dynamic>.from(mapa)),
        DateTime.parse(mapa['atualizadoEm'] as String),
      );
}

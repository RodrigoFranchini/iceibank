// Classe criada pela IA para as regras puras do modo offline (saldo provisorio), separadas do Hive para teste.
import '../modelos/operacao_pendente.dart';

/// Saldo em cache mais o efeito das operacoes que ainda vao ser enviadas.
/// Operacoes em conflito ou que falharam ficam de fora: elas so voltam a valer
/// se o usuario mandar reenviar.
double saldoProvisorio(double saldoEmCache, Iterable<OperacaoPendente> operacoes) => operacoes
    .where((op) => op.status == StatusOperacao.pendente)
    .fold(saldoEmCache, (saldo, op) => saldo + op.efeito);

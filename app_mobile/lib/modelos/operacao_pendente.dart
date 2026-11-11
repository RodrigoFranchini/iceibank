// Classe criada pela IA para representar um deposito ou saque feito offline que espera sincronizacao.
import '../util/formato.dart';
import 'conta.dart';

enum TipoOperacao {
  deposito('DEPOSITO', 'Depósito'),
  saque('SAQUE', 'Saque');

  const TipoOperacao(this.api, this.rotulo);

  /// Valor do campo "tipo" no /sincronizar.
  final String api;
  final String rotulo;
}

enum StatusOperacao {
  pendente('Pendente'),
  conflito('Conflito'),
  falhou('Falhou');

  const StatusOperacao(this.rotulo);

  final String rotulo;
}

class OperacaoPendente {
  const OperacaoPendente({
    required this.idLocal,
    required this.idConta,
    required this.tipo,
    required this.valor,
    required this.vetorConhecido,
    required this.criadoEm,
    this.status = StatusOperacao.pendente,
    this.erro,
    this.contaAtual,
  });

  final String idLocal;
  final int idConta;
  final TipoOperacao tipo;
  final double valor;

  /// vetorAtual da conta em cache quando a operacao foi criada (ou o devolvido pela anterior).
  final List<int> vetorConhecido;
  final DateTime criadoEm;
  final StatusOperacao status;
  final String? erro;

  /// Estado real da conta devolvido no 409.
  final Conta? contaAtual;

  double get efeito => tipo == TipoOperacao.deposito ? valor : -valor;

  String get descricao => '${tipo.rotulo.toUpperCase()} de ${formatarMoeda(valor)}';

  OperacaoPendente _copiar({
    List<int>? vetorConhecido,
    required StatusOperacao status,
    String? erro,
    Conta? contaAtual,
  }) =>
      OperacaoPendente(
        idLocal: idLocal,
        idConta: idConta,
        tipo: tipo,
        valor: valor,
        vetorConhecido: vetorConhecido ?? this.vetorConhecido,
        criadoEm: criadoEm,
        status: status,
        erro: erro,
        contaAtual: contaAtual,
      );

  OperacaoPendente comVetor(List<int> vetor) => _copiar(vetorConhecido: vetor, status: status);

  OperacaoPendente comConflito(String erro, Conta contaAtual) =>
      _copiar(status: StatusOperacao.conflito, erro: erro, contaAtual: contaAtual);

  OperacaoPendente comFalha(String erro) => _copiar(status: StatusOperacao.falhou, erro: erro);

  /// Volta para a fila usando a versao real da conta que o usuario viu no conflito.
  OperacaoPendente paraReenvio() =>
      _copiar(vetorConhecido: contaAtual?.vetorAtual, status: StatusOperacao.pendente);

  Map<String, Object?> paraMapa() => {
        'idLocal': idLocal,
        'idConta': idConta,
        'tipo': tipo.api,
        'valor': valor,
        'vetorConhecido': vetorConhecido,
        'criadoEm': criadoEm.toIso8601String(),
        'status': status.name.toUpperCase(),
        'erro': erro,
        'contaAtual': contaAtual?.paraMapa(),
      };

  factory OperacaoPendente.deMapa(Map mapa) {
    final contaAtual = mapa['contaAtual'] as Map?;
    return OperacaoPendente(
      idLocal: mapa['idLocal'] as String,
      idConta: mapa['idConta'] as int,
      tipo: TipoOperacao.values.firstWhere((t) => t.api == mapa['tipo']),
      valor: (mapa['valor'] as num).toDouble(),
      vetorConhecido: (mapa['vetorConhecido'] as List).map((v) => (v as num).toInt()).toList(),
      criadoEm: DateTime.parse(mapa['criadoEm'] as String),
      status: StatusOperacao.values.firstWhere((s) => s.name.toUpperCase() == mapa['status']),
      erro: mapa['erro'] as String?,
      contaAtual: contaAtual == null ? null : Conta.deJson(Map<String, dynamic>.from(contaAtual)),
    );
  }
}

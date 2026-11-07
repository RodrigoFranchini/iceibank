// Classe criada pela IA para consultar periodicamente o lider atual eleito pelo Bully e avisar o painel da tela inicial.
import 'dart:async';

import 'package:flutter/foundation.dart';

import '../config.dart';

/// Ordem de tentativa de uma rodada: primeiro a ultima agencia que respondeu, depois as outras.
List<int> ordemDeTentativa(int primeira, [int total = totalAgencias]) =>
    [primeira, for (var agencia = 0; agencia < total; agencia++) if (agencia != primeira) agencia];

class MonitorLideranca extends ChangeNotifier {
  MonitorLideranca(this._consultarLider, {this.intervalo = const Duration(seconds: 3)});

  final Future<int?> Function(int agencia) _consultarLider;

  // 3 s e o mesmo periodo do heartbeat do backend: o painel acompanha a troca de
  // lider no ritmo em que as proprias agencias a detectam. GET /bully/lider e
  // publico e barato (so le uma variavel), entao o polling nao pesa nas agencias.
  final Duration intervalo;

  Timer? _timer;
  bool _consultando = false;
  bool _descartado = false;
  int _ultimaQueRespondeu = 0;

  /// False ate terminar a primeira rodada.
  bool verificou = false;

  /// Null com [agenciaQueRespondeu] preenchida significa eleicao em andamento.
  int? lider;

  /// Null quando nenhuma agencia respondeu na ultima rodada.
  int? agenciaQueRespondeu;

  DateTime? verificadoEm;

  void iniciar() {
    parar();
    verificar();
    _timer = Timer.periodic(intervalo, (_) => verificar());
  }

  void parar() {
    _timer?.cancel();
    _timer = null;
  }

  /// Uma rodada: tenta as agencias em ordem ate uma responder.
  Future<void> verificar() async {
    // Uma rodada com timeouts pode passar de 3 s; nao sobrepoe rodadas.
    if (_consultando) return;
    _consultando = true;
    try {
      for (final agencia in ordemDeTentativa(_ultimaQueRespondeu)) {
        try {
          final liderAtual = await _consultarLider(agencia);
          _ultimaQueRespondeu = agencia;
          _registrar(liderAtual, agencia);
          return;
        } on Exception {
          continue;
        }
      }
      _registrar(null, null);
    } finally {
      _consultando = false;
    }
  }

  void _registrar(int? liderAtual, int? agencia) {
    if (_descartado) return;
    verificou = true;
    lider = liderAtual;
    agenciaQueRespondeu = agencia;
    verificadoEm = DateTime.now();
    notifyListeners();
  }

  @override
  void dispose() {
    parar();
    _descartado = true;
    super.dispose();
  }
}

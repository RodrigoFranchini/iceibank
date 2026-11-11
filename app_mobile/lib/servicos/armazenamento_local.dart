// Classe criada pela IA para guardar no Hive o cache das contas e a fila de operacoes pendentes, como Maps simples.
import 'package:hive_flutter/hive_flutter.dart';

import '../modelos/conta_em_cache.dart';
import '../modelos/operacao_pendente.dart';

class ArmazenamentoLocal {
  ArmazenamentoLocal(this._contas, this._fila);

  /// Chave: id da conta.
  final Box<Map> _contas;

  /// Chave: idLocal da operacao.
  final Box<Map> _fila;

  static Future<ArmazenamentoLocal> abrir() async {
    await Hive.initFlutter();
    return ArmazenamentoLocal(await Hive.openBox<Map>('contas'), await Hive.openBox<Map>('fila'));
  }

  ContaEmCache? conta(int id) {
    final mapa = _contas.get(id);
    return mapa == null ? null : ContaEmCache.deMapa(mapa);
  }

  Future<void> salvarConta(ContaEmCache conta) => _contas.put(conta.conta.id, conta.paraMapa());

  /// Fila em ordem de criacao (FIFO).
  List<OperacaoPendente> fila() => _fila.values.map(OperacaoPendente.deMapa).toList()
    ..sort((a, b) => a.criadoEm.compareTo(b.criadoEm));

  Future<void> salvarOperacao(OperacaoPendente op) => _fila.put(op.idLocal, op.paraMapa());

  Future<void> removerOperacao(String idLocal) => _fila.delete(idLocal);
}

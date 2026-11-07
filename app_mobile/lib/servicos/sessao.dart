// Classe criada pela IA para guardar o token JWT e o host das agencias entre execucoes do app.
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config.dart';

class Sessao extends ChangeNotifier {
  Sessao(this._preferencias);

  static const _chaveToken = 'iceibank_token';
  static const _chaveHost = 'iceibank_host';

  final SharedPreferences _preferencias;

  /// Texto mostrado na tela de login (ex.: sessao expirada).
  String? aviso;

  String? get token => _preferencias.getString(_chaveToken);
  String get host => _preferencias.getString(_chaveHost) ?? hostPadrao();
  bool get autenticada => token != null;

  Future<void> salvarHost(String host) => _preferencias.setString(_chaveHost, host);

  Future<void> entrar(String token) async {
    await _preferencias.setString(_chaveToken, token);
    aviso = null;
    notifyListeners();
  }

  Future<void> sair({String? aviso}) async {
    await _preferencias.remove(_chaveToken);
    this.aviso = aviso;
    notifyListeners();
  }

  /// Chamado pelo ApiCliente quando a agencia responde 401.
  void expirar(String mensagemApi) =>
      sair(aviso: 'Sessão expirada, faça login novamente. ($mensagemApi)');
}

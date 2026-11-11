// Classe criada pela IA para iniciar o app ICEIBank: carrega a sessao salva, abre o Hive e liga o cliente da API a sessao.
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'servicos/api_cliente.dart';
import 'servicos/armazenamento_local.dart';
import 'servicos/sessao.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final sessao = Sessao(await SharedPreferences.getInstance());
  final api = ApiCliente(
    host: () => sessao.host,
    token: () => sessao.token,
    aoExpirarSessao: sessao.expirar,
  );
  final armazenamento = await ArmazenamentoLocal.abrir();
  runApp(IceibankApp(sessao: sessao, api: api, armazenamento: armazenamento, conectividade: Connectivity()));
}

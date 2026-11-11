// Classe criada pela IA para montar o MaterialApp e alternar entre login e tela inicial conforme a sessao.
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:material_ui/material_ui.dart';

import 'servicos/api_cliente.dart';
import 'servicos/armazenamento_local.dart';
import 'servicos/sessao.dart';
import 'telas/home_tela.dart';
import 'telas/login_tela.dart';

class IceibankApp extends StatelessWidget {
  const IceibankApp({
    super.key,
    required this.sessao,
    required this.api,
    required this.armazenamento,
    required this.conectividade,
  });

  final Sessao sessao;
  final ApiCliente api;
  final ArmazenamentoLocal armazenamento;
  final Connectivity conectividade;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ICEIBank',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo)),
      home: ListenableBuilder(
        listenable: sessao,
        builder: (context, _) => sessao.autenticada
            ? HomeTela(sessao: sessao, api: api, armazenamento: armazenamento, conectividade: conectividade)
            : LoginTela(sessao: sessao, api: api),
      ),
    );
  }
}

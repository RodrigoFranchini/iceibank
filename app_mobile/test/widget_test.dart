// Classe criada pela IA para testar que o app abre no login sem token salvo e na tela inicial com token salvo.
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:iceibank_mobile/app.dart';
import 'package:iceibank_mobile/servicos/api_cliente.dart';
import 'package:iceibank_mobile/servicos/armazenamento_local.dart';
import 'package:iceibank_mobile/servicos/sessao.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'apoio_hive.dart';

class ConectividadeFalsa implements Connectivity {
  @override
  Future<List<ConnectivityResult>> checkConnectivity() async => [ConnectivityResult.wifi];

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged => const Stream.empty();
}

void main() {
  late ArmazenamentoLocal armazenamento;

  // Fora do testWidgets: o Hive faz IO real, que nao avanca dentro do relogio falso.
  setUpAll(() async => armazenamento = await abrirArmazenamentoTemporario());

  Future<IceibankApp> montar(Map<String, Object> salvos) async {
    SharedPreferences.setMockInitialValues(salvos);
    final sessao = Sessao(await SharedPreferences.getInstance());
    final api = ApiCliente(
      host: () => sessao.host,
      token: () => sessao.token,
      cliente: MockClient((_) async => http.Response('{"idAgencia":0,"liderAtual":2}', 200)),
    );
    return IceibankApp(sessao: sessao, api: api, armazenamento: armazenamento, conectividade: ConectividadeFalsa());
  }

  testWidgets('sem token mostra o login', (tester) async {
    await tester.pumpWidget(await montar({}));

    expect(find.text('Entrar'), findsOneWidget);
    expect(find.text('Host das agências'), findsOneWidget);
  });

  testWidgets('com token salvo pula o login e mostra o lider', (tester) async {
    await tester.pumpWidget(await montar({'iceibank_token': 't'}));
    await tester.pump();

    expect(find.text('Líder atual: Agência 2'), findsOneWidget);
    expect(find.text('Online'), findsOneWidget);
    // Desmonta a tela para o dispose parar os timers.
    await tester.pumpWidget(const SizedBox());
  });
}

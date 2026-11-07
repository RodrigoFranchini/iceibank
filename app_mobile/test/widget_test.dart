// Classe criada pela IA para testar que o app abre no login sem token salvo e na tela inicial com token salvo.
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:iceibank_mobile/app.dart';
import 'package:iceibank_mobile/servicos/api_cliente.dart';
import 'package:iceibank_mobile/servicos/sessao.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<IceibankApp> montar(Map<String, Object> salvos) async {
  SharedPreferences.setMockInitialValues(salvos);
  final sessao = Sessao(await SharedPreferences.getInstance());
  final api = ApiCliente(
    host: () => sessao.host,
    token: () => sessao.token,
    cliente: MockClient((_) async => http.Response('{"idAgencia":0,"liderAtual":2}', 200)),
  );
  return IceibankApp(sessao: sessao, api: api);
}

void main() {
  testWidgets('sem token mostra o login', (tester) async {
    await tester.pumpWidget(await montar({}));

    expect(find.text('Entrar'), findsOneWidget);
    expect(find.text('Host das agências'), findsOneWidget);
  });

  testWidgets('com token salvo pula o login e mostra o lider', (tester) async {
    await tester.pumpWidget(await montar({'iceibank_token': 't'}));
    await tester.pump();

    expect(find.text('Líder atual: Agência 2'), findsOneWidget);
    // Desmonta a tela para o dispose parar o timer do monitor.
    await tester.pumpWidget(const SizedBox());
  });
}

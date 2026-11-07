// Classe criada pela IA para testar a regra de particionamento das contas entre as agencias.
import 'package:flutter_test/flutter_test.dart';
import 'package:iceibank_mobile/config.dart';

void main() {
  test('conta pertence a agencia id % 3', () {
    expect(agenciaDaConta(0), 0);
    expect(agenciaDaConta(4), 1);
    expect(agenciaDaConta(8), 2);
    expect(agenciaDaConta(9), 0);
  });

  test('porta da agencia e 4000 + id', () {
    expect(portaDaAgencia(0), 4000);
    expect(portaDaAgencia(2), 4002);
  });
}

// Classe criada pela IA para centralizar as constantes de rede e a regra de particionamento das contas entre as agencias.
import 'dart:io' show Platform;

const int portaBase = 4000;
const int totalAgencias = 3;
const Duration tempoLimiteRequisicao = Duration(seconds: 3);

/// Mesma regra do backend: a conta pertence a agencia id % 3.
int agenciaDaConta(int idConta) => idConta % totalAgencias;

int portaDaAgencia(int agencia) => portaBase + agencia;

/// O emulador Android enxerga o host em 10.0.2.2; o simulador iOS usa localhost.
String hostPadrao() => Platform.isAndroid ? '10.0.2.2' : 'localhost';

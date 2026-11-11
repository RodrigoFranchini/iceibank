// Classe criada pela IA para a tela inicial com o painel de lideranca, as operacoes bancarias e a fila offline.
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:material_ui/material_ui.dart';

import '../servicos/api_cliente.dart';
import '../servicos/armazenamento_local.dart';
import '../servicos/contas_offline.dart';
import '../servicos/monitor_lideranca.dart';
import '../servicos/sessao.dart';
import 'widgets/cartao_operacao.dart';
import 'widgets/cartao_pendentes.dart';
import 'widgets/cartao_saldo.dart';
import 'widgets/cartao_transferencia.dart';
import 'widgets/indicador_conexao.dart';
import 'widgets/painel_lideranca.dart';

class HomeTela extends StatefulWidget {
  const HomeTela({
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
  State<HomeTela> createState() => _HomeTelaState();
}

class _HomeTelaState extends State<HomeTela> {
  // Monitor e sincronizacao vivem enquanto a tela existe: no logout (ou 401) a tela
  // sai e os timers param no dispose; a fila fica no Hive e volta a ser enviada apos o login.
  late final _monitor = MonitorLideranca(widget.api.consultarLider)..iniciar();
  late final _contas = ContasOffline(api: widget.api, armazenamento: widget.armazenamento)
    ..iniciar(widget.conectividade);

  @override
  void dispose() {
    _monitor.dispose();
    _contas.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ICEIBank'),
        actions: [
          IndicadorConexao(contas: _contas),
          IconButton(
            tooltip: 'Sair',
            icon: const Icon(Icons.logout),
            onPressed: () => widget.sessao.sair(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          PainelLideranca(monitor: _monitor),
          CartaoPendentes(contas: _contas),
          CartaoSaldo(contas: _contas),
          CartaoOperacao(contas: _contas),
          CartaoTransferencia(api: widget.api),
        ],
      ),
    );
  }
}

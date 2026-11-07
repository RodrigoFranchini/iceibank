// Classe criada pela IA para a tela inicial com o painel de lideranca e as operacoes bancarias.
import 'package:material_ui/material_ui.dart';

import '../servicos/api_cliente.dart';
import '../servicos/monitor_lideranca.dart';
import '../servicos/sessao.dart';
import 'widgets/cartao_operacao.dart';
import 'widgets/cartao_saldo.dart';
import 'widgets/cartao_transferencia.dart';
import 'widgets/painel_lideranca.dart';

class HomeTela extends StatefulWidget {
  const HomeTela({super.key, required this.sessao, required this.api});

  final Sessao sessao;
  final ApiCliente api;

  @override
  State<HomeTela> createState() => _HomeTelaState();
}

class _HomeTelaState extends State<HomeTela> {
  // O monitor vive enquanto a tela existe; no logout a tela sai e o timer para no dispose.
  late final _monitor = MonitorLideranca(widget.api.consultarLider)..iniciar();

  @override
  void dispose() {
    _monitor.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ICEIBank'),
        actions: [
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
          CartaoSaldo(api: widget.api),
          CartaoOperacao(api: widget.api),
          CartaoTransferencia(api: widget.api),
        ],
      ),
    );
  }
}

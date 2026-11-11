// Classe criada pela IA para listar as operacoes offline pendentes e resolver conflitos e falhas de sincronizacao.
import 'package:material_ui/material_ui.dart';

import '../../modelos/operacao_pendente.dart';
import '../../servicos/contas_offline.dart';
import '../../util/formato.dart';

class CartaoPendentes extends StatelessWidget {
  const CartaoPendentes({super.key, required this.contas});

  final ContasOffline contas;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: contas,
      builder: (context, _) {
        final fila = contas.fila;
        if (fila.isEmpty) return const SizedBox.shrink();
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Operações pendentes (${fila.length})', style: Theme.of(context).textTheme.titleMedium),
                for (final op in fila) _ItemPendente(op: op, contas: contas),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ItemPendente extends StatelessWidget {
  const _ItemPendente({required this.op, required this.contas});

  final OperacaoPendente op;
  final ContasOffline contas;

  @override
  Widget build(BuildContext context) {
    final cor = op.status == StatusOperacao.pendente ? Colors.orange.shade800 : Colors.red.shade700;
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(border: Border.all(color: cor), borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('Conta ${op.idConta}: ${op.descricao}')),
              Text(op.status.rotulo, style: TextStyle(color: cor, fontWeight: FontWeight.bold)),
            ],
          ),
          Text('Criada às ${formatarDataHora(op.criadoEm)}', style: Theme.of(context).textTheme.bodySmall),
          if (op.status == StatusOperacao.conflito)
            Text(
              'A operação pendente (${op.descricao}) não pôde ser aplicada automaticamente: a conta mudou na '
              'agência enquanto o app estava offline. Saldo real: ${formatarMoeda(op.contaAtual?.saldo ?? 0)}.',
              style: TextStyle(color: cor),
            ),
          if (op.status == StatusOperacao.falhou) Text('Falhou: ${op.erro}', style: TextStyle(color: cor)),
          if (op.status != StatusOperacao.pendente)
            OverflowBar(
              alignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: () => contas.descartar(op), child: const Text('Descartar')),
                if (op.status == StatusOperacao.conflito)
                  FilledButton(onPressed: () => contas.reenviar(op), child: const Text('Reenviar')),
              ],
            ),
        ],
      ),
    );
  }
}

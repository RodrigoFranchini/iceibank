// Classe criada pela IA para o formulario de deposito e saque.
import 'package:material_ui/material_ui.dart';

import '../../servicos/api_cliente.dart';
import '../../util/formato.dart';
import 'acao_com_retorno.dart';

class CartaoOperacao extends StatefulWidget {
  const CartaoOperacao({super.key, required this.api});

  final ApiCliente api;

  @override
  State<CartaoOperacao> createState() => _CartaoOperacaoState();
}

class _CartaoOperacaoState extends State<CartaoOperacao> with AcaoComRetorno {
  final _id = TextEditingController();
  final _valor = TextEditingController();

  Future<void> _depositar() => executar(() async {
        final conta = await widget.api.depositar(lerId(_id.text, 'id de conta'), lerValor(_valor.text));
        return 'Depósito realizado. Novo saldo: ${formatarMoeda(conta.saldo)}.';
      });

  Future<void> _sacar() => executar(() async {
        final conta = await widget.api.sacar(lerId(_id.text, 'id de conta'), lerValor(_valor.text));
        return 'Saque realizado. Novo saldo: ${formatarMoeda(conta.saldo)}.';
      });

  @override
  void dispose() {
    _id.dispose();
    _valor.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Depósito e saque', style: Theme.of(context).textTheme.titleMedium),
            TextField(
              controller: _id,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Id da conta'),
            ),
            TextField(
              controller: _valor,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Valor'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton(onPressed: carregando ? null : _depositar, child: const Text('Depositar')),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(onPressed: carregando ? null : _sacar, child: const Text('Sacar')),
                ),
              ],
            ),
            retorno(),
          ],
        ),
      ),
    );
  }
}

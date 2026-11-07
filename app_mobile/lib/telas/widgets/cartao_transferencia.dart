// Classe criada pela IA para o formulario de transferencia entre contas.
import 'package:material_ui/material_ui.dart';

import '../../servicos/api_cliente.dart';
import '../../util/formato.dart';
import 'acao_com_retorno.dart';

class CartaoTransferencia extends StatefulWidget {
  const CartaoTransferencia({super.key, required this.api});

  final ApiCliente api;

  @override
  State<CartaoTransferencia> createState() => _CartaoTransferenciaState();
}

class _CartaoTransferenciaState extends State<CartaoTransferencia> with AcaoComRetorno {
  final _origem = TextEditingController();
  final _destino = TextEditingController();
  final _valor = TextEditingController();

  // A mensagem da API ja diz se foi na mesma agencia ou entre agencias.
  Future<void> _transferir() => executar(() => widget.api.transferir(
        lerId(_origem.text, 'id de origem'),
        lerId(_destino.text, 'id de destino'),
        lerValor(_valor.text),
      ));

  @override
  void dispose() {
    _origem.dispose();
    _destino.dispose();
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
            Text('Transferência', style: Theme.of(context).textTheme.titleMedium),
            TextField(
              controller: _origem,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Conta de origem'),
            ),
            TextField(
              controller: _destino,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Conta de destino'),
            ),
            TextField(
              controller: _valor,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Valor'),
            ),
            const SizedBox(height: 12),
            FilledButton(onPressed: carregando ? null : _transferir, child: const Text('Transferir')),
            retorno(),
          ],
        ),
      ),
    );
  }
}

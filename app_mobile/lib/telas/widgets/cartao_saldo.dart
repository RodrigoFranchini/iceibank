// Classe criada pela IA para o formulario de consulta de saldo.
import 'package:material_ui/material_ui.dart';

import '../../modelos/conta.dart';
import '../../servicos/api_cliente.dart';
import '../../util/formato.dart';
import 'acao_com_retorno.dart';

class CartaoSaldo extends StatefulWidget {
  const CartaoSaldo({super.key, required this.api});

  final ApiCliente api;

  @override
  State<CartaoSaldo> createState() => _CartaoSaldoState();
}

class _CartaoSaldoState extends State<CartaoSaldo> with AcaoComRetorno {
  final _id = TextEditingController();
  Conta? _conta;

  Future<void> _consultar() => executar(() async {
        setState(() => _conta = null);
        final conta = await widget.api.consultarConta(lerId(_id.text, 'id de conta'));
        setState(() => _conta = conta);
        return '';
      });

  @override
  void dispose() {
    _id.dispose();
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
            Text('Consultar saldo', style: Theme.of(context).textTheme.titleMedium),
            TextField(
              controller: _id,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Id da conta'),
            ),
            const SizedBox(height: 12),
            FilledButton(onPressed: carregando ? null : _consultar, child: const Text('Consultar')),
            if (_conta != null) ...[
              const SizedBox(height: 12),
              Text('Id: ${_conta!.id}'),
              Text('Nome: ${_conta!.nomeAluno}'),
              Text('Saldo: ${formatarMoeda(_conta!.saldo)}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
            retorno(),
          ],
        ),
      ),
    );
  }
}

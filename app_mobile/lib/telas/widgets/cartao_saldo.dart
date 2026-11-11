// Classe criada pela IA para o formulario de consulta de saldo, com o cache offline e o saldo provisorio.
import 'package:material_ui/material_ui.dart';

import '../../servicos/contas_offline.dart';
import '../../servicos/regras_offline.dart';
import '../../util/formato.dart';
import 'acao_com_retorno.dart';

class CartaoSaldo extends StatefulWidget {
  const CartaoSaldo({super.key, required this.contas});

  final ContasOffline contas;

  @override
  State<CartaoSaldo> createState() => _CartaoSaldoState();
}

class _CartaoSaldoState extends State<CartaoSaldo> with AcaoComRetorno {
  final _id = TextEditingController();
  int? _idConsultado;
  bool _emCache = false;

  Future<void> _consultar() => executar(() async {
        setState(() => _idConsultado = null);
        final resultado = await widget.contas.consultar(lerId(_id.text, 'id de conta'));
        setState(() {
          _idConsultado = resultado.conta.conta.id;
          _emCache = resultado.emCache;
        });
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
            // Reconstroi quando a sincronizacao atualiza o cache ou a fila.
            if (_idConsultado != null) ListenableBuilder(listenable: widget.contas, builder: (context, _) => _dados()),
            retorno(),
          ],
        ),
      ),
    );
  }

  Widget _dados() {
    final cache = widget.contas.contaEmCache(_idConsultado!);
    if (cache == null) return const SizedBox.shrink();
    final conta = cache.conta;
    final pendentes = widget.contas.operacoesDaConta(conta.id);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        if (_emCache)
          Text('Dados em cache de ${formatarDataHora(cache.atualizadoEm)}',
              style: TextStyle(color: Colors.orange.shade900, fontStyle: FontStyle.italic)),
        Text('Id: ${conta.id}'),
        Text('Nome: ${conta.nomeAluno}'),
        Text('Saldo: ${formatarMoeda(conta.saldo)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        if (pendentes.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('Saldo provisório: ${formatarMoeda(saldoProvisorio(conta.saldo, pendentes))}',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange.shade900)),
              Chip(
                label: const Text('pendente de sincronização'),
                backgroundColor: Colors.orange.shade100,
                side: BorderSide(color: Colors.orange.shade700),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

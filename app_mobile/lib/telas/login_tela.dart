// Classe criada pela IA para a tela de login com usuario, senha e host das agencias.
import 'package:material_ui/material_ui.dart';

import '../servicos/api_cliente.dart';
import '../servicos/sessao.dart';
import 'widgets/acao_com_retorno.dart';

class LoginTela extends StatefulWidget {
  const LoginTela({super.key, required this.sessao, required this.api});

  final Sessao sessao;
  final ApiCliente api;

  @override
  State<LoginTela> createState() => _LoginTelaState();
}

class _LoginTelaState extends State<LoginTela> with AcaoComRetorno {
  final _usuario = TextEditingController();
  final _senha = TextEditingController();
  late final _host = TextEditingController(text: widget.sessao.host);

  Future<void> _entrar() => executar(() async {
    final host = _host.text.trim();
    if (host.isEmpty) {
      throw const FormatException('Informe o host das agências.');
    }
    await widget.sessao.salvarHost(host);
    final token = await widget.api.login(_usuario.text.trim(), _senha.text);
    await widget.sessao.entrar(token);
    return '';
  });

  @override
  void dispose() {
    _usuario.dispose();
    _senha.dispose();
    _host.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final aviso = widget.sessao.aviso;
    return Scaffold(
      appBar: AppBar(title: const Text('ICEIBank - Login')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          if (aviso != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                aviso,
                style: TextStyle(color: Colors.orange.shade900, fontWeight: FontWeight.w500),
              ),
            ),
          TextField(
            controller: _usuario,
            autocorrect: false,
            enableSuggestions: false,
            decoration: const InputDecoration(labelText: 'Usuário'),
          ),
          TextField(
            controller: _senha,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Senha'),
            onSubmitted: (_) => _entrar(),
          ),
          TextField(
            controller: _host,
            autocorrect: false,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              labelText: 'Host das agências',
              helperText: 'Agência N responde na porta 4000 + N',
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(onPressed: carregando ? null : _entrar, child: const Text('Entrar')),
          retorno(),
        ],
      ),
    );
  }
}

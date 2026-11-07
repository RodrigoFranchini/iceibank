// Classe criada pela IA para padronizar o carregamento e as mensagens de sucesso e erro dos formularios.
import 'package:material_ui/material_ui.dart';

import '../../servicos/api_excecao.dart';

mixin AcaoComRetorno<T extends StatefulWidget> on State<T> {
  bool carregando = false;
  String? erro;
  String? sucesso;

  /// Executa [acao]; o texto devolvido vira a mensagem de sucesso.
  Future<void> executar(Future<String> Function() acao) async {
    setState(() {
      carregando = true;
      erro = null;
      sucesso = null;
    });
    try {
      final mensagem = await acao();
      if (mounted) setState(() => sucesso = mensagem);
    } catch (e) {
      // 401: a sessao ja foi encerrada e a tela de login mostra o aviso.
      if (!mounted || e is SessaoExpiradaExcecao) return;
      final mensagem = mensagemDeErro(e);
      setState(() => erro = mensagem);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(mensagem), backgroundColor: Colors.red.shade700));
    } finally {
      if (mounted) setState(() => carregando = false);
    }
  }

  /// Texto inline: vermelho para erro, verde para sucesso.
  Widget retorno() {
    if (erro != null) return _texto(erro!, Colors.red.shade700);
    if (sucesso != null && sucesso!.isNotEmpty) return _texto(sucesso!, Colors.green.shade700);
    return const SizedBox.shrink();
  }

  Widget _texto(String texto, Color cor) => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(texto, style: TextStyle(color: cor, fontWeight: FontWeight.w500)),
      );
}

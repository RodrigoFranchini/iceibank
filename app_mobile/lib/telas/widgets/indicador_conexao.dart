// Classe criada pela IA para mostrar na AppBar se o app esta online e quantas operacoes esperam sincronizacao.
import 'package:material_ui/material_ui.dart';

import '../../servicos/contas_offline.dart';

class IndicadorConexao extends StatelessWidget {
  const IndicadorConexao({super.key, required this.contas});

  final ContasOffline contas;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: contas,
      builder: (context, _) {
        final pendentes = contas.fila.length;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Chip(
              avatar: Icon(contas.online ? Icons.wifi : Icons.wifi_off, size: 16, color: Colors.white),
              label: Text(contas.online ? 'Online' : 'Offline', style: const TextStyle(color: Colors.white)),
              backgroundColor: contas.online ? Colors.green.shade700 : Colors.red.shade700,
              side: BorderSide.none,
            ),
            if (pendentes > 0)
              Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Badge(
                  label: Text('$pendentes'),
                  backgroundColor: Colors.orange.shade800,
                  child: Icon(contas.sincronizando ? Icons.sync : Icons.schedule),
                ),
              ),
          ],
        );
      },
    );
  }
}

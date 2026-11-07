// Classe criada pela IA para mostrar o lider atual do Bully, atualizado sozinho pelo MonitorLideranca.
import 'package:material_ui/material_ui.dart';

import '../../servicos/monitor_lideranca.dart';
import '../../util/formato.dart';

class PainelLideranca extends StatelessWidget {
  const PainelLideranca({super.key, required this.monitor});

  final MonitorLideranca monitor;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: monitor,
      builder: (context, _) {
        final (icone, cor, titulo) = _estado();
        final hora = monitor.verificadoEm == null ? null : formatarHora(monitor.verificadoEm!);
        final detalhe = !monitor.verificou
            ? 'Consultando as agências...'
            : monitor.agenciaQueRespondeu == null
                ? 'Nenhuma agência respondeu (verificado às $hora).'
                : 'Respondido pela Agência ${monitor.agenciaQueRespondeu} às $hora.';
        return Card(
          color: cor.withValues(alpha: 0.08),
          child: ListTile(
            leading: Icon(icone, color: cor, size: 32),
            title: Text(titulo, style: TextStyle(fontWeight: FontWeight.bold, color: cor)),
            subtitle: Text(detalhe),
          ),
        );
      },
    );
  }

  (IconData, Color, String) _estado() {
    if (!monitor.verificou) return (Icons.hourglass_empty, Colors.grey.shade700, 'Líder atual: ...');
    if (monitor.agenciaQueRespondeu == null) {
      return (Icons.cloud_off, Colors.red.shade700, 'Líder atual: desconhecido');
    }
    if (monitor.lider == null) {
      return (Icons.how_to_vote, Colors.orange.shade800, 'Líder atual: eleição em andamento');
    }
    return (Icons.star, Colors.indigo, 'Líder atual: Agência ${monitor.lider}');
  }
}

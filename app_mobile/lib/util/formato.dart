// Classe criada pela IA para formatar valores e horarios e ler os campos numericos dos formularios.

String formatarMoeda(double valor) => 'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';

String formatarHora(DateTime momento) {
  String doisDigitos(int n) => n.toString().padLeft(2, '0');
  return '${doisDigitos(momento.hour)}:${doisDigitos(momento.minute)}:${doisDigitos(momento.second)}';
}

/// Lança FormatException com a mensagem que vai para a tela.
int lerId(String texto, String campo) {
  final id = int.tryParse(texto.trim());
  if (id == null || id < 0) throw FormatException('Informe um $campo válido.');
  return id;
}

double lerValor(String texto) {
  final valor = double.tryParse(texto.trim().replaceAll(',', '.'));
  if (valor == null || valor <= 0) throw const FormatException('Informe um valor maior que zero.');
  return valor;
}

// Classe criada pela IA para abrir caixas do Hive numa pasta temporaria durante os testes.
import 'dart:io';

import 'package:hive/hive.dart';
import 'package:iceibank_mobile/servicos/armazenamento_local.dart';

Future<ArmazenamentoLocal> abrirArmazenamentoTemporario() async {
  Hive.init(Directory.systemTemp.createTempSync('iceibank_teste').path);
  final sufixo = DateTime.now().microsecondsSinceEpoch;
  return ArmazenamentoLocal(await Hive.openBox<Map>('contas$sufixo'), await Hive.openBox<Map>('fila$sufixo'));
}

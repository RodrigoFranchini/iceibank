package br.pucminas.iceibank.agencia.service;

import java.util.Map;
import java.io.IOException;

public interface EventLogService {

    Map<String, Object> registrar(String tipo, int timestampLamport, Map<String, Object> detalhes) throws IOException;
}

package br.pucminas.iceibank.agencia;

import java.nio.file.DirectoryStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Map;

import com.fasterxml.jackson.databind.ObjectMapper;

/**
 * Equivalente ao mesclar-logs.js do roteiro: le os .jsonl de todas as
 * agencias em data/ e monta uma unica linha do tempo, ordenada por relogio
 * de Lamport.
 *
 * Executar (a partir da pasta agencia/, depois de gerar eventos com as
 * agencias rodando):
 *   mvn spring-boot:run -Dspring-boot.run.mainClass=br.pucminas.iceibank.agencia.MesclarLogs
 */
public class MesclarLogs {

    public static void main(String[] args) throws Exception {
        Path pastaDados = Paths.get("data");
        ObjectMapper mapper = new ObjectMapper();

        List<Map<String, Object>> todosEventos = new ArrayList<>();

        try (DirectoryStream<Path> arquivos = Files.newDirectoryStream(pastaDados, "*.jsonl")) {
            for (Path arquivo : arquivos) {
                for (String linha : Files.readAllLines(arquivo)) {
                    if (!linha.isBlank()) {
                        todosEventos.add(mapper.readValue(linha, Map.class));
                    }
                }
            }
        }

        todosEventos.sort(Comparator.comparingInt(e -> ((Number) e.get("timestampLamport")).intValue()));

        System.out.println("=== Linha do tempo unificada (ordenada por relogio de Lamport) ===");
        for (Map<String, Object> evento : todosEventos) {
            System.out.println(String.format(
                    "[Lamport %s] (%s) %s - %s %s",
                    evento.get("timestampLamport"),
                    evento.get("horaParede"),
                    evento.get("agencia"),
                    evento.get("tipo"),
                    mapper.writeValueAsString(evento.get("detalhes"))));
        }
    }
}

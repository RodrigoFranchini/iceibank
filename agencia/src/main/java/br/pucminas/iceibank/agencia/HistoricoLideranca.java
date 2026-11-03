package br.pucminas.iceibank.agencia;

import java.nio.file.DirectoryStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.time.Instant;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.Set;

import com.fasterxml.jackson.databind.ObjectMapper;

/**
 * Equivalente ao historico-lideranca.js do roteiro: le os .jsonl de todas as
 * agencias em data/, filtra os eventos do algoritmo Bully, ordena pela hora de
 * parede e imprime o historico de eleicoes e a linha do tempo de lideres.
 *
 * Executar (a partir da pasta agencia/, depois de gerar eventos com as
 * agencias rodando):
 *   mvn spring-boot:run -Dspring-boot.run.main-class=br.pucminas.iceibank.agencia.HistoricoLideranca
 */
public class HistoricoLideranca {

    private static final Set<String> TIPOS_BULLY = Set.of(
            "ELEICAO_INICIADA",
            "ELEICAO_RECEBIDA",
            "TORNOU_LIDER",
            "LIDER_ANUNCIADO",
            "LIDER_NAO_RESPONDEU");

    @SuppressWarnings("unchecked")
    public static void main(String[] args) throws Exception {
        Path pastaDados = Paths.get("data");
        ObjectMapper mapper = new ObjectMapper();

        List<Map<String, Object>> eventosBully = new ArrayList<>();

        try (DirectoryStream<Path> arquivos = Files.newDirectoryStream(pastaDados, "eventos-agencia-*.jsonl")) {
            for (Path arquivo : arquivos) {
                for (String linha : Files.readAllLines(arquivo)) {
                    if (linha.isBlank()) continue;
                    Map<String, Object> evento = mapper.readValue(linha, Map.class);
                    if (TIPOS_BULLY.contains((String) evento.get("tipo"))) {
                        eventosBully.add(evento);
                    }
                }
            }
        }

        eventosBully.sort(Comparator.comparing(e -> Instant.parse((String) e.get("horaParede"))));

        System.out.println("=== Histórico de eventos de eleição ===");
        for (Map<String, Object> evento : eventosBully) {
            System.out.println(String.format(
                    "(%s) [%s] %s %s",
                    evento.get("horaParede"),
                    evento.get("agencia"),
                    evento.get("tipo"),
                    mapper.writeValueAsString(evento.get("detalhes"))));
        }

        System.out.println();
        System.out.println("=== Linha do tempo de líderes ===");
        for (Map<String, Object> evento : eventosBully) {
            if (!"TORNOU_LIDER".equals(evento.get("tipo"))) continue;
            Map<String, Object> detalhes = (Map<String, Object>) evento.get("detalhes");
            System.out.println(String.format(
                    "A partir de %s: Agência %s é a líder",
                    evento.get("horaParede"),
                    detalhes.get("idAgencia")));
        }
    }
}

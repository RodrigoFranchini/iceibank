package br.pucminas.iceibank.agencia;

import java.nio.file.DirectoryStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.time.Instant;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Comparator;
import java.util.List;
import java.util.Map;

import com.fasterxml.jackson.databind.ObjectMapper;

/**
 * Equivalente ao mesclar-logs.js do roteiro: le os .jsonl de todas as
 * agencias em data/ e monta uma unica linha do tempo, ordenada pela hora de
 * parede e exibindo o relogio vetorial de cada evento.
 *
 * Relogio vetorial nao define ordem total (eventos concorrentes nao tem
 * "antes" nem "depois"), por isso a ordenacao para exibicao usa horaParede.
 * A relacao causal de verdade vem da comparacao dos vetores, listada no fim.
 *
 * Executar (a partir da pasta agencia/, depois de gerar eventos com as
 * agencias rodando):
 *   mvn spring-boot:run -Dspring-boot.run.main-class=br.pucminas.iceibank.agencia.MesclarLogs
 */
public class MesclarLogs {

    public enum Relacao { ANTES, DEPOIS, IGUAIS, CONCORRENTES }

    /**
     * Compara dois vetores posicao a posicao:
     * - v1 <= v2 em todas as posicoes (e diferentes): v1 aconteceu ANTES de v2;
     * - v1 >= v2 em todas as posicoes (e diferentes): v1 aconteceu DEPOIS de v2;
     * - cada um e maior em pelo menos uma posicao: CONCORRENTES (nenhum
     *   dos dois poderia saber do outro).
     */
    public static Relacao compararVetores(int[] v1, int[] v2) {
        boolean algumMenor = false;
        boolean algumMaior = false;
        for (int i = 0; i < v1.length; i++) {
            if (v1[i] < v2[i]) algumMenor = true;
            if (v1[i] > v2[i]) algumMaior = true;
        }
        if (algumMenor && algumMaior) return Relacao.CONCORRENTES;
        if (algumMenor) return Relacao.ANTES;
        if (algumMaior) return Relacao.DEPOIS;
        return Relacao.IGUAIS;
    }

    @SuppressWarnings("unchecked")
    public static void main(String[] args) throws Exception {
        Path pastaDados = Paths.get("data");
        ObjectMapper mapper = new ObjectMapper();

        List<Map<String, Object>> todosEventos = new ArrayList<>();

        try (DirectoryStream<Path> arquivos = Files.newDirectoryStream(pastaDados, "eventos-agencia-*.jsonl")) {
            for (Path arquivo : arquivos) {
                for (String linha : Files.readAllLines(arquivo)) {
                    if (linha.isBlank()) continue;
                    Map<String, Object> evento = mapper.readValue(linha, Map.class);
                    // Linhas do Sprint 1 (so timestampLamport) nao tem vetor para comparar.
                    if (evento.get("timestampVetorial") != null) {
                        todosEventos.add(evento);
                    }
                }
            }
        }

        todosEventos.sort(Comparator.comparing(e -> Instant.parse((String) e.get("horaParede"))));

        System.out.println("=== Linha do tempo unificada (ordenada por hora de parede) ===");
        for (Map<String, Object> evento : todosEventos) {
            System.out.println(String.format(
                    "%s (%s) %s - %s %s",
                    Arrays.toString(vetor(evento)),
                    evento.get("horaParede"),
                    evento.get("agencia"),
                    evento.get("tipo"),
                    mapper.writeValueAsString(evento.get("detalhes"))));
        }

        // Compara cada par de eventos de agencias DIFERENTES (dentro da mesma
        // agencia os eventos sao sempre sequenciais, nunca concorrentes).
        List<String> causais = new ArrayList<>();
        List<String> concorrentes = new ArrayList<>();
        for (int i = 0; i < todosEventos.size(); i++) {
            for (int j = i + 1; j < todosEventos.size(); j++) {
                Map<String, Object> a = todosEventos.get(i);
                Map<String, Object> b = todosEventos.get(j);
                if (a.get("agencia").equals(b.get("agencia"))) continue;

                Relacao relacao = compararVetores(vetor(a), vetor(b));
                if (relacao == Relacao.CONCORRENTES) {
                    concorrentes.add(descrever(a) + "  ||  " + descrever(b));
                } else if (relacao == Relacao.ANTES) {
                    causais.add(descrever(a) + "  ->  " + descrever(b));
                } else if (relacao == Relacao.DEPOIS) {
                    causais.add(descrever(b) + "  ->  " + descrever(a));
                }
            }
        }

        System.out.println();
        System.out.println("=== Pares causais entre agencias (a -> b: a aconteceu antes de b) ===");
        causais.forEach(System.out::println);

        System.out.println();
        System.out.println("=== Pares CONCORRENTES entre agencias (a || b) ===");
        concorrentes.forEach(System.out::println);
    }

    @SuppressWarnings("unchecked")
    private static int[] vetor(Map<String, Object> evento) {
        List<Number> lista = (List<Number>) evento.get("timestampVetorial");
        return lista.stream().mapToInt(Number::intValue).toArray();
    }

    private static String descrever(Map<String, Object> evento) {
        return evento.get("agencia") + " " + evento.get("tipo") + " " + Arrays.toString(vetor(evento));
    }
}

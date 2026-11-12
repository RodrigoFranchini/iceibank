package br.pucminas.iceibank.agencia.service;

import java.io.IOException;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.concurrent.atomic.AtomicReference;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.event.EventListener;
import org.springframework.stereotype.Service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;

import br.pucminas.iceibank.agencia.config.AgenciaProperties;

// Classe criada pela IA para implementar o algoritmo de Bully (eleicao, coordenador e heartbeat) entre as agencias.

/**
 * Eleicao de lider pelo algoritmo de Bully: a agencia de maior id que estiver
 * no ar vence.
 *
 * Quem inicia a eleicao pergunta (POST /bully/eleicao) a todas as agencias de
 * id maior. Se alguma responder, ela assume a eleicao e a minha parte acaba;
 * se nenhuma responder, eu me torno o lider e aviso todas as outras
 * (POST /bully/coordenador). Toda chamada tem timeout (padrao 1s): quem nao
 * responde nesse prazo e considerado fora do ar.
 *
 * O heartbeat consulta o lider periodicamente (GET /bully/lider); se ele nao
 * responder, o lider e esquecido e uma nova eleicao e iniciada.
 *
 * Mesmo cuidado do RelogioVetorial: o estado e tocado por threads diferentes
 * (requisicoes HTTP do Spring e a thread da propria eleicao), entao o lider
 * fica num AtomicReference e a flag "eleicao em andamento" num AtomicBoolean
 * com compareAndSet, para duas eleicoes nunca rodarem ao mesmo tempo.
 */
@Service
public class BullyService {

    /**
     * Funcionalidade adicional (Sprint 3): prazo de resposta e intervalo do
     * heartbeat vem do application.properties, que le as variaveis de ambiente
     * BULLY_TIMEOUT_MS e BULLY_HEARTBEAT_MS (padrao 1000 e 3000, como no roteiro).
     */
    private final long timeoutMs;
    private final long intervaloHeartbeatMs;

    private final AgenciaProperties agenciaProperties;
    private final RelogioVetorial relogio;
    private final EventLogService eventLog;

    private final HttpClient clienteHttp;
    private final ObjectMapper mapeadorJson = new ObjectMapper();

    /** null = lider ainda desconhecido. */
    private final AtomicReference<Integer> liderAtual = new AtomicReference<>(null);
    private final AtomicBoolean eleicaoEmAndamento = new AtomicBoolean(false);

    /**
     * Thread unica para rodar eleicoes fora da thread HTTP: o "OK" do Bully e
     * o proprio 200 da rota, entao quem pergunta nao pode ficar bloqueado
     * esperando a eleicao desta agencia terminar.
     */
    private final ExecutorService executorEleicao = Executors.newSingleThreadExecutor(r -> {
        Thread thread = new Thread(r, "bully-eleicao");
        thread.setDaemon(true);
        return thread;
    });

    /** Thread unica (daemon) do heartbeat, separada da thread das eleicoes. */
    private final ScheduledExecutorService agendadorHeartbeat = Executors.newSingleThreadScheduledExecutor(r -> {
        Thread thread = new Thread(r, "bully-heartbeat");
        thread.setDaemon(true);
        return thread;
    });

    public BullyService(AgenciaProperties agenciaProperties, RelogioVetorial relogio, EventLogService eventLog,
                        @Value("${iceibank.bully.timeout-ms}") long timeoutMs,
                        @Value("${iceibank.bully.intervalo-heartbeat-ms}") long intervaloHeartbeatMs) {
        this.timeoutMs = timeoutMs;
        this.intervaloHeartbeatMs = intervaloHeartbeatMs;
        this.clienteHttp = HttpClient.newBuilder()
                .connectTimeout(Duration.ofMillis(timeoutMs))
                .build();
        this.agenciaProperties = agenciaProperties;
        this.relogio = relogio;
        this.eventLog = eventLog;
    }

    /** Equivalente ao callback do app.listen: ao subir, ja dispara uma eleicao e liga o heartbeat. */
    @EventListener(ApplicationReadyEvent.class)
    public void aoIniciarAplicacao() {
        executorEleicao.submit(this::iniciarEleicao);
        System.out.println("[Bully] timeout=" + timeoutMs + "ms, heartbeat=" + intervaloHeartbeatMs + "ms");
        iniciarHeartbeat(intervaloHeartbeatMs);
    }

    public void iniciarEleicao() {
        if (!eleicaoEmAndamento.compareAndSet(false, true)) {
            return;
        }

        boolean alguemRespondeu = false;
        try {
            int meuId = agenciaProperties.getId();
            registrar("ELEICAO_INICIADA", relogio.eventoLocal(), Map.of("idAgencia", meuId));

            for (int idAgencia = meuId + 1; idAgencia < agenciaProperties.getNumeroAgencias(); idAgencia++) {
                Map<String, Object> corpo = new LinkedHashMap<>();
                corpo.put("origemId", meuId);
                corpo.put("vetorEnvio", relogio.aoEnviar());
                if (postar(idAgencia, "/bully/eleicao", corpo)) {
                    alguemRespondeu = true;
                }
            }
        } finally {
            eleicaoEmAndamento.set(false);
        }

        if (!alguemRespondeu) {
            tornarMeLider();
        }
    }

    private void tornarMeLider() {
        int meuId = agenciaProperties.getId();
        liderAtual.set(meuId);
        registrar("TORNOU_LIDER", relogio.eventoLocal(), Map.of("idAgencia", meuId));

        for (int idAgencia = 0; idAgencia < agenciaProperties.getNumeroAgencias(); idAgencia++) {
            if (idAgencia == meuId) {
                continue;
            }
            Map<String, Object> corpo = new LinkedHashMap<>();
            corpo.put("liderId", meuId);
            corpo.put("vetorEnvio", relogio.aoEnviar());
            postar(idAgencia, "/bully/coordenador", corpo);
        }
    }

    /** Chegou uma pergunta de eleicao: o 200 da rota e o "OK" e, em paralelo, esta agencia inicia a sua eleicao. */
    public void receberEleicao(int origemId, int[] vetorRecebido) {
        registrar("ELEICAO_RECEBIDA", relogio.aoReceber(vetorRecebido),
                Map.of("de", origemId, "minhaId", agenciaProperties.getId()));
        executorEleicao.submit(this::iniciarEleicao);
    }

    public void receberCoordenador(int liderId, int[] vetorRecebido) {
        liderAtual.set(liderId);
        registrar("LIDER_ANUNCIADO", relogio.aoReceber(vetorRecebido),
                Map.of("liderId", liderId, "agencia", agenciaProperties.getId()));
    }

    /** Lider conhecido por esta agencia, ou null se ainda nao ha. */
    public Integer obterLiderAtual() {
        return liderAtual.get();
    }

    /** Se nao ha lider, elege; se o lider conhecido nao responde, esquece-o e elege de novo. */
    public void verificarLider() {
        Integer lider = liderAtual.get();
        if (lider == null) {
            iniciarEleicao();
            return;
        }
        int meuId = agenciaProperties.getId();
        if (lider == meuId) {
            return;
        }

        HttpRequest requisicao = HttpRequest.newBuilder(urlDaAgencia(lider, "/bully/lider"))
                .timeout(Duration.ofMillis(timeoutMs))
                .GET()
                .build();
        if (!respondeuOk(requisicao)) {
            Map<String, Object> detalhes = new LinkedHashMap<>();
            detalhes.put("liderAtual", lider);
            detalhes.put("agencia", meuId);
            registrar("LIDER_NAO_RESPONDEU", relogio.eventoLocal(), detalhes);
            liderAtual.set(null);
            iniciarEleicao();
        }
    }

    /**
     * Agenda verificarLider com intervalo fixo ENTRE execucoes. O try/catch
     * dentro da tarefa e obrigatorio: no ScheduledExecutorService, uma excecao
     * nao tratada cancela silenciosamente todas as execucoes futuras.
     */
    public void iniciarHeartbeat(long intervaloMs) {
        agendadorHeartbeat.scheduleWithFixedDelay(() -> {
            try {
                verificarLider();
            } catch (Exception excecao) {
                System.err.println("Falha no heartbeat do Bully: " + excecao.getMessage());
            }
        }, intervaloMs, intervaloMs, TimeUnit.MILLISECONDS);
    }

    /** POST em outra agencia; true somente se ela respondeu 2xx dentro do timeout. */
    private boolean postar(int idAgencia, String caminho, Map<String, Object> corpo) {
        try {
            HttpRequest requisicao = HttpRequest.newBuilder(urlDaAgencia(idAgencia, caminho))
                    .timeout(Duration.ofMillis(timeoutMs))
                    .header("Content-Type", "application/json")
                    .POST(HttpRequest.BodyPublishers.ofString(mapeadorJson.writeValueAsString(corpo)))
                    .build();
            return respondeuOk(requisicao);
        } catch (JsonProcessingException excecao) {
            return false;
        }
    }

    /** Qualquer falha (agencia fora do ar, timeout, status nao 2xx) conta como "nao respondeu". */
    private boolean respondeuOk(HttpRequest requisicao) {
        try {
            HttpResponse<Void> resposta = clienteHttp.send(requisicao, HttpResponse.BodyHandlers.discarding());
            return resposta.statusCode() / 100 == 2;
        } catch (IOException excecao) {
            return false;
        } catch (InterruptedException excecao) {
            Thread.currentThread().interrupt();
            return false;
        }
    }

    private URI urlDaAgencia(int idAgencia, String caminho) {
        return URI.create("http://localhost:" + agenciaProperties.portaDaAgencia(idAgencia) + caminho);
    }

    /** Falha ao gravar o log nao pode derrubar a eleicao: apenas avisa no stderr. */
    private void registrar(String tipo, int[] vetor, Map<String, Object> detalhes) {
        try {
            eventLog.registrar(tipo, vetor, detalhes);
        } catch (IOException excecao) {
            System.err.println("Falha ao registrar evento " + tipo + ": " + excecao.getMessage());
        }
    }
}

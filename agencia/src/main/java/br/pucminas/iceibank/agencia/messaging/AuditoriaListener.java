package br.pucminas.iceibank.agencia.messaging;

import java.io.FileWriter;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.time.Instant;

import org.springframework.amqp.core.Message;
import org.springframework.amqp.rabbit.annotation.RabbitListener;
import org.springframework.stereotype.Component;

import br.pucminas.iceibank.agencia.config.AgenciaProperties;
import br.pucminas.iceibank.agencia.config.AmqpConfig;

// Classe criada pela IA para a funcionalidade adicional do Sprint 2 (fila de auditoria).

/**
 * Funcionalidade adicional do Sprint 2: trilha de auditoria central.
 *
 * Toda mensagem publicada em iceibank.eventos com routing key agencia.#
 * tambem cai na fila-auditoria. As 3 agencias consomem dessa MESMA fila
 * (consumidores concorrentes): cada mensagem e entregue a so uma delas, que
 * grava a copia em data/auditoria.jsonl.
 *
 * Nao mexe no relogio vetorial nem nas contas: e so observacao, nao um
 * evento de negocio da agencia.
 */
@Component
public class AuditoriaListener {

    private final String nomeAgencia;
    private final Path caminhoArquivo;

    public AuditoriaListener(AgenciaProperties agenciaProperties) throws IOException {
        this.nomeAgencia = "agencia-" + agenciaProperties.getId();
        Path pastaDados = Paths.get("data");
        Files.createDirectories(pastaDados);
        this.caminhoArquivo = pastaDados.resolve("auditoria.jsonl");
    }

    @RabbitListener(queues = AmqpConfig.FILA_AUDITORIA)
    public void auditar(Message mensagem) throws IOException {
        String routingKey = mensagem.getMessageProperties().getReceivedRoutingKey();
        String corpo = new String(mensagem.getBody(), StandardCharsets.UTF_8);

        // O corpo ja e JSON (Jackson2JsonMessageConverter), entao entra direto na linha.
        String linha = "{\"auditadoEm\":\"" + Instant.now() + "\""
                + ",\"auditadoPor\":\"" + nomeAgencia + "\""
                + ",\"routingKey\":\"" + routingKey + "\""
                + ",\"mensagem\":" + corpo + "}";

        try (FileWriter writer = new FileWriter(caminhoArquivo.toFile(), true)) {
            writer.write(linha + System.lineSeparator());
        }
        System.out.println("[Auditoria] " + routingKey + " " + corpo);
    }
}

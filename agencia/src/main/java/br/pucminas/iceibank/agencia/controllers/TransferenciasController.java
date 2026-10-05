package br.pucminas.iceibank.agencia.controllers;

import java.io.IOException;
import java.util.Map;

import org.springframework.amqp.AmqpException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

import br.pucminas.iceibank.agencia.config.AgenciaProperties;
import br.pucminas.iceibank.agencia.entities.Conta;
import br.pucminas.iceibank.agencia.messaging.CreditoRemotoMessage;
import br.pucminas.iceibank.agencia.messaging.MensageriaService;
import br.pucminas.iceibank.agencia.service.EventLogService;
import br.pucminas.iceibank.agencia.service.RelogioVetorial;
import br.pucminas.iceibank.agencia.store.ContaStore;

@RestController
public class TransferenciasController {

    private final Map<Integer, Conta> contas;
    private final AgenciaProperties agenciaProperties;
    private final RelogioVetorial relogio;
    private final EventLogService registro;
    private final MensageriaService mensageria;

    public TransferenciasController(ContaStore contaStore,
                                     AgenciaProperties agenciaProperties,
                                     RelogioVetorial relogio,
                                     EventLogService registro,
                                     MensageriaService mensageria) {
        this.contas = contaStore.getContas();
        this.agenciaProperties = agenciaProperties;
        this.relogio = relogio;
        this.registro = registro;
        this.mensageria = mensageria;
    }

    @PostMapping("/transferencias")
    public ResponseEntity<?> transferir(@RequestBody Map<String, Object> corpo) throws IOException {
        int idOrigem = ((Number) corpo.get("idOrigem")).intValue();
        int idDestino = ((Number) corpo.get("idDestino")).intValue();
        double valor = ((Number) corpo.get("valor")).doubleValue();

        Conta contaOrigem = contas.get(idOrigem);
        if (contaOrigem == null) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(Map.of("erro", "Conta de origem não encontrada nesta agência."));
        }
        if (contaOrigem.getSaldo() < valor) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(Map.of("erro", "Saldo insuficiente."));
        }

        int agenciaDestino = agenciaProperties.agenciaResponsavel(idDestino);

        // O debito e sempre local, pois esta agencia e a dona da conta de origem
        int[] tsDebito = relogio.eventoLocal();
        contaOrigem.setSaldo(contaOrigem.getSaldo() - valor);
        registro.registrar("TRANSFERENCIA_DEBITO", tsDebito, Map.of(
                "idOrigem", idOrigem,
                "idDestino", idDestino,
                "valor", valor));

        if (agenciaDestino == agenciaProperties.getId()) {
            // Caso simples: mesma agencia, credita direto
            Conta contaDestino = contas.get(idDestino);
            if (contaDestino == null) {
                contaOrigem.setSaldo(contaOrigem.getSaldo() + valor);
                return ResponseEntity.status(HttpStatus.NOT_FOUND)
                        .body(Map.of("erro", "Conta de destino não encontrada."));
            }
            int[] tsCredito = relogio.eventoLocal();
            contaDestino.setSaldo(contaDestino.getSaldo() + valor);
            registro.registrar("TRANSFERENCIA_CREDITO", tsCredito, Map.of(
                    "idOrigem", idOrigem,
                    "idDestino", idDestino,
                    "valor", valor));
            return ResponseEntity.ok(Map.of("mensagem", "Transferência concluída (mesma agência)."));
        }

        // Caso entre agencias: publica um pedido de credito na exchange. A agencia
        // de destino consome da propria fila quando puder (comunicacao indireta),
        // entao o 200 aqui significa "mensagem publicada", nao "credito aplicado".
        int[] vetorEnvio = relogio.aoEnviar();
        String routingKey = "agencia." + agenciaDestino + ".creditar";
        try {
            mensageria.publicar(routingKey,
                    new CreditoRemotoMessage(idDestino, valor, vetorEnvio, agenciaProperties.getId()));
            return ResponseEntity.ok(Map.of("mensagem",
                    "Transferência publicada para a agência " + agenciaDestino + " (crédito assíncrono)."));
        } catch (AmqpException erro) {
            // LIMITACAO CONHECIDA: se a publicacao falhar (broker fora do ar), o debito
            // ja aplicado acima NAO e revertido. O mesmo vale se o destino nao achar a
            // conta (CREDITO_REMOTO_FALHOU): a origem nem fica sabendo. Resolver isso de
            // forma correta e o assunto do Sprint 4 (2PC/Saga). Por enquanto, so
            // registramos a inconsistencia no log.
            registro.registrar("TRANSFERENCIA_FALHOU", relogio.eventoLocal(), Map.of(
                    "idOrigem", idOrigem,
                    "idDestino", idDestino,
                    "valor", valor,
                    "erro", String.valueOf(erro.getMessage())));
            return ResponseEntity.status(HttpStatus.BAD_GATEWAY)
                    .body(Map.of("erro", "Falha ao publicar no RabbitMQ. Débito já aplicado - inconsistência conhecida (ver Sprint 4)."));
        }
    }
}

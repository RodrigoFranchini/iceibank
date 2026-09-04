package br.pucminas.iceibank.agencia.controllers;

import java.io.IOException;
import java.util.Map;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.client.RestClientException;
import org.springframework.web.client.RestTemplate;

import br.pucminas.iceibank.agencia.config.AgenciaProperties;
import br.pucminas.iceibank.agencia.entities.Conta;
import br.pucminas.iceibank.agencia.service.EventLogService;
import br.pucminas.iceibank.agencia.service.LamportClockService;
import br.pucminas.iceibank.agencia.store.ContaStore;

@RestController
public class TransferenciasController {

    private final Map<Integer, Conta> contas;
    private final AgenciaProperties agenciaProperties;
    private final LamportClockService relogio;
    private final EventLogService registro;
    private final RestTemplate restTemplate = new RestTemplate();

    public TransferenciasController(ContaStore contaStore,
                                     AgenciaProperties agenciaProperties,
                                     LamportClockService relogio,
                                     EventLogService registro) {
        this.contas = contaStore.getContas();
        this.agenciaProperties = agenciaProperties;
        this.relogio = relogio;
        this.registro = registro;
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
        int tsDebito = relogio.eventoLocal();
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
            int tsCredito = relogio.eventoLocal();
            contaDestino.setSaldo(contaDestino.getSaldo() + valor);
            registro.registrar("TRANSFERENCIA_CREDITO", tsCredito, Map.of(
                    "idOrigem", idOrigem,
                    "idDestino", idDestino,
                    "valor", valor));
            return ResponseEntity.ok(Map.of("mensagem", "Transferência concluída (mesma agência)."));
        }

        // Caso entre agencias: chama a agencia de destino diretamente via REST
        int tsEnvio = relogio.aoEnviar();
        String urlDestino = agenciaProperties.urlDaAgencia(agenciaDestino);
        try {
            Map<String, Object> payload = Map.of(
                    "valor", valor,
                    "timestampLamport", tsEnvio,
                    "origemAgencia", agenciaProperties.getId());
            restTemplate.postForEntity(urlDestino + "/contas/" + idDestino + "/creditar-remoto", payload, Void.class);
            return ResponseEntity.ok(Map.of("mensagem", "Transferência concluída (entre agências)."));
        } catch (RestClientException erro) {
            // LIMITACAO CONHECIDA: se esta chamada falhar, o debito ja aplicado acima
            // NAO e revertido - o dinheiro "desaparece" temporariamente. Resolver isso
            // de forma correta e o assunto do Sprint 4 (2PC/Saga). Por enquanto, so
            // registramos a inconsistencia no log.
            registro.registrar("TRANSFERENCIA_FALHOU", relogio.eventoLocal(), Map.of(
                    "idOrigem", idOrigem,
                    "idDestino", idDestino,
                    "valor", valor,
                    "erro", String.valueOf(erro.getMessage())));
            return ResponseEntity.status(HttpStatus.BAD_GATEWAY)
                    .body(Map.of("erro", "Falha ao contatar agência de destino. Débito já aplicado - inconsistência conhecida (ver Sprint 4)."));
        }
    }

    @PostMapping("/contas/{id}/creditar-remoto")
    public ResponseEntity<?> creditarRemoto(@PathVariable("id") int idConta, @RequestBody Map<String, Object> corpo) throws IOException {
        double valor = ((Number) corpo.get("valor")).doubleValue();
        int timestampLamport = ((Number) corpo.get("timestampLamport")).intValue();
        int origemAgencia = ((Number) corpo.get("origemAgencia")).intValue();

        // Ao RECEBER uma mensagem de outra agencia, o relogio de Lamport e
        // atualizado com base no timestamp recebido - e a regra 3 do algoritmo.
        int ts = relogio.aoReceber(timestampLamport);

        Conta conta = contas.get(idConta);
        if (conta == null) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(Map.of("erro", "Conta não encontrada nesta agência."));
        }
        conta.setSaldo(conta.getSaldo() + valor);
        registro.registrar("TRANSFERENCIA_CREDITO_REMOTO", ts, Map.of(
                "idConta", idConta,
                "valor", valor,
                "origemAgencia", origemAgencia));

        return ResponseEntity.ok(Map.of("mensagem", "Crédito remoto aplicado.", "saldoAtual", conta.getSaldo()));
    }
}

package br.pucminas.iceibank.agencia.controllers;

import java.io.IOException;
import java.util.Map;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import br.pucminas.iceibank.agencia.config.AgenciaProperties;
import br.pucminas.iceibank.agencia.entities.Conta;
import br.pucminas.iceibank.agencia.service.EventLogService;
import br.pucminas.iceibank.agencia.service.LamportClockService;
import br.pucminas.iceibank.agencia.store.ContaStore;

@RestController
@RequestMapping("/contas")
public class ContasController {

    private final AgenciaProperties agenciaProperties;
    private final LamportClockService relogio;
    private final EventLogService registro;
    private final Map<Integer, Conta> contas;

    public ContasController(AgenciaProperties agenciaProperties,
                             LamportClockService relogio,
                             EventLogService registro,
                             ContaStore contaStore) {
        this.agenciaProperties = agenciaProperties;
        this.relogio = relogio;
        this.registro = registro;
        this.contas = contaStore.getContas();
    }

    @PostMapping
    public ResponseEntity<?> criarConta(@RequestBody Map<String, Object> corpo) throws IOException {
        int id = ((Number) corpo.get("id")).intValue();
        String nomeAluno = (String) corpo.get("nomeAluno");
        double saldoInicial = corpo.get("saldoInicial") != null ? ((Number) corpo.get("saldoInicial")).doubleValue() : 0;

        if (agenciaProperties.agenciaResponsavel(id) != agenciaProperties.getId()) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(Map.of("erro", "Conta " + id + " não pertence a esta agência."));
        }
        if (contas.containsKey(id)) {
            return ResponseEntity.status(HttpStatus.CONFLICT)
                    .body(Map.of("erro", "Conta já existe."));
        }

        int ts = relogio.eventoLocal();
        Conta conta = new Conta();
        conta.setId(id);
        conta.setNomeAluno(nomeAluno);
        conta.setSaldo(saldoInicial);
        contas.put(id, conta);

        registro.registrar("CRIAR_CONTA", ts, Map.of(
                "id", id,
                "nomeAluno", nomeAluno,
                "saldoInicial", saldoInicial));

        return ResponseEntity.status(HttpStatus.CREATED).body(conta);
    }

    @GetMapping("/{id}")
    public ResponseEntity<?> consultarSaldo(@PathVariable("id") int id) {
        Conta conta = contas.get(id);
        if (conta == null) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(Map.of("erro", "Conta não encontrada nesta agência."));
        }
        return ResponseEntity.ok(conta);
    }

    @PostMapping("/{id}/depositar")
    public ResponseEntity<?> depositar(@PathVariable("id") int id, @RequestBody Map<String, Object> corpo) throws IOException {
        Conta conta = contas.get(id);
        if (conta == null) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(Map.of("erro", "Conta não encontrada nesta agência."));
        }
        double valor = ((Number) corpo.get("valor")).doubleValue();

        int ts = relogio.eventoLocal();
        conta.setSaldo(conta.getSaldo() + valor);

        registro.registrar("DEPOSITO", ts, Map.of(
                "id", id,
                "valor", valor,
                "novoSaldo", conta.getSaldo()));

        return ResponseEntity.ok(conta);
    }

    @PostMapping("/{id}/sacar")
    public ResponseEntity<?> sacar(@PathVariable("id") int id, @RequestBody Map<String, Object> corpo) throws IOException {
        Conta conta = contas.get(id);
        if (conta == null) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(Map.of("erro", "Conta não encontrada nesta agência."));
        }
        double valor = ((Number) corpo.get("valor")).doubleValue();
        if (conta.getSaldo() < valor) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(Map.of("erro", "Saldo insuficiente."));
        }

        int ts = relogio.eventoLocal();
        conta.setSaldo(conta.getSaldo() - valor);

        registro.registrar("SAQUE", ts, Map.of(
                "id", id,
                "valor", valor,
                "novoSaldo", conta.getSaldo()));

        return ResponseEntity.ok(conta);
    }
}

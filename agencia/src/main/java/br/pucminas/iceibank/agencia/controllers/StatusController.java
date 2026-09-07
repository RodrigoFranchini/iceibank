package br.pucminas.iceibank.agencia.controllers;

import java.util.Map;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import br.pucminas.iceibank.agencia.config.AgenciaProperties;
import br.pucminas.iceibank.agencia.service.LamportClockService;
import br.pucminas.iceibank.agencia.store.ContaStore;

@RestController
public class StatusController {

    private final AgenciaProperties agenciaProperties;
    private final LamportClockService relogio;
    private final ContaStore contaStore;

    public StatusController(AgenciaProperties agenciaProperties, LamportClockService relogio, ContaStore contaStore) {
        this.agenciaProperties = agenciaProperties;
        this.relogio = relogio;
        this.contaStore = contaStore;
    }

    // /health publico
    @GetMapping("/health")
    public Map<String, Object> health() {
        return Map.of("idAgencia", agenciaProperties.getId(), "status", "UP");
    }

    // curl -s http://localhost:4000/status -H "Authorization: Bearer $TOKEN"
    @GetMapping("/status")
    public Map<String, Object> status() {
        return Map.of(
                "contadorLamport", relogio.contadorAtual(),
                "quantidadeContas", contaStore.getContas().size());
    }
}

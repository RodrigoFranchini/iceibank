package br.pucminas.iceibank.agencia.controllers;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import br.pucminas.iceibank.agencia.config.AgenciaProperties;
import br.pucminas.iceibank.agencia.service.BullyService;

/**
 * Rotas do algoritmo de Bully, chamadas pelas outras agencias (sem JWT).
 */
@RestController
@RequestMapping("/bully")
public class BullyController {

    private final BullyService bullyService;
    private final AgenciaProperties agenciaProperties;

    public BullyController(BullyService bullyService, AgenciaProperties agenciaProperties) {
        this.bullyService = bullyService;
        this.agenciaProperties = agenciaProperties;
    }

    @PostMapping("/eleicao")
    public ResponseEntity<?> eleicao(@RequestBody Map<String, Object> corpo) {
        int origemId = ((Number) corpo.get("origemId")).intValue();
        bullyService.receberEleicao(origemId, converterVetor(corpo.get("vetorEnvio")));
        return ResponseEntity.ok().build();
    }

    @PostMapping("/coordenador")
    public ResponseEntity<?> coordenador(@RequestBody Map<String, Object> corpo) {
        int liderId = ((Number) corpo.get("liderId")).intValue();
        bullyService.receberCoordenador(liderId, converterVetor(corpo.get("vetorEnvio")));
        return ResponseEntity.ok().build();
    }

    // liderAtual pode ser null; por isso LinkedHashMap (Map.of rejeita null)
    @GetMapping("/lider")
    public ResponseEntity<?> lider() {
        Map<String, Object> resposta = new LinkedHashMap<>();
        resposta.put("idAgencia", agenciaProperties.getId());
        resposta.put("liderAtual", bullyService.obterLiderAtual());
        return ResponseEntity.ok(resposta);
    }

    /** O JSON entrega o vetor como lista de numeros; o relogio trabalha com int[]. */
    private int[] converterVetor(Object vetorJson) {
        List<?> lista = (List<?>) vetorJson;
        int[] vetor = new int[lista.size()];
        for (int i = 0; i < vetor.length; i++) {
            vetor[i] = ((Number) lista.get(i)).intValue();
        }
        return vetor;
    }
}

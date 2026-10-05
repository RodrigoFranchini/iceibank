package br.pucminas.iceibank.agencia.messaging;

import java.io.IOException;
import java.util.Map;

import org.springframework.amqp.rabbit.annotation.RabbitListener;
import org.springframework.stereotype.Component;

import br.pucminas.iceibank.agencia.entities.Conta;
import br.pucminas.iceibank.agencia.service.EventLogService;
import br.pucminas.iceibank.agencia.service.RelogioVetorial;
import br.pucminas.iceibank.agencia.store.ContaStore;

// Classe criada pela IA para consumir a fila da agencia e aplicar o credito remoto, substituindo a rota creditar-remoto do Sprint 1.

/**
 * Consumidor da fila desta agencia: substitui a rota HTTP
 * /contas/{id}/creditar-remoto do Sprint 1.
 *
 * Nao passa pelo filtro JWT (nao e uma requisicao HTTP): quem pode publicar
 * na fila e controlado pelas credenciais do broker (usuario/senha da
 * RABBITMQ_URL).
 */
@Component
public class CreditoRemotoListener {

    private final Map<Integer, Conta> contas;
    private final RelogioVetorial relogio;
    private final EventLogService registro;

    public CreditoRemotoListener(ContaStore contaStore, RelogioVetorial relogio, EventLogService registro) {
        this.contas = contaStore.getContas();
        this.relogio = relogio;
        this.registro = registro;
    }

    @RabbitListener(queues = "fila-agencia-${iceibank.id}")
    public void aoReceberCredito(CreditoRemotoMessage mensagem) throws IOException {
        // Regra 3 do relogio vetorial: max com o vetor que veio na mensagem.
        int[] ts = relogio.aoReceber(mensagem.vetorEnvio());

        Conta conta = contas.get(mensagem.idConta());
        if (conta == null) {
            // So registra e retorna. Se lancasse excecao, o Spring devolveria a
            // mensagem para a fila (requeue) e ela voltaria para ca em loop infinito.
            registro.registrar("CREDITO_REMOTO_FALHOU", ts, Map.of(
                    "idConta", mensagem.idConta(),
                    "valor", mensagem.valor(),
                    "origemAgencia", mensagem.origemAgencia(),
                    "motivo", "Conta não encontrada nesta agência."));
            return;
        }

        conta.setSaldo(conta.getSaldo() + mensagem.valor());
        registro.registrar("TRANSFERENCIA_CREDITO_REMOTO", ts, Map.of(
                "idConta", mensagem.idConta(),
                "valor", mensagem.valor(),
                "origemAgencia", mensagem.origemAgencia()));
    }
}

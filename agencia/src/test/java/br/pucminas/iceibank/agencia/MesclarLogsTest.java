package br.pucminas.iceibank.agencia;

import static org.junit.jupiter.api.Assertions.assertEquals;

import org.junit.jupiter.api.Test;

import br.pucminas.iceibank.agencia.MesclarLogs.Relacao;

// Testes criados pela IA para a comparacao de vetores (exemplos da secao 6.4 do roteiro).

class MesclarLogsTest {

    @Test
    void exemplo1DoRoteiroEhCausal() {
        // [3,1,0] <= [3,2,0] em todas as posicoes: o primeiro aconteceu antes
        assertEquals(Relacao.ANTES, MesclarLogs.compararVetores(new int[] {3, 1, 0}, new int[] {3, 2, 0}));
        assertEquals(Relacao.DEPOIS, MesclarLogs.compararVetores(new int[] {3, 2, 0}, new int[] {3, 1, 0}));
    }

    @Test
    void exemplo2DoRoteiroEhConcorrente() {
        // [3,1,0] e maior na posicao 0, [1,3,0] e maior na posicao 1
        assertEquals(Relacao.CONCORRENTES, MesclarLogs.compararVetores(new int[] {3, 1, 0}, new int[] {1, 3, 0}));
    }

    @Test
    void vetoresIguais() {
        assertEquals(Relacao.IGUAIS, MesclarLogs.compararVetores(new int[] {1, 2, 3}, new int[] {1, 2, 3}));
    }

    @Test
    void debitoAntesDoCreditoRemoto() {
        // debito na A0 [2,0,0]; credito na A1 apos receber [3,0,0] -> [3,2,0]
        assertEquals(Relacao.ANTES, MesclarLogs.compararVetores(new int[] {2, 0, 0}, new int[] {3, 2, 0}));
    }
}

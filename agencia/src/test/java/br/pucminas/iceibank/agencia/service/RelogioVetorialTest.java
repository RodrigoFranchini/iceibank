package br.pucminas.iceibank.agencia.service;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;

import org.junit.jupiter.api.Test;

// Testes criados pela IA para as 3 regras do relogio vetorial.

class RelogioVetorialTest {

    @Test
    void eventoLocalIncrementaSoAPropriaPosicao() {
        RelogioVetorial relogio = new RelogioVetorial(1, 3);

        assertArrayEquals(new int[] {0, 1, 0}, relogio.eventoLocal());
        assertArrayEquals(new int[] {0, 2, 0}, relogio.eventoLocal());
    }

    @Test
    void aoEnviarTambemIncrementaSoAPropriaPosicao() {
        RelogioVetorial relogio = new RelogioVetorial(2, 3);

        assertArrayEquals(new int[] {0, 0, 1}, relogio.aoEnviar());
    }

    @Test
    void aoReceberFazMaxPosicaoAPosicaoEDepoisIncrementaAPropria() {
        RelogioVetorial relogio = new RelogioVetorial(1, 3);
        relogio.eventoLocal(); // [0,1,0]

        // vetor recebido [3,0,2] -> max = [3,1,2] -> incrementa a propria -> [3,2,2]
        assertArrayEquals(new int[] {3, 2, 2}, relogio.aoReceber(new int[] {3, 0, 2}));
    }

    @Test
    void sequenciaDeTransferenciaEntreAgencias() {
        RelogioVetorial agencia0 = new RelogioVetorial(0, 3);
        RelogioVetorial agencia1 = new RelogioVetorial(1, 3);

        agencia0.eventoLocal();                  // A0 cria conta     -> [1,0,0]
        agencia1.eventoLocal();                  // A1 cria conta     -> [0,1,0]
        agencia0.eventoLocal();                  // A0 debita         -> [2,0,0]
        int[] vetorEnvio = agencia0.aoEnviar();  // A0 publica        -> [3,0,0]

        assertArrayEquals(new int[] {3, 0, 0}, vetorEnvio);
        assertArrayEquals(new int[] {3, 2, 0}, agencia1.aoReceber(vetorEnvio));
    }

    @Test
    void retornaCopiaENaoOArrayInterno() {
        RelogioVetorial relogio = new RelogioVetorial(0, 3);
        int[] registrado = relogio.eventoLocal();

        relogio.eventoLocal();
        registrado[1] = 99;

        assertArrayEquals(new int[] {1, 99, 0}, registrado);
        assertArrayEquals(new int[] {2, 0, 0}, relogio.vetorAtual());
    }
}

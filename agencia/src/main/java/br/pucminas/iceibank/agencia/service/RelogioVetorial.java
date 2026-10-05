package br.pucminas.iceibank.agencia.service;

import java.util.Arrays;

// Classe criada pela IA para implementar o relogio vetorial (3 regras), substituindo o relogio de Lamport do Sprint 1.

/**
 * Relogio vetorial (substitui o relogio de Lamport do Sprint 1).
 *
 * Cada agencia guarda um contador por agencia do sistema: a posicao
 * idAgencia e o "quanto eu ja fiz"; as demais posicoes sao "o quanto eu sei
 * que cada outra agencia ja fez".
 *
 * Todos os metodos sao synchronized porque o Spring atende requisicoes HTTP
 * e mensagens do RabbitMQ em threads diferentes, e todos retornam uma COPIA
 * do vetor: se o array interno vazasse para o log, ele "mudaria sozinho"
 * depois, a cada novo evento.
 */
public class RelogioVetorial {

    private final int idAgencia;
    private final int[] vetor;

    public RelogioVetorial(int idAgencia, int numeroAgencias) {
        this.idAgencia = idAgencia;
        this.vetor = new int[numeroAgencias];
    }

    /** Regra 1: evento local incrementa apenas a propria posicao. */
    public synchronized int[] eventoLocal() {
        vetor[idAgencia]++;
        return vetor.clone();
    }

    /** Regra 2: envio de mensagem e um evento local; o vetor retornado viaja na mensagem. */
    public synchronized int[] aoEnviar() {
        vetor[idAgencia]++;
        return vetor.clone();
    }

    /** Regra 3: ao receber, max posicao a posicao com o vetor recebido e depois incrementa a propria. */
    public synchronized int[] aoReceber(int[] vetorRecebido) {
        for (int i = 0; i < vetor.length; i++) {
            vetor[i] = Math.max(vetor[i], vetorRecebido[i]);
        }
        vetor[idAgencia]++;
        return vetor.clone();
    }

    /** Le o vetor atual, sem incrementar. */
    public synchronized int[] vetorAtual() {
        return vetor.clone();
    }

    @Override
    public synchronized String toString() {
        return Arrays.toString(vetor);
    }
}

package br.pucminas.iceibank.agencia.service;

/**
 * Comparacao de relogios vetoriais, usada tanto pelo mesclador de logs quanto
 * pela sincronizacao offline (para detectar se o app esta desatualizado).
 */
public final class CompararVetores {

    public enum Relacao { ANTES, DEPOIS, IGUAIS, CONCORRENTES }

    private CompararVetores() {
    }

    /**
     * Compara dois vetores posicao a posicao:
     * - v1 <= v2 em todas as posicoes (e diferentes): v1 aconteceu ANTES de v2;
     * - v1 >= v2 em todas as posicoes (e diferentes): v1 aconteceu DEPOIS de v2;
     * - cada um e maior em pelo menos uma posicao: CONCORRENTES (nenhum
     *   dos dois poderia saber do outro).
     */
    public static Relacao comparar(int[] v1, int[] v2) {
        boolean algumMenor = false;
        boolean algumMaior = false;
        for (int i = 0; i < v1.length; i++) {
            if (v1[i] < v2[i]) algumMenor = true;
            if (v1[i] > v2[i]) algumMaior = true;
        }
        if (algumMenor && algumMaior) return Relacao.CONCORRENTES;
        if (algumMenor) return Relacao.ANTES;
        if (algumMaior) return Relacao.DEPOIS;
        return Relacao.IGUAIS;
    }
}

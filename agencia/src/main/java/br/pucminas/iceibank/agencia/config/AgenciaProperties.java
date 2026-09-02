package br.pucminas.iceibank.agencia.config;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

/**
 * Equivalente ao config.js do roteiro: guarda a identidade desta agencia e a
 * regra de particionamento das contas entre as agencias do ICEIBank.
 *
 * Os valores vem do application.properties (prefixo "iceibank") e podem ser
 * sobrescritos na linha de comando, ex.: --iceibank.id=1
 */
@Component
@ConfigurationProperties(prefix = "iceibank")
public class AgenciaProperties {

    /** Porta base do roteiro, antes de somar o OFFSET pessoal. */
    private static final int PORTA_BASE_PADRAO = 4000;

    /** Dois ultimos digitos da matricula/RA, para evitar conflito de portas em maquina compartilhada. */
    private int offset;

    /** Quantidade total de agencias do sistema (fixado em 3 no Sprint 1). */
    private int numeroAgencias;

    /** Identificador desta agencia (0, 1 ou 2). */
    private int id;

    /**
     * Regra de particionamento: cada conta pertence a exatamente uma agencia.
     * Math.floorMod (e nao o operador %) garante resultado nao negativo caso
     * algum dia um id de conta negativo chegue ate aqui.
     */
    public int agenciaResponsavel(int idConta) {
        return Math.floorMod(idConta, numeroAgencias);
    }

    /** Porta em que a agencia informada escuta. */
    public int portaDaAgencia(int idAgencia) {
        return PORTA_BASE_PADRAO + offset + idAgencia;
    }

    /** URL base da agencia informada, usada nas chamadas entre agencias. */
    public String urlDaAgencia(int idAgencia) {
        return "http://localhost:" + portaDaAgencia(idAgencia);
    }

    public int getOffset() {
        return offset;
    }

    public void setOffset(int offset) {
        this.offset = offset;
    }

    public int getNumeroAgencias() {
        return numeroAgencias;
    }

    public void setNumeroAgencias(int numeroAgencias) {
        this.numeroAgencias = numeroAgencias;
    }

    public int getId() {
        return id;
    }

    public void setId(int id) {
        this.id = id;
    }
}

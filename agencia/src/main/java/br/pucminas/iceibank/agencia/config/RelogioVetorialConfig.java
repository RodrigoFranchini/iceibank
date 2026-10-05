package br.pucminas.iceibank.agencia.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import br.pucminas.iceibank.agencia.service.RelogioVetorial;

// Classe criada pela IA para registrar o relogio vetorial como bean com o id e o numero de agencias da configuracao.

/**
 * Registra o relogio vetorial como bean unico da agencia, com o id e o
 * numero de agencias vindos do application.properties / linha de comando.
 */
@Configuration
public class RelogioVetorialConfig {

    @Bean
    public RelogioVetorial relogioVetorial(AgenciaProperties agenciaProperties) {
        return new RelogioVetorial(agenciaProperties.getId(), agenciaProperties.getNumeroAgencias());
    }
}

package br.pucminas.iceibank.agencia.config;

import org.springframework.boot.web.server.ConfigurableWebServerFactory;
import org.springframework.boot.web.server.WebServerFactoryCustomizer;
import org.springframework.stereotype.Component;

// Classe criada pela IA para realizar a customizacao da porta do servidor web, equivalente ao trecho final do app.js do roteiro.

/**
 * Equivalente ao trecho final do app.js:
 *   const porta = new URL(agenciaConfig.url).port;
 *   app.listen(porta, ...);
 *
 * Faz a agencia escutar automaticamente na porta que lhe corresponde
 * (4000 + offset + id), sem precisar informar --server.port na linha de
 * comando - basta informar --iceibank.id ao subir a aplicacao.
 */
@Component
public class PortaAgenciaCustomizer implements WebServerFactoryCustomizer<ConfigurableWebServerFactory> {

    private final AgenciaProperties agenciaProperties;

    public PortaAgenciaCustomizer(AgenciaProperties agenciaProperties) {
        this.agenciaProperties = agenciaProperties;
    }

    @Override
    public void customize(ConfigurableWebServerFactory factory) {
        factory.setPort(agenciaProperties.portaDaAgencia(agenciaProperties.getId()));
    }
}

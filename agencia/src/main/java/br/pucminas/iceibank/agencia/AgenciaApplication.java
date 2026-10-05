package br.pucminas.iceibank.agencia;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class AgenciaApplication {

    public static void main(String[] args) {
        // Falha rapido (equivalente ao process.exit(1) do exemplo do roteiro):
        // sem o broker a agencia nao consegue trocar mensagens com as outras.
        String rabbitUrl = System.getenv("RABBITMQ_URL");
        if (rabbitUrl == null || rabbitUrl.isBlank()) {
            System.err.println("ERRO: variavel de ambiente RABBITMQ_URL nao definida.");
            System.exit(1);
        }
        SpringApplication.run(AgenciaApplication.class, args);
    }
}

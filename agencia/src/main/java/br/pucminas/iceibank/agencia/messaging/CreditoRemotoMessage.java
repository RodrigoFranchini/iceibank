package br.pucminas.iceibank.agencia.messaging;

// Classe criada pela IA para representar a mensagem de credito remoto trocada entre agencias via RabbitMQ.

/**
 * Mensagem publicada pela agencia de origem para pedir o credito na agencia
 * de destino. O vetorEnvio (relogio vetorial no momento do envio) viaja
 * DENTRO da mensagem, para o destino aplicar a regra 3 do relogio ao receber.
 */
public record CreditoRemotoMessage(int idConta, double valor, int[] vetorEnvio, int origemAgencia) {
}

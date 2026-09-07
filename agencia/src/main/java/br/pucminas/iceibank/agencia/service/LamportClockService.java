package br.pucminas.iceibank.agencia.service;

public interface LamportClockService {

    // Registra um evento local, incrementando o contador, retorna o contador atualizado.
    int eventoLocal();

    // Incrementa o contador ao fazer uma operação de envio, retorna o contador atualizado.
    int aoEnviar();

    // Incrementa o contador ao receber um evento de outro processo, retornando o contador atualizado.
    int aoReceber(int timestampRecebido);

    // Le o valor atual do contador, sem incrementar.
    int contadorAtual();
}

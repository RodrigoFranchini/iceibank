package br.pucminas.iceibank.agencia.service.serviceImpl;

import org.springframework.stereotype.Service;

import br.pucminas.iceibank.agencia.service.LamportClockService;

@Service
public class LamportClockServiceImpl implements LamportClockService {
    private int contador;

    public LamportClockServiceImpl(){
        this.contador = 0;
    }

    @Override
    public synchronized int eventoLocal() {
        contador++;
        return contador;
    }

    @Override
    public synchronized int aoEnviar() {
        contador++;
        return contador;
    }

    @Override
    public synchronized int aoReceber(int timestampRecebido) {
        contador = Math.max(contador, timestampRecebido) + 1;
        return contador;
    }
}

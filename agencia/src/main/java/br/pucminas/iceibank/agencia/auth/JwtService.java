package br.pucminas.iceibank.agencia.auth;

import java.util.Date;

import javax.crypto.SecretKey;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;

@Service
public class JwtService {

    private final SecretKey chaveAssinatura;
    private final long expiracaoEmMilissegundos;

    public JwtService(@Value("${jwt.segredo}") String segredo,
                       @Value("${jwt.expiracao-minutos}") long expiracaoEmMinutos) {
        this.chaveAssinatura = Keys.hmacShaKeyFor(segredo.getBytes());
        this.expiracaoEmMilissegundos = expiracaoEmMinutos * 60 * 1000;
    }

    public String gerarToken(String usuario) {
        Date agora = new Date();
        Date expiracao = new Date(agora.getTime() + expiracaoEmMilissegundos);
        return Jwts.builder()
                .subject(usuario)
                .issuedAt(agora)
                .expiration(expiracao)
                .signWith(chaveAssinatura)
                .compact();
    }

    public String extrairUsuario(String token) {
        return Jwts.parser()
                .verifyWith(chaveAssinatura)
                .build()
                .parseSignedClaims(token)
                .getPayload()
                .getSubject();
    }
}

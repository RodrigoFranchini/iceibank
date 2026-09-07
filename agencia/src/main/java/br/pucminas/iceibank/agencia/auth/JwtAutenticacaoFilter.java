package br.pucminas.iceibank.agencia.auth;

import java.io.IOException;

import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import io.jsonwebtoken.JwtException;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

@Component
public class JwtAutenticacaoFilter extends OncePerRequestFilter {

    private final JwtService jwtService;

    public JwtAutenticacaoFilter(JwtService jwtService) {
        this.jwtService = jwtService;
    }

    @Override
    protected void doFilterInternal(HttpServletRequest requisicao, HttpServletResponse resposta, FilterChain cadeia)
            throws ServletException, IOException {
        if ("OPTIONS".equalsIgnoreCase(requisicao.getMethod())) {
            cadeia.doFilter(requisicao, resposta);
            return;
        }

        String caminho = requisicao.getRequestURI();

        if (rotaPublica(caminho)) {
            cadeia.doFilter(requisicao, resposta);
            return;
        }

        String cabecalhoAutorizacao = requisicao.getHeader("Authorization");
        if (cabecalhoAutorizacao == null || !cabecalhoAutorizacao.startsWith("Bearer ")) {
            responderNaoAutorizado(resposta, "Token ausente.");
            return;
        }

        String token = cabecalhoAutorizacao.substring("Bearer ".length());
        try {
            jwtService.extrairUsuario(token);
            cadeia.doFilter(requisicao, resposta);
        } catch (JwtException excecao) {
            responderNaoAutorizado(resposta, "Token inválido ou expirado.");
        }
    }

    private boolean rotaPublica(String caminho) {
        return caminho.equals("/auth/login") || caminho.equals("/health")
                || caminho.matches("/contas/\\d+/creditar-remoto");
    }

    private void responderNaoAutorizado(HttpServletResponse resposta, String mensagem) throws IOException {
        resposta.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
        resposta.setCharacterEncoding("UTF-8");
        resposta.setContentType("application/json");
        resposta.getWriter().write("{\"erro\":\"" + mensagem + "\"}");
    }
}

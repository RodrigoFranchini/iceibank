package br.pucminas.iceibank.agencia.controllers;

import java.util.Map;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import br.pucminas.iceibank.agencia.auth.JwtService;

@RestController
@RequestMapping("/auth")
public class AuthController {

    private static final String USUARIO_VALIDO = "admin";
    private static final String SENHA_VALIDA = "admin123";

    private final JwtService jwtService;

    public AuthController(JwtService jwtService) {
        this.jwtService = jwtService;
    }

    // Realiza login + gera token JWT
    // TOKEN=$(curl -s -X POST http://localhost:4000/auth/login -H "Content-Type: application/json" -d '{"usuario":"admin","senha":"admin123"}' | python3 -c "import json,sys;print(json.load(sys.stdin)['token'])")
    @PostMapping("/login")
    public ResponseEntity<?> login(@RequestBody Map<String, Object> corpo) {
        String usuario = (String) corpo.get("usuario");
        String senha = (String) corpo.get("senha");

        if (!USUARIO_VALIDO.equals(usuario) || !SENHA_VALIDA.equals(senha)) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(Map.of("erro", "Usuário ou senha inválidos."));
        }

        return ResponseEntity.ok(Map.of("token", jwtService.gerarToken(usuario)));
    }
}

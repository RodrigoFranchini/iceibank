// Interface gerada com uso de inteligência artificial.

import { useState, type FormEvent } from "react";
import "./App.css";

type Conta = {
  id: number;
  nomeAluno: string;
  saldo: number;
};

function lerArmazenado(chave: string): string {
  return localStorage.getItem(chave) ?? "";
}

export default function App() {
  const [agenciaUrl, setAgenciaUrl] = useState(lerArmazenado("iceibank_agenciaUrl") || "http://localhost:4000");
  const [token, setToken] = useState<string | null>(localStorage.getItem("iceibank_token"));
  const [usuario, setUsuario] = useState("");
  const [senha, setSenha] = useState("");

  const [erro, setErro] = useState<string | null>(null);
  const [mensagem, setMensagem] = useState<string | null>(null);

  const [idConsulta, setIdConsulta] = useState("");
  const [contaConsultada, setContaConsultada] = useState<Conta | null>(null);

  const [idOperacao, setIdOperacao] = useState("");
  const [valorOperacao, setValorOperacao] = useState("");

  const [idOrigem, setIdOrigem] = useState("");
  const [idDestino, setIdDestino] = useState("");
  const [valorTransferencia, setValorTransferencia] = useState("");

  function salvarAgenciaUrl(url: string) {
    setAgenciaUrl(url);
    localStorage.setItem("iceibank_agenciaUrl", url);
  }

  function salvarToken(novoToken: string | null) {
    setToken(novoToken);
    if (novoToken) {
      localStorage.setItem("iceibank_token", novoToken);
    } else {
      localStorage.removeItem("iceibank_token");
    }
  }

  async function chamarApi<T>(caminho: string, opcoes: RequestInit = {}): Promise<T> {
    const resposta = await fetch(`${agenciaUrl}${caminho}`, {
      ...opcoes,
      headers: {
        "Content-Type": "application/json",
        ...(token ? { Authorization: `Bearer ${token}` } : {}),
      },
    });
    const corpo = await resposta.json().catch(() => null);
    if (!resposta.ok) {
      if (resposta.status === 401) {
        salvarToken(null);
      }
      throw new Error(corpo?.erro ?? `Erro ${resposta.status}`);
    }
    return corpo as T;
  }

  function iniciarAcao() {
    setErro(null);
    setMensagem(null);
  }

  async function executarAcao(acao: () => Promise<void>) {
    iniciarAcao();
    try {
      await acao();
    } catch (excecao) {
      setErro(excecao instanceof Error ? excecao.message : "Erro inesperado.");
    }
  }

  async function fazerLogin(evento: FormEvent) {
    evento.preventDefault();
    await executarAcao(async () => {
      const resposta = await chamarApi<{ token: string }>("/auth/login", {
        method: "POST",
        body: JSON.stringify({ usuario, senha }),
      });
      salvarToken(resposta.token);
      setMensagem("Login realizado com sucesso.");
    });
  }

  function fazerLogout() {
    salvarToken(null);
    setContaConsultada(null);
  }

  async function consultarSaldo(evento: FormEvent) {
    evento.preventDefault();
    await executarAcao(async () => {
      const conta = await chamarApi<Conta>(`/contas/${idConsulta}`);
      setContaConsultada(conta);
    });
  }

  async function depositar() {
    await executarAcao(async () => {
      const conta = await chamarApi<Conta>(`/contas/${idOperacao}/depositar`, {
        method: "POST",
        body: JSON.stringify({ valor: Number(valorOperacao) }),
      });
      setMensagem(`Depósito realizado. Novo saldo: ${conta.saldo}`);
    });
  }

  async function sacar() {
    await executarAcao(async () => {
      const conta = await chamarApi<Conta>(`/contas/${idOperacao}/sacar`, {
        method: "POST",
        body: JSON.stringify({ valor: Number(valorOperacao) }),
      });
      setMensagem(`Saque realizado. Novo saldo: ${conta.saldo}`);
    });
  }

  async function transferir(evento: FormEvent) {
    evento.preventDefault();
    await executarAcao(async () => {
      const resposta = await chamarApi<{ mensagem: string }>("/transferencias", {
        method: "POST",
        body: JSON.stringify({
          idOrigem: Number(idOrigem),
          idDestino: Number(idDestino),
          valor: Number(valorTransferencia),
        }),
      });
      setMensagem(resposta.mensagem);
    });
  }

  return (
    <div className="pagina">
      <h1>ICEIBank</h1>

      <div className="secao">
        <label>Agência (URL base)</label>
        <div className="linha">
          <input value={agenciaUrl} onChange={(evento) => salvarAgenciaUrl(evento.target.value)} />
        </div>
      </div>

      {erro && <p className="mensagemErro">{erro}</p>}
      {mensagem && <p className="mensagemSucesso">{mensagem}</p>}

      {!token ? (
        <form className="secao" onSubmit={fazerLogin}>
          <h2>Login</h2>
          <div className="linha">
            <input placeholder="usuário" value={usuario} onChange={(evento) => setUsuario(evento.target.value)} />
          </div>
          <div className="linha">
            <input
              type="password"
              placeholder="senha"
              value={senha}
              onChange={(evento) => setSenha(evento.target.value)}
            />
          </div>
          <button type="submit">Entrar</button>
        </form>
      ) : (
        <div className="secao">
          <button onClick={fazerLogout}>Sair</button>
        </div>
      )}

      {token && (
        <>
          <form className="secao" onSubmit={consultarSaldo}>
            <h2>Consultar saldo</h2>
            <div className="linha">
              <input
                placeholder="id da conta"
                value={idConsulta}
                onChange={(evento) => setIdConsulta(evento.target.value)}
              />
              <button type="submit">Consultar</button>
            </div>
            {contaConsultada && (
              <p className="contaAtual">
                #{contaConsultada.id} {contaConsultada.nomeAluno} — saldo: {contaConsultada.saldo}
              </p>
            )}
          </form>

          <div className="secao">
            <h2>Depósito / saque</h2>
            <div className="linha">
              <input
                placeholder="id da conta"
                value={idOperacao}
                onChange={(evento) => setIdOperacao(evento.target.value)}
              />
              <input
                placeholder="valor"
                value={valorOperacao}
                onChange={(evento) => setValorOperacao(evento.target.value)}
              />
            </div>
            <div className="linha">
              <button onClick={depositar}>Depositar</button>
              <button onClick={sacar}>Sacar</button>
            </div>
          </div>

          <form className="secao" onSubmit={transferir}>
            <h2>Transferência</h2>
            <div className="linha">
              <input
                placeholder="conta origem"
                value={idOrigem}
                onChange={(evento) => setIdOrigem(evento.target.value)}
              />
              <input
                placeholder="conta destino"
                value={idDestino}
                onChange={(evento) => setIdDestino(evento.target.value)}
              />
            </div>
            <div className="linha">
              <input
                placeholder="valor"
                value={valorTransferencia}
                onChange={(evento) => setValorTransferencia(evento.target.value)}
              />
              <button type="submit">Transferir</button>
            </div>
          </form>
        </>
      )}
    </div>
  );
}

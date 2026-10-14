#!/usr/bin/env python3
"""Site de login do RISE (aula 2).

Um servidor web inteiro em um arquivo só, usando apenas o que já vem com o
Python. Ele funciona, e é assim que muito site de verdade começa. Leia com
calma: a aula é sobre o que há de errado aqui.
"""

import html
import os
import sqlite3
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import parse_qs, urlparse

BANCO = os.environ.get("BANCO", "/dados/usuarios.db")
PORTA = int(os.environ.get("PORTA", "80"))
# Como o formulário envia os dados: "get" (na URL) ou "post" (no corpo do pedido)
METODO = os.environ.get("METODO", "get").lower()

SEGREDO = "RISE{quem_le_o_banco_le_a_senha}"

PAGINA = """<!doctype html>
<html lang="pt-BR">
<head>
  <meta charset="utf-8">
  <title>RISE Login</title>
  <style>
    body {{ background: #111; color: #eee; font-family: monospace; padding: 3rem; }}
    h1 {{ color: #e95420; }}
    a {{ color: #e95420; }}
    input {{ font: inherit; padding: .3rem; margin: .2rem 0; }}
  </style>
</head>
<body>
  <h1>{titulo}</h1>
  {corpo}
</body>
</html>
"""

FORMULARIO = """<form action="{acao}" method="{metodo}">
  <p>Usuário<br><input name="usuario" autofocus></p>
  <p>Senha<br><input name="senha" type="password"></p>
  <p><input type="submit" value="{botao}"></p>
</form>
"""


def abrir_banco():
    """Abre o arquivo do banco e, se ele for novo, cria a tabela de usuários."""
    banco = sqlite3.connect(BANCO)
    banco.execute("CREATE TABLE IF NOT EXISTS usuarios (nome TEXT PRIMARY KEY, senha TEXT)")
    # Quem já usava o site antes de você chegar
    banco.executemany(
        "INSERT OR IGNORE INTO usuarios (nome, senha) VALUES (?, ?)",
        [
            ("admin", "cafe-com-leite-42"),
            ("ana", "123456"),
            ("bruno", "bruno2008"),
        ],
    )
    banco.commit()
    return banco


def cadastrar(nome, senha):
    """Guarda um usuário novo. Devolve False se o nome já existir."""
    banco = abrir_banco()
    try:
        banco.execute("INSERT INTO usuarios (nome, senha) VALUES (?, ?)", (nome, senha))
        banco.commit()
        return True
    except sqlite3.IntegrityError:
        return False
    finally:
        banco.close()


def senha_confere(nome, senha):
    """Compara a senha digitada com a que está guardada no banco."""
    banco = abrir_banco()
    linha = banco.execute("SELECT senha FROM usuarios WHERE nome = ?", (nome,)).fetchone()
    banco.close()
    return linha is not None and linha[0] == senha


class Site(BaseHTTPRequestHandler):
    def do_GET(self):
        # Em um GET, os campos do formulário chegam na própria URL, depois do "?"
        url = urlparse(self.path)
        self.responder(url.path, parse_qs(url.query))

    def do_POST(self):
        # Em um POST, os campos chegam no corpo do pedido, depois dos cabeçalhos
        tamanho = int(self.headers.get("Content-Length", 0))
        corpo = self.rfile.read(tamanho).decode()
        self.responder(urlparse(self.path).path, parse_qs(corpo))

    def responder(self, caminho, campos):
        usuario = campos.get("usuario", [""])[0]
        senha = campos.get("senha", [""])[0]

        if caminho == "/":
            self.pagina(
                200,
                "Entrar",
                FORMULARIO.format(acao="/login", metodo=METODO, botao="Entrar")
                + '<p>Ainda não tem conta? <a href="/cadastro">Cadastre-se</a>.</p>',
            )
        elif caminho == "/cadastro":
            self.pagina(
                200,
                "Criar conta",
                FORMULARIO.format(acao="/cadastrar", metodo=METODO, botao="Criar conta")
                + '<p><a href="/">Voltar</a></p>',
            )
        elif caminho == "/cadastrar":
            if not usuario or not senha:
                self.pagina(400, "Faltou algo", '<p>Preencha usuário e senha. <a href="/cadastro">Voltar</a></p>')
            elif cadastrar(usuario, senha):
                self.pagina(200, "Conta criada", '<p>Agora <a href="/">entre com ela</a>.</p>')
            else:
                self.pagina(409, "Nome já usado", '<p>Escolha outro. <a href="/cadastro">Voltar</a></p>')
        elif caminho == "/login":
            if senha_confere(usuario, senha):
                if usuario == "admin":
                    corpo = f"<p>O segredo deste site: <b>{SEGREDO}</b></p>"
                else:
                    corpo = "<p>Você entrou. Só o <b>admin</b> vê o segredo deste site.</p>"
                self.pagina(200, f"Olá, {html.escape(usuario)}", corpo + '<p><a href="/">Sair</a></p>')
            else:
                self.pagina(401, "Acesso negado", '<p>Usuário ou senha incorretos. <a href="/">Voltar</a></p>')
        else:
            self.pagina(404, "Não existe", '<p><a href="/">Voltar</a></p>')

    def pagina(self, codigo, titulo, corpo):
        conteudo = PAGINA.format(titulo=titulo, corpo=corpo).encode()
        self.send_response(codigo)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.send_header("Content-Length", str(len(conteudo)))
        self.end_headers()
        self.wfile.write(conteudo)


if __name__ == "__main__":
    abrir_banco().close()
    print(f"Site de login no ar na porta {PORTA} (formulário via {METODO.upper()})", flush=True)
    ThreadingHTTPServer(("", PORTA), Site).serve_forever()

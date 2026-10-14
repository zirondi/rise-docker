# RISE — Aula 2: um site dentro de um container

Na aula passada os containers eram brinquedos descartáveis: você entrava, quebrava e jogava fora. Hoje eles ficam de pé e atendem pela rede. No final você vai ter um site com login rodando na sua máquina, e vai descobrir o que há de errado com ele.

A regra do prompt continua valendo:

```
[container 3f2a91c0b7de] / #      <- dentro do container
voce@lab:~$                       <- sua máquina
```

E os **dois terminais** também: **A** para os comandos principais, **B** para observar.

---

## Preparação

Se a pasta da aula passada ainda existe na sua máquina:

```bash
cd rise-docker-lab
git pull
```

Se não existe mais:

```bash
git clone https://github.com/zirondi/rise-docker.git rise-docker-lab
cd rise-docker-lab
```

Carregue as duas imagens de hoje. A primeira é a da aula passada; a segunda é nova.

```bash
podman load -i imagens/rise-lab-amd64.tar.gz
podman load -i aula2/imagens/rise-web-amd64.tar.gz
podman images
```

Devem aparecer `rise-lab` e `rise-web`.

---

## Lab 4 — Um servidor web em container

Um container que fica rodando em segundo plano (`-d`) e atende pela rede:

```bash
podman run -d --name site -p 8080:80 rise-lab httpd -f -v -h /www
```

`-p 8080:80` liga a porta 8080 **da sua máquina** à porta 80 **do container**.

Abra no navegador: <http://localhost:8080>

Depois:

```bash
podman ps            # o container está lá, com a porta mapeada
podman logs site     # cada acesso que você fez aparece aqui
```

No terminal B, deixe os logs correndo e aperte F5 no navegador algumas vezes:

```bash
podman logs -f site
```

(Ctrl+C para sair.)

Desafio: mude o texto da página **sem parar o container**. Dica:

```bash
podman exec -it site bash
```

O arquivo é `/www/index.html` (o editor `vi` está disponível; para sair dele, `Esc` e `:wq`).

Conseguiu? Agora apague o container e suba outro igual:

```bash
podman rm -f site
podman run -d --name site -p 8080:80 rise-lab httpd -f -v -h /www
```

F5 no navegador.

**Pense:** para onde foi a sua alteração? Onde você já viu isso acontecer na aula passada?

```bash
podman rm -f site
```

---

## Lab 5 — Sua primeira imagem

Mexer dentro do container não dura. Para a mudança durar, ela tem que estar na **receita**.

```bash
cd aula2/meu-site
cat Containerfile
```

São três instruções: parte da imagem `rise-lab`, copia um `index.html` por cima do original e define o que roda quando o container sobe.

Abra o `index.html` desta pasta no editor de texto e troque o título pelo seu nome. Salve. Depois construa a imagem (o ponto no final faz parte do comando: é "a pasta atual"):

```bash
podman build -t meu-site .
podman images
```

Suba um container a partir dela. Repare que não precisa mais dizer `httpd ...` no final: a receita já sabe o que rodar.

```bash
podman run -d --name site -p 8080:80 meu-site
```

F5 em <http://localhost:8080>. Agora o teste que importa:

```bash
podman rm -f site
podman run -d --name site -p 8080:80 meu-site
```

F5 de novo.

**Pense:** desta vez a página sobreviveu. O que mudou em relação ao Lab 4?

```bash
podman rm -f site
cd ../..
```

---

## Lab 6 — Um site com login

A imagem `rise-web` traz um site de verdade, pequeno: cadastro, login e um banco de dados. Suba em outra porta:

```bash
podman run -d --name login -p 8081:80 rise-web
```

Abra <http://localhost:8081>.

1. Clique em **Cadastre-se** e crie uma conta. **Invente uma senha só para esta aula: não use nenhuma senha sua de verdade.**
2. Volte e entre com ela.
3. Tente entrar com a senha errada.

O site inteiro é um arquivo de 150 linhas. Dê uma olhada:

```bash
less aula2/app/site.py
```

(`q` para sair.) Não precisa entender tudo. Procure só duas coisas: onde a senha é **guardada** e onde ela é **comparada**.

**Pense:** só o usuário `admin` vê o segredo do site. Você não sabe a senha dele. Guarde essa informação.

---

## Lab 7 — Onde a sua senha foi parar (parte 1)

Entre de novo com a sua conta e, antes de qualquer outra coisa, **olhe a barra de endereço do navegador**.

Agora abra o histórico do navegador (Ctrl+H).

E no terminal B:

```bash
podman logs login
```

**Pense:** em quantos lugares diferentes a sua senha ficou escrita? Quem mais, além de você, consegue ler cada um deles?

O navegador não faz mágica: ele manda um texto para o servidor e recebe outro de volta. Dá para fazer o mesmo pedido na mão (troque `SEU_USUARIO` e `SUA_SENHA`):

```bash
curl -v 'http://localhost:8081/login?usuario=SEU_USUARIO&senha=SUA_SENHA'
```

As linhas que começam com `>` são o que foi **enviado**. As que começam com `<` são o que **voltou**.

**Pense:** ache a sua senha no que foi enviado. Esse texto saiu do `curl`, atravessou a rede e chegou no container. Em que formato ele viajou?

---

## Lab 8 — Onde a sua senha foi parar (parte 2)

O site guarda os usuários num arquivo dentro do container: `/dados/usuarios.db`. Abra o arquivo com o programa que lê esse tipo de banco:

```bash
podman exec -it login sqlite3 -header -column /dados/usuarios.db 'SELECT * FROM usuarios'
```

Você não digitou senha nenhuma para ver isso.

**Desafio:** entre no site como `admin` e pegue o segredo.

Na vida real ninguém precisa nem entrar no servidor: basta o arquivo vazar. Copie o banco para fora do container, como alguém que achou um backup esquecido:

```bash
podman cp login:/dados/usuarios.db /tmp/vazou.db
grep -a -o 'cafe[a-z0-9-]*' /tmp/vazou.db
```

**Pense:** se este fosse um site com 10 mil usuários, o que a pessoa que pegou esse arquivo teria em mãos? E se metade desses usuários usa a mesma senha no e-mail?

### O banco também é descartável

```bash
podman rm -f login
podman run -d --name login -p 8081:80 rise-web
```

Tente entrar com a sua conta.

A conta sumiu junto com o container, como a página do Lab 4. Um site de verdade não pode perder os usuários a cada reinício: o banco precisa morar fora do container. É a "porta" (`-v`) da aula passada, agora usada de propósito:

```bash
podman rm -f login
podman run -d --name login -p 8081:80 -v dados-login:/dados rise-web
```

Crie a conta de novo, apague o container e suba outro com o mesmo comando acima. A conta continua lá.

```bash
podman volume ls
```

**Pense:** o banco agora sobrevive ao container. As senhas dentro dele também.

Ao terminar:

```bash
podman rm -f login
podman volume rm dados-login
rm /tmp/vazou.db
```

---

## Exemplo final — o mesmo site com POST

O site aceita uma opção que troca a forma como o formulário envia os dados: em vez de irem na URL (GET), eles vão no corpo do pedido (POST).

```bash
podman run -d --name login -p 8081:80 -e METODO=post rise-web
```

Entre com `ana` e a senha `123456` e olhe de novo os três lugares do Lab 7:

```bash
podman logs login
# -> "POST /login HTTP/1.1" 200 -
```

A senha sumiu da barra de endereço, do histórico e do log. O pedido feito na mão fica assim:

```bash
curl -v -d 'usuario=ana&senha=123456' http://localhost:8081/login
```

**Pense:** a senha saiu da primeira linha do pedido. Ela deixou de ser enviada? E no banco, mudou alguma coisa?

```bash
podman rm -f login
```

Para rodar em casa, construa a imagem em vez de carregar o arquivo (funciona em qualquer computador, inclusive Mac com chip Apple): `cd aula2 && podman build -t rise-web .`

---

## Cola de comandos

| Comando | O que faz |
|---|---|
| `podman run -d --name NOME -p 8080:80 IMAGEM` | Sobe um container em segundo plano com uma porta ligada à sua máquina |
| `podman logs NOME` / `podman logs -f NOME` | Mostra o que o container imprimiu / fica acompanhando |
| `podman exec -it NOME bash` | Abre um shell dentro de um container que já está rodando |
| `podman exec NOME COMANDO` | Roda um comando só, lá dentro |
| `podman build -t NOME .` | Constrói uma imagem a partir do `Containerfile` da pasta atual |
| `podman cp NOME:/caminho DESTINO` | Copia um arquivo de dentro do container para a sua máquina |
| `podman run -v VOLUME:/pasta ...` | Guarda `/pasta` num volume, que sobrevive ao container |
| `podman volume ls` / `podman volume rm VOLUME` | Lista / apaga volumes |
| `podman rm -f NOME` | Para e apaga um container de uma vez |
| `curl -v URL` | Faz um pedido web pelo terminal e mostra o que foi enviado e recebido |

# RISE — Aula 2: um site dentro de um container

Na aula passada os containers eram brinquedos descartáveis: você entrava, quebrava e jogava fora. Hoje eles ficam de pé e atendem pela rede. No final você vai ter um site com login rodando na sua máquina, e vai descobrir o que há de errado com ele.

A regra do prompt continua valendo:

```
[container 3f2a91c0b7de] / #      <- dentro do container
voce@lab:~$                       <- sua máquina
```

E os **dois terminais** também: **A** para os comandos principais, **B** para observar.

## Hoje os comandos estão em scripts

Cada passo da aula é um script nesta pasta. Rode `ls` e veja: os números são os números dos Labs. Todo script **mostra em amarelo o comando que está rodando** antes de rodá-lo. Leia essa linha: é ela que você vai digitar quando não tiver script nenhum.

Os scripts que sobem um container apagam antes o container antigo de mesmo nome. Então "apague o container e suba outro igual" é só rodar o mesmo script de novo.

Se aparecer `Permission denied`, rode com `bash` na frente: `bash 04-site.sh`.

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

Nos **dois** terminais, entre na pasta da aula de hoje:

```bash
cd aula2
```

No terminal A, carregue as duas imagens de hoje (a da aula passada e uma nova):

```bash
./00-preparar.sh
```

No final devem aparecer `rise-lab` e `rise-web`.

---

## Lab 4 — Um servidor web em container

Um container que fica rodando em segundo plano (`-d`) e atende pela rede:

```bash
./04-site.sh
```

Repare no `-p 8080:80` do comando amarelo: ele liga a porta 8080 **da sua máquina** à porta 80 **do container**.

Abra no navegador: <http://localhost:8080>

Veja o que existe agora na sua máquina:

```bash
./estado.sh
```

No terminal B, deixe os logs correndo e aperte F5 no navegador algumas vezes:

```bash
./logs.sh site
```

(Ctrl+C para sair.)

Desafio: mude o texto da página **sem parar o container**. Dica:

```bash
./entrar.sh site
```

O arquivo é `/www/index.html` (o editor `vi` está disponível; para sair dele, `Esc` e `:wq`). Para sair do container, `exit`.

Conseguiu? Agora apague o container e suba outro igual, rodando o mesmo script de novo:

```bash
./04-site.sh
```

F5 no navegador.

**Pense:** para onde foi a sua alteração? Onde você já viu isso acontecer na aula passada?

---

## Lab 5 — Sua primeira imagem

Mexer dentro do container não dura. Para a mudança durar, ela tem que estar na **receita**: o arquivo `meu-site/Containerfile`. São três instruções: parte da imagem `rise-lab`, copia um `index.html` por cima do original e define o que roda quando o container sobe.

Abra o arquivo `meu-site/index.html` no editor de texto e troque o título pelo seu nome. Salve. Depois construa a imagem:

```bash
./05-construir.sh
```

O script mostra a receita, constrói a imagem `meu-site` e, no final, as camadas dela: a de cima é a sua.

Suba um container a partir dela. Repare que o comando amarelo não tem mais `httpd ...` no final: a receita já sabe o que rodar.

```bash
./05-meu-site.sh
```

F5 em <http://localhost:8080>. Agora o teste que importa: apague e suba de novo.

```bash
./05-meu-site.sh
```

F5 de novo.

**Pense:** desta vez a página sobreviveu. O que mudou em relação ao Lab 4?

---

## Lab 6 — Um site com login

A imagem `rise-web` traz um site de verdade, pequeno: cadastro, login e um banco de dados. Ele sobe em outra porta:

```bash
./06-login.sh
```

Abra <http://localhost:8081>.

1. Clique em **Cadastre-se** e crie uma conta. **Invente uma senha só para esta aula: não use nenhuma senha sua de verdade.**
2. Volte e entre com ela.
3. Tente entrar com a senha errada.

O site inteiro é um arquivo de 150 linhas. Dê uma olhada:

```bash
./06-codigo.sh
```

(`q` para sair.) Não precisa entender tudo. Procure só duas coisas: onde a senha é **guardada** e onde ela é **comparada**.

**Pense:** só o usuário `admin` vê o segredo do site. Você não sabe a senha dele. Guarde essa informação.

---

## Lab 7 — Onde a sua senha foi parar (parte 1)

Entre de novo com a sua conta e, antes de qualquer outra coisa, **olhe a barra de endereço do navegador**.

Agora abra o histórico do navegador (Ctrl+H).

E no terminal B:

```bash
./logs.sh login
```

**Pense:** em quantos lugares diferentes a sua senha ficou escrita? Quem mais, além de você, consegue ler cada um deles?

O navegador não faz mágica: ele manda um texto para o servidor e recebe outro de volta. Dá para fazer o mesmo pedido na mão (troque `SEU_USUARIO` e `SUA_SENHA`):

```bash
./07-curl.sh SEU_USUARIO SUA_SENHA
```

As linhas que começam com `>` são o que foi **enviado**. As que começam com `<` são o que **voltou**.

**Pense:** ache a sua senha no que foi enviado. Esse texto saiu do `curl`, atravessou a rede e chegou no container. Em que formato ele viajou?

---

## Lab 8 — Onde a sua senha foi parar (parte 2)

O site guarda os usuários num arquivo dentro do container: `/dados/usuarios.db`. Abra o arquivo com o programa que lê esse tipo de banco:

```bash
./08-banco.sh
```

Você não digitou senha nenhuma para ver isso.

**Desafio:** entre no site como `admin` e pegue o segredo.

Na vida real ninguém precisa nem entrar no servidor: basta o arquivo vazar. Copie o banco para fora do container, como alguém que achou um backup esquecido, e procure uma senha nele:

```bash
./08-vazar.sh
```

**Pense:** se este fosse um site com 10 mil usuários, o que a pessoa que pegou esse arquivo teria em mãos? E se metade desses usuários usa a mesma senha no e-mail?

### O banco também é descartável

Apague o site e suba outro:

```bash
./06-login.sh
```

Tente entrar com a sua conta.

A conta sumiu junto com o container, como a página do Lab 4. Um site de verdade não pode perder os usuários a cada reinício: o banco precisa morar fora do container. É a "porta" (`-v`) da aula passada, agora usada de propósito:

```bash
./08-login-volume.sh
```

Crie a conta de novo e rode o mesmo script outra vez (ele apaga o container e sobe outro). A conta continua lá. Veja o volume na lista:

```bash
./estado.sh
```

**Pense:** o banco agora sobrevive ao container. As senhas dentro dele também.

---

## Exemplo final — o mesmo site com POST

O site aceita uma opção que troca a forma como o formulário envia os dados: em vez de irem na URL (GET), eles vão no corpo do pedido (POST).

```bash
./09-login-post.sh
```

Entre com `ana` e a senha `123456` e olhe de novo os três lugares do Lab 7. No terminal B:

```bash
./logs.sh login
# -> "POST /login HTTP/1.1" 200 -
```

A senha sumiu da barra de endereço, do histórico e do log. O pedido feito na mão fica assim:

```bash
./09-curl-post.sh ana 123456
```

**Pense:** a senha saiu da primeira linha do pedido. Ela deixou de ser enviada? E no banco, mudou alguma coisa?

Ao terminar a aula:

```bash
./limpar.sh
```

Para rodar em casa, num computador que não é x86_64 (um Mac com chip Apple, por exemplo), o `./00-preparar.sh` constrói as imagens em vez de carregar o arquivo.

---

## Cola: o que cada script roda

| Script | Comando |
|---|---|
| `./00-preparar.sh` | `podman load -i ARQUIVO` (ou `podman build -t NOME PASTA`) e `podman images` |
| `./estado.sh` | `podman ps`, `podman images`, `podman volume ls` |
| `./logs.sh NOME` | `podman logs -f NOME`: o que o container imprimiu, acompanhando |
| `./painel.sh NOME` | `podman stats NOME`: CPU, memória e processos ao vivo |
| `./entrar.sh NOME` | `podman exec -it NOME bash`: um shell dentro de um container rodando |
| `./04-site.sh` | `podman run -d --name site -p 8080:80 rise-lab httpd -f -v -h /www` |
| `./05-construir.sh` | `podman build -t meu-site meu-site` e `podman history meu-site` |
| `./05-meu-site.sh` | `podman run -d --name site -p 8080:80 meu-site` |
| `./06-login.sh` | `podman run -d --name login -p 8081:80 rise-web` |
| `./07-curl.sh USUARIO SENHA` | `curl -v 'http://localhost:8081/login?usuario=…&senha=…'` |
| `./08-banco.sh` | `podman exec login sqlite3 … 'SELECT * FROM usuarios'` |
| `./08-vazar.sh` | `podman cp login:/dados/usuarios.db vazou.db` e `grep` |
| `./08-login-volume.sh` | `podman run … -v dados-login:/dados rise-web`: o banco num volume |
| `./09-login-post.sh` | `podman run … -e METODO=post rise-web` |
| `./09-curl-post.sh USUARIO SENHA` | `curl -v -d 'usuario=…&senha=…' http://localhost:8081/login` |
| `./limpar.sh` | `podman rm -f`, `podman volume rm`, `podman rmi meu-site` |

Antes de subir um container, todo script desses roda `podman rm -f NOME` para apagar o antigo.

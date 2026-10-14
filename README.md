# RISE — Laboratório de Containers: pode quebrar tudo

Hoje você vai rodar os comandos que todo mundo diz para nunca rodar: `rm -rf /`, uma fork bomb e um vazamento de memória. Tudo dentro de um container, que é exatamente o tipo de ambiente onde o CTF que vocês jogaram estava rodando.

**Regra de ouro:** olhe o prompt antes de dar Enter.

```
[container 3f2a91c0b7de] / #      <- dentro do container: pode destruir
voce@lab:~$                       <- sua máquina: NÃO rode os comandos destrutivos aqui
```

Você vai precisar de **dois terminais** abertos lado a lado:

- **Terminal A**: onde você entra no container e quebra as coisas.
- **Terminal B**: onde você fica do lado de fora, observando.

---

## Lab 0 — Preparação e primeiro container

No terminal A:

```bash
git clone https://github.com/zirondi/rise-docker.git rise-docker-lab
cd rise-docker-lab
podman load -i imagens/rise-lab-amd64.tar.gz
```

O `load` carrega uma **imagem** chamada `rise-lab`, que veio pronta dentro do repositório. Imagem é a receita já preparada; container é o que roda a partir dela.

Essa imagem foi produzida a partir do arquivo `Containerfile` (abra e leia, são 20 linhas) com o comando `podman build -t rise-lab .`. Em casa, ou num computador que não seja x86_64 (um Mac com chip Apple, por exemplo), é esse comando que você usa no lugar do `load`.

Agora entre num container:

```bash
podman run -it --rm rise-lab
```

O prompt mudou. Lá dentro, investigue:

```bash
whoami        # quem você é aqui dentro?
hostname      # qual o nome desta "máquina"?
ps aux        # quantos processos existem?
ls /          # parece um Linux inteiro?
```

No terminal B (fora), enquanto o container está aberto:

```bash
podman ps         # containers rodando
podman images     # imagens que você tem
```

**Pense:** sua máquina tem centenas de processos. Por que o `ps aux` lá dentro mostra só dois?

Saia com `exit`. Como você usou `--rm`, o container foi apagado ao sair.

---

## Lab 1 — `rm -rf /`

Antes de rodar, escreva num papel: **o que você acha que vai acontecer?** A sua máquina morre? O container morre? Nada acontece?

Terminal A:

```bash
podman run -it --rm rise-lab
```

Confira o prompt (`[container ...]`). Então:

```bash
rm -rf /
```

Vai passar uma enxurrada de erros `Read-only file system` vindos de `/sys` e `/proc`. Isso é normal: são partes que o kernel não deixa o container apagar. Espere terminar (ou aperte Ctrl+C depois de alguns segundos).

Agora tente:

```bash
ls            # funciona?
echo /*       # e isto? por quê?
cd / && pwd   # e isto?
```

`ls` é um programa (um arquivo em `/bin`), e você acabou de apagá-lo. `echo`, `cd` e `pwd` fazem parte do próprio shell, que já estava carregado na memória.

Saia (`exit`) e suba outro container da mesma imagem:

```bash
podman run -it --rm rise-lab
ls /
```

Tudo de volta. O container é descartável; a imagem nunca foi tocada.

### Parte 2 — e quando o container enxerga seus arquivos?

Saia do container. No terminal A, **fora** do container, crie uma pasta descartável com dois arquivos falsos:

```bash
PASTA=$(mktemp -d)
touch "$PASTA/trabalho-de-calculo.txt" "$PASTA/fotos.zip"
ls "$PASTA"
```

Suba um container que enxerga essa pasta em `/dados`:

```bash
podman run -it --rm -v "$PASTA":/dados:Z rise-lab
```

> Confira o comando acima antes do Enter. O que vem antes dos dois-pontos em `-v` é uma pasta **da sua máquina**. Use somente `"$PASTA"`.
>
> O `:Z` no final é exigência do SELinux, a camada de segurança das máquinas do lab: sem ele o container nem consegue ler a pasta.

Dentro do container:

```bash
ls /dados
rm -rf /
exit
```

De volta à sua máquina:

```bash
ls -la "$PASTA"
```

**Pense:** o que sobrou? O que isso diz sobre montar a sua pasta pessoal dentro de um container que roda código de outra pessoa?

---

## Lab 2 — Fork bomb

Uma fork bomb é um processo que cria cópias de si mesmo sem parar:

```bash
:(){ :|:& };:
```

Lendo devagar: define uma função chamada `:` que chama a si mesma duas vezes em background, e depois a executa. Uma vira duas, duas viram quatro, e assim por diante.

Terminal A — um container com no máximo 50 processos:

```bash
podman run -it --rm --name bomba --pids-limit 50 rise-lab
```

Terminal B — o painel de observação:

```bash
podman stats bomba
```

Terminal A, dentro do container:

```bash
fork_bomb
```

(ou digite a bomba na mão)

Observe no terminal B a coluna **PIDS**. No terminal A vão aparecer mensagens `fork: Resource temporarily unavailable`.

**Pense:** em que número a coluna PIDS parou? Sua máquina ficou lenta? Você ainda consegue abrir um programa nela?

Para desarmar, no terminal B aperte Ctrl+C para sair do `stats` e:

```bash
podman kill bomba
```

---

## Lab 3 — Vazamento de memória

O programa `mem_leak` é C puro: um laço infinito de `malloc()` de 5 MB que nunca dá `free()`. O código está em `scripts/mem_leak.c`.

Terminal A — um container com no máximo 64 MB de RAM:

```bash
podman run -it --rm --name vazamento --memory 64m --memory-swap 64m rise-lab
```

Terminal B:

```bash
podman stats vazamento
```

Terminal A, dentro do container:

```bash
mem_leak
```

Aperte Enter e acompanhe a contagem no terminal A e a coluna **MEM USAGE / LIMIT** no terminal B.

Quando o programa morrer, ainda dentro do container:

```bash
echo $?
```

O número é **137 = 128 + 9**. O 9 é o sinal `SIGKILL`: quem matou o processo foi o kernel do Linux (o "OOM Killer", de *Out Of Memory*), sem pedir licença.

**Pense:** o programa morreu, mas você ainda está dentro do container. Quem decidiu o que morria? Em quantos MB ele morreu, e por que não foi exatamente em 64?

Saia com `exit`.

---

## Lab 4 — Um servidor web em container

Até aqui os containers eram descartáveis e interativos. Agora um que fica rodando em segundo plano (`-d`) e atende pela rede:

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

Desafio: mude o texto da página **sem parar o container**. Dica:

```bash
podman exec -it site bash
```

O arquivo é `/www/index.html` (o editor `vi` está disponível; para sair dele, `Esc` e `:wq`).

Ao terminar:

```bash
podman stop site
podman rm site
```

**Pense:** o texto que você mandou do navegador até o container passou pela rede. Alguém no meio do caminho conseguiria ler? Esse é o assunto das próximas aulas.

---

## Grand finale (opcional) — sem jaula

Só no final da aula, e só se o professor liberar. **Salve tudo o que estiver aberto: sua máquina pode travar e precisar ser reiniciada.**

Os mesmos experimentos, agora sem os limites:

```bash
# Fork bomb sem limite de processos
podman run -it --rm --name bomba --pids-limit=-1 rise-lab
fork_bomb
```

```bash
# Vazamento sem limite de memória
podman run -it --rm --name vazamento rise-lab
mem_leak
```

**Pense:** qual a diferença entre um container com limites e um sem? De quem é a responsabilidade de colocar os limites?

---

## Cola de comandos

| Comando | O que faz |
|---|---|
| `podman load -i ARQUIVO` | Carrega uma imagem pronta a partir de um arquivo |
| `podman build -t NOME .` | Constrói uma imagem a partir do `Containerfile` da pasta atual |
| `podman images` | Lista as imagens |
| `podman run -it --rm IMAGEM` | Sobe um container interativo e o apaga ao sair |
| `podman run -d --name NOME IMAGEM` | Sobe um container em segundo plano |
| `podman ps` / `podman ps -a` | Containers rodando / todos, inclusive os parados |
| `podman exec -it NOME bash` | Abre um shell dentro de um container que já está rodando |
| `podman logs NOME` | Mostra o que o container imprimiu |
| `podman stats NOME` | Uso de CPU, memória e processos ao vivo |
| `podman stop NOME` / `podman kill NOME` | Para com educação / mata na hora |
| `podman rm NOME` | Apaga um container parado |

Opções do `run` usadas hoje: `--memory 64m` (limite de RAM), `--pids-limit 50` (limite de processos), `-p 8080:80` (porta), `-v PASTA:/dados:Z` (pasta do host dentro do container).

Onde você ler `podman`, pode ler `docker`: os comandos são os mesmos.

---

## Desafio de casa

Para fazer no seu computador: as máquinas do lab não têm o `compose` instalado. Instale o Podman (ou o Docker) e o `podman-compose` (ou use `docker compose`).

1. Abra o `compose.yml` desta pasta. Ele descreve **dois** containers que conversam entre si.
2. Suba com `podman compose up -d` e acompanhe com `podman compose logs -f`.
3. Responda: como o container `visitante` encontra o `site`, se ninguém passou um endereço IP para ele?
4. Compare com o [`compose.yml` do CTF](../rise-ctf-linux/compose.yml) que vocês jogaram. Ache nele o limite de memória e o limite de processos. Agora você sabe por que eles estão lá.

---

## Aula 2

A continuação está em [`aula2/README.md`](aula2/README.md): o servidor web do Lab 4, a sua primeira imagem e um site com login.

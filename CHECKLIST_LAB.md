# Checklist de validação do laboratório

Para rodar numa máquina do lab da UNESP, **logado com uma conta de aluno**, alguns dias antes da aula. Tudo aqui já passou no Mac do professor, mas o Mac roda o podman dentro de uma VM em modo rootful: ele não reproduz home em NFS, subuid, SELinux nem a delegação de cgroups do lab.

## 1. Checagem automática

```bash
git clone https://github.com/zirondi/rise-docker.git rise-docker-lab
cd rise-docker-lab
./checar-lab.sh
```

O script testa, na ordem: podman instalado, cgroups v2 com `memory` e `pids` delegados, subuid/subgid, filesystem e espaço do home, carga da imagem do lab a partir de `imagens/rise-lab-amd64.tar.gz`, pull pela rede (só aviso), limite de memória (espera exit 137), limite de processos, porta 8080, volume com pasta do host, e extras (git, compose, tmux).

A rede do lab trava em `podman pull` de forma intermitente (Docker Hub e ECR). Por isso a imagem `rise-lab` para x86_64 vai pronta dentro do repositório e os alunos só fazem `podman load`: a aula não baixa nenhuma imagem.

## 2. O que fazer em cada falha

| Item | Sintoma | Saída |
|---|---|---|
| 2 | cgroups v1, ou `memory`/`pids` fora da lista de controllers | Precisa do admin do lab (ver abaixo). Sem isso, os Labs 2 e 3 viram demonstração no telão |
| 3 | Sem entrada em `/etc/subuid` e o pull falha com `insufficient UIDs or GIDs` | Plano B "sem subuid" |
| 4 | Home em NFS e erros de storage no pull/build | Plano B "storage fora do home" |
| 5 | `podman load` falha | Conferir se o `git clone` trouxe `imagens/rise-lab-amd64.tar.gz` inteiro (4,3 MB) |
| 6 | Pull não completa (aviso) | Esperado nesta rede; nada a fazer, a aula não usa pull |
| 9 | Porta 8080 ocupada | Trocar para `-p 8081:80` no guia |
| 10 | Só funciona com `:Z` | Trocar o comando do Lab 1 parte 2 no `README.md` para `-v "$PASTA":/dados:Z` |

### Pedir ao admin: delegação de cgroups

Em distros com systemd, a delegação ao usuário é configurada assim (como root):

```bash
mkdir -p /etc/systemd/system/user@.service.d
cat > /etc/systemd/system/user@.service.d/delegate.conf <<'EOF'
[Service]
Delegate=cpu cpuset io memory pids
EOF
systemctl daemon-reload
```

Vale a partir do próximo login do usuário.

### Plano B: storage fora do home (NFS)

Cada aluno roda uma vez:

```bash
mkdir -p ~/.config/containers
cat > ~/.config/containers/storage.conf <<EOF
[storage]
driver = "overlay"
graphroot = "/tmp/$USER-containers"
runroot = "/tmp/$USER-containers-run"
EOF
```

As imagens passam a morar em `/tmp` (somem no reboot, o que é aceitável para a aula).

### Plano B: sem subuid

Acrescentar ao mesmo `storage.conf`:

```toml
[storage.options.overlay]
ignore_chown_errors = "true"
```

### Regerar a imagem do repositório

Se o `Containerfile`, os scripts ou a página mudarem, a imagem precisa ser refeita. No Mac do professor (ARM), construindo para x86_64:

```bash
podman build --platform linux/amd64 -t rise-lab-amd64 .
podman machine ssh "sudo skopeo copy containers-storage:localhost/rise-lab-amd64:latest docker-archive:$PWD/imagens/rise-lab-amd64.tar:localhost/rise-lab:latest"
gzip -9 -f imagens/rise-lab-amd64.tar
```

Numa máquina x86_64 é mais simples: `podman build -t rise-lab . && podman save rise-lab | gzip -9 > imagens/rise-lab-amd64.tar.gz`.

### Se o `git clone` também travar

Leve a pasta `rise-docker-lab` num pendrive ou numa pasta compartilhada: ela tem poucos MB e já contém a imagem.

## 3. Checagem manual (o script não cobre)

- [ ] Seguir o `README.md` do início ao fim como se fosse um aluno, com dois terminais.
- [ ] Abrir <http://localhost:8080> no navegador do lab durante o Lab 4.
- [ ] **Grand finale sem limite**: rodar os dois comandos numa máquina do lab e anotar o que acontece de verdade e como recuperar. Isso **não foi testado**: não rodei a versão sem limite em lugar nenhum. A expectativa é a sessão do aluno travar (fork bomb) e a máquina entrar em swap (memory leak), com logout ou reboot como saída, mas depende dos limites que o lab já impõe por usuário.
- [ ] Conferir se os alunos conseguem reiniciar a máquina sozinhos caso ela trave.
- [ ] As imagens persistem entre logins? Se o home for zerado a cada sessão, o `podman load` é refeito no dia (leva segundos).
- [ ] `git clone` do GitHub funciona a partir do lab? A rede de lá é instável para registries; confirme para o GitHub.

## 4. Abertura com o CTF (máquina do professor)

O `rise-ctf-linux/compose.yml` não sobe sozinho fora do servidor: ele monta `/etc/timezone` (que não existe no macOS nem em toda distro) e só expõe o Wetty via Traefik. O arquivo `demo-ctf.override.yml` resolve os dois pontos sem alterar o repo do CTF:

```bash
cd ../rise-ctf-linux
podman network create edge-network      # só se ainda não existir
podman compose -f compose.yml -f ../rise-docker-lab/demo-ctf.override.yml up -d
podman compose -f compose.yml -f ../rise-docker-lab/demo-ctf.override.yml down
```

Testado no Mac: os dois containers sobem e `http://localhost:3000` responde HTTP 200. O login pelo navegador não foi conferido visualmente; faça isso uma vez antes da aula.

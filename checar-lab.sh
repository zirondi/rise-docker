#!/usr/bin/env bash
# Valida se uma máquina está pronta para a aula de containers do RISE.
# Rode com uma conta de ALUNO, dentro da pasta rise-docker-lab:
#
#   ./checar-lab.sh
#
# Cada item imprime OK, AVISO ou FALHOU. Veja CHECKLIST_LAB.md para o que
# fazer em cada falha.

cd "$(dirname "${BASH_SOURCE[0]}")" || exit 1

IMG=rise-lab
BASE=public.ecr.aws/docker/library/alpine:3.21
FALHAS=0
AVISOS=0

ok()     { printf '  \033[32mOK\033[0m      %s\n' "$1"; }
aviso()  { printf '  \033[33mAVISO\033[0m   %s\n' "$1"; AVISOS=$((AVISOS + 1)); }
falhou() { printf '  \033[31mFALHOU\033[0m  %s\n' "$1"; FALHAS=$((FALHAS + 1)); }
titulo() { printf '\n[%s] %s\n' "$1" "$2"; }

titulo 1 "Podman instalado"
if ! command -v podman > /dev/null; then
    falhou "podman não encontrado no PATH"
    exit 1
fi
ok "$(podman --version)"

titulo 2 "Modo de execução e cgroups"
ROOTLESS=$(podman info --format '{{.Host.Security.Rootless}}' 2> /dev/null)
CGV=$(podman info --format '{{.Host.CgroupsVersion}}' 2> /dev/null)
CTRL=$(podman info --format '{{.Host.CgroupControllers}}' 2> /dev/null)
DRIVER=$(podman info --format '{{.Store.GraphDriverName}}' 2> /dev/null)
GRAPH=$(podman info --format '{{.Store.GraphRoot}}' 2> /dev/null)
echo "  rootless=$ROOTLESS  cgroups=$CGV  controllers=$CTRL  storage=$DRIVER"
echo "  graphroot=$GRAPH"
if [ -z "$CGV" ]; then
    falhou "'podman info' não respondeu (veja o erro com: podman info)"
elif [ "$CGV" != "v2" ]; then
    falhou "cgroups $CGV: --memory e --pids-limit não funcionam em rootless"
else
    ok "cgroups v2"
    case "$CTRL" in *memory*) ok "controller 'memory' disponível" ;; *) falhou "controller 'memory' não delegado ao usuário" ;; esac
    case "$CTRL" in *pids*) ok "controller 'pids' disponível" ;; *) falhou "controller 'pids' não delegado ao usuário" ;; esac
fi

titulo 3 "subuid / subgid do usuário $USER"
if [ "$ROOTLESS" = "true" ]; then
    if grep -q "^$USER:" /etc/subuid 2> /dev/null && grep -q "^$USER:" /etc/subgid 2> /dev/null; then
        ok "entradas encontradas em /etc/subuid e /etc/subgid"
    else
        aviso "sem entrada em /etc/subuid ou /etc/subgid (o pull pode falhar; ver plano B)"
    fi
else
    ok "não se aplica (podman não está em modo rootless aqui)"
fi

titulo 4 "Sistema de arquivos do home"
FSTYPE=$(stat -f -c %T "$HOME" 2> /dev/null || df -PT "$HOME" 2> /dev/null | awk 'NR==2 {print $2}')
case "$FSTYPE" in
    nfs* | cifs* | smb* | afs* | lustre*) aviso "home em '$FSTYPE': storage rootless costuma falhar (ver plano B)" ;;
    "") aviso "não consegui detectar o tipo de filesystem do home" ;;
    *) ok "home em '$FSTYPE'" ;;
esac
LIVRE=$(df -Pk "$HOME" | awk 'NR==2 {print int($4 / 1024)}')
if [ "${LIVRE:-0}" -lt 500 ]; then
    aviso "apenas ${LIVRE} MB livres no home (o lab usa ~100 MB)"
else
    ok "${LIVRE} MB livres no home"
fi

titulo 5 "Imagem do lab"
TAR=imagens/rise-lab-amd64.tar.gz
if [ "$(uname -m)" = "x86_64" ] && [ -f "$TAR" ]; then
    # Caminho dos alunos: carrega a imagem pronta, sem usar a rede
    if podman load -q -i "$TAR" > /dev/null 2> /tmp/checar-lab.err; then
        ok "imagem carregada de $TAR (sem rede)"
    else
        falhou "podman load falhou: $(tail -1 /tmp/checar-lab.err)"
    fi
else
    # Outra arquitetura (ex.: Mac ARM): precisa construir
    T0=$SECONDS
    if podman build -q -t "$IMG" . > /dev/null 2> /tmp/checar-lab.err; then
        ok "arquitetura $(uname -m): imagem construída em $((SECONDS - T0))s"
    else
        falhou "build falhou: $(tail -1 /tmp/checar-lab.err)"
    fi
fi
if ! podman image exists "$IMG"; then
    echo
    echo "Sem a imagem não dá para testar o resto. Falhas: $FALHAS"
    exit 1
fi

titulo 6 "Pull pela rede (opcional: a aula não depende disso)"
LIMITE=""
command -v timeout > /dev/null && LIMITE="timeout 45"
T0=$SECONDS
if $LIMITE podman pull -q "$BASE" > /dev/null 2> /tmp/checar-lab.err; then
    ok "pull de $BASE em $((SECONDS - T0))s"
else
    aviso "pull não completou em 45s: nesta rede, use só a imagem do repositório"
fi

titulo 7 "Limite de memória (Lab 3)"
podman run --rm --memory 64m --memory-swap 64m "$IMG" \
    bash -c 'echo | mem_leak > /dev/null; exit ${PIPESTATUS[1]}' 2> /tmp/checar-lab.err
RC=$?
if [ $RC -eq 137 ]; then
    ok "mem_leak morto pelo kernel com exit code 137"
else
    falhou "esperava exit code 137, veio $RC: $(tail -1 /tmp/checar-lab.err)"
fi

titulo 8 "Limite de processos (Lab 2)"
NEGADOS=$(podman run --rm --pids-limit 20 "$IMG" \
    bash -c 'for i in $(seq 40); do sleep 3 & done; wait' 2>&1 | grep -c 'Resource temporarily unavailable')
if [ "${NEGADOS:-0}" -gt 0 ]; then
    ok "--pids-limit aplicado ($NEGADOS forks negados)"
else
    falhou "--pids-limit 20 não segurou 40 processos"
fi

titulo 9 "Porta 8080 e servidor web (Lab 4)"
podman rm -f checar-lab-site > /dev/null 2>&1
if podman run -d --name checar-lab-site -p 8080:80 "$IMG" httpd -f -h /www > /dev/null 2> /tmp/checar-lab.err; then
    sleep 1
    if (curl -s localhost:8080 || wget -qO- localhost:8080) 2> /dev/null | grep -q RISE; then
        ok "site respondeu em http://localhost:8080"
    else
        falhou "container subiu mas http://localhost:8080 não respondeu"
    fi
else
    falhou "não subiu com -p 8080:80: $(tail -1 /tmp/checar-lab.err)"
fi
podman rm -f checar-lab-site > /dev/null 2>&1

titulo 10 "Volume com pasta do host (Lab 1, parte 2)"
PASTA=$(mktemp -d)
touch "$PASTA/arquivo.txt"
if podman run --rm -v "$PASTA":/dados "$IMG" rm /dados/arquivo.txt 2> /dev/null && [ ! -e "$PASTA/arquivo.txt" ]; then
    ok "container apagou arquivo do host via -v"
elif podman run --rm -v "$PASTA":/dados:Z "$IMG" rm /dados/arquivo.txt 2> /dev/null && [ ! -e "$PASTA/arquivo.txt" ]; then
    aviso "volume só funciona com o sufixo :Z (SELinux); use -v PASTA:/dados:Z no guia"
else
    falhou "container não conseguiu apagar arquivo em volume montado"
fi
rm -rf "$PASTA"

titulo 11 "Extras"
command -v git > /dev/null && ok "git instalado" || aviso "git não encontrado (alunos não conseguem clonar o repo)"
podman compose version > /dev/null 2>&1 && ok "podman compose disponível" || aviso "podman compose indisponível (só afeta o desafio de casa)"
command -v tmux > /dev/null && ok "tmux instalado" || aviso "sem tmux (alunos usam duas janelas de terminal)"

rm -f /tmp/checar-lab.err
echo
if [ $FALHAS -eq 0 ]; then
    printf '\033[32mPronto para a aula.\033[0m Avisos: %s\n' "$AVISOS"
else
    printf '\033[31m%s item(ns) falharam.\033[0m Avisos: %s. Veja CHECKLIST_LAB.md.\n' "$FALHAS" "$AVISOS"
fi
exit $FALHAS

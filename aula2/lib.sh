# Funções usadas por todos os scripts desta pasta. Não precisa rodar este
# arquivo: cada script o carrega sozinho.

# Os scripts sempre trabalham a partir da pasta aula2/
cd "$(dirname "${BASH_SOURCE[0]}")" || exit 1

# Portas da sua máquina. Para trocar:  PORTA_SITE=9090 ./04-site.sh
PORTA_SITE="${PORTA_SITE:-8080}"
PORTA_LOGIN="${PORTA_LOGIN:-8081}"

# Mostra o comando em amarelo, do jeito que você o digitaria, e depois o executa
roda() {
    local linha="" arg
    for arg in "$@"; do
        if [[ -z "$arg" || "$arg" =~ [^A-Za-z0-9_./:=@%+,-] ]]; then
            arg="'${arg//\'/\'\\\'\'}'"
        fi
        linha+="$arg "
    done
    printf '\033[1;33m$ %s\033[0m\n' "${linha% }"
    "$@"
}

# Apaga containers pelo nome, um por vez e em silêncio (não reclama se não
# existirem). O "escuta" usa a rede do "login": ele precisa vir antes na lista.
tira() {
    local nome
    for nome in "$@"; do
        podman rm -f "$nome" > /dev/null 2>&1
    done
    return 0
}

# Para com uma explicação se faltar argumento:  precisa 2 "$#" "./07-curl.sh USUARIO SENHA"
precisa() {
    if [ "$2" -lt "$1" ]; then
        echo "Uso: $3" >&2
        exit 1
    fi
}

# Para com uma explicação se o container ainda não existir
existe() {
    if ! podman container exists "$1"; then
        echo "O container '$1' não está rodando. Suba antes com: $2" >&2
        exit 1
    fi
}

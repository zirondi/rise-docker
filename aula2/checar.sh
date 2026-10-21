#!/usr/bin/env bash
# Antes da aula 2: rode numa máquina do lab, com conta de ALUNO, dentro de aula2/,
# depois do ./00-preparar.sh. Cada item imprime OK ou FALHOU.
# Usa nomes próprios (checar-*): não mexe nos containers da aula.
set -u
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

FALHAS=0
ok()     { printf '  \033[32mOK\033[0m      %s\n' "$1"; }
falhou() { printf '  \033[31mFALHOU\033[0m  %s\n' "$1"; FALHAS=$((FALHAS + 1)); }
titulo() { printf '\n[%s] %s\n' "$1" "$2"; }
faxina() {
    tira checar-escuta checar-login checar-site
    podman volume rm checar-dados > /dev/null 2>&1
    podman rmi checar-meu-site > /dev/null 2>&1
}
trap faxina EXIT
faxina

titulo 1 "Imagens carregadas"
for img in rise-lab rise-web; do
    if podman image exists "$img"; then ok "$img"; else falhou "$img ausente: rode ./00-preparar.sh"; fi
done

titulo 2 "Ferramentas da aula"
for prog in curl less; do
    if command -v "$prog" > /dev/null; then ok "$prog"; else falhou "$prog não encontrado"; fi
done

titulo 3 "Portas $PORTA_SITE e $PORTA_LOGIN livres"
for porta in "$PORTA_SITE" "$PORTA_LOGIN"; do
    if curl -s -o /dev/null --max-time 2 "http://localhost:$porta"; then
        falhou "porta $porta já responde: veja com ./estado.sh"
    else
        ok "porta $porta"
    fi
done

titulo 4 "Lab 4: servidor web da imagem rise-lab"
podman run -d --name checar-site -p "$PORTA_SITE":80 rise-lab httpd -f -v -h /www > /dev/null 2>&1
sleep 1
codigo=$(curl -s -o /dev/null -w '%{http_code}' --max-time 5 "http://localhost:$PORTA_SITE")
if [ "$codigo" = 200 ]; then ok "responde 200"; else falhou "respondeu '$codigo'"; fi
tira checar-site

titulo 5 "Lab 5: build sem baixar nada"
if podman build --pull=never -q -t checar-meu-site meu-site > /dev/null 2>&1; then
    ok "meu-site construída"
else
    falhou "build falhou: rode 'podman build --pull=never -t teste meu-site' para ver o erro"
fi

titulo 6 "Labs 6 a 8: site de login com volume"
podman run -d --name checar-login -p "$PORTA_LOGIN":80 -v checar-dados:/dados rise-web > /dev/null 2>&1
sleep 2
codigo=$(curl -s -o /dev/null -w '%{http_code}' --max-time 5 "http://localhost:$PORTA_LOGIN/login?usuario=ana&senha=123456")
if [ "$codigo" = 200 ]; then ok "login certo responde 200"; else falhou "login respondeu '$codigo'"; fi
if podman exec checar-login sqlite3 /dados/usuarios.db 'SELECT senha FROM usuarios' 2> /dev/null | grep -q cafe-com-leite-42; then
    ok "sqlite3 lê o banco"
else
    falhou "sqlite3 não leu o banco"
fi
if podman logs checar-login 2>&1 | grep -q 'senha=123456'; then ok "a senha aparece no log"; else falhou "a senha não apareceu no log"; fi

titulo 7 "A senha na rede (só no telão): tcpdump ao lado do site"
podman run -d --name checar-escuta --network container:checar-login --cap-add NET_RAW \
    rise-web tcpdump -A -l -i any 'tcp port 80' > /dev/null 2>&1
sleep 2
curl -s -o /dev/null --max-time 5 "http://localhost:$PORTA_LOGIN/login?usuario=professor&senha=batata-frita"
sleep 1
if podman logs checar-escuta 2>&1 | grep -q 'senha=batata-frita'; then
    ok "o tcpdump viu a senha"
else
    falhou "o tcpdump não viu a senha; use o plano B: ./escutar.sh --dentro"
    podman logs checar-escuta 2>&1 | tail -3 | sed 's/^/          /'
fi

echo
if [ "$FALHAS" -eq 0 ]; then
    echo "Tudo certo para a aula 2."
else
    echo "$FALHAS item(ns) falharam."
fi
exit "$FALHAS"

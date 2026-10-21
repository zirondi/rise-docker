#!/usr/bin/env bash
# Exemplo final: o mesmo site, mas o formulário envia por POST (no corpo do
# pedido) em vez de GET (na URL). Rodar de novo apaga o antigo e sobe outro.
set -u
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

tira escuta site login
roda podman run -d --name login -p "$PORTA_LOGIN":80 -e METODO=post rise-web

echo
echo "Abra no navegador: http://localhost:$PORTA_LOGIN"

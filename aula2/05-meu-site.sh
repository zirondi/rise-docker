#!/usr/bin/env bash
# Lab 5: sobe um container a partir da SUA imagem. Sem "httpd ..." no final:
# a receita já diz o que rodar. Rodar de novo apaga o antigo e sobe outro.
set -u
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

tira site
roda podman run -d --name site -p "$PORTA_SITE":80 meu-site

echo
echo "Abra no navegador: http://localhost:$PORTA_SITE"

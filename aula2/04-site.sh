#!/usr/bin/env bash
# Lab 4: um servidor web em segundo plano, a partir da imagem da aula 1.
# Rodar de novo apaga o container "site" antigo e sobe um novo, igualzinho.
set -u
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

tira site
# -d: segundo plano.  -p: porta da sua máquina -> porta 80 do container
roda podman run -d --name site -p "$PORTA_SITE":80 rise-lab httpd -f -v -h /www

echo
echo "Abra no navegador: http://localhost:$PORTA_SITE"

#!/usr/bin/env bash
# Lab 8: o mesmo site, agora com o banco num volume FORA do container.
# Rodar de novo apaga o container, mas o volume "dados-login" (e as contas) fica.
set -u
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

tira escuta site login
roda podman run -d --name login -p "$PORTA_LOGIN":80 -v dados-login:/dados rise-web

echo
echo "Abra no navegador: http://localhost:$PORTA_LOGIN"

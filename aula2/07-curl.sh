#!/usr/bin/env bash
# Lab 7: faz o mesmo pedido de login que o navegador faz, só que pelo terminal.
# Linhas com ">" foram ENVIADAS; linhas com "<" VOLTARAM do servidor.
#   ./07-curl.sh SEU_USUARIO SUA_SENHA
set -u
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
precisa 2 "$#" "./07-curl.sh USUARIO SENHA   (exemplo: ./07-curl.sh ana 123456)"

roda curl -v "http://localhost:$PORTA_LOGIN/login?usuario=$1&senha=$2"

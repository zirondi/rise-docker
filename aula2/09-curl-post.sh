#!/usr/bin/env bash
# Exemplo final: o pedido de login por POST, feito na mão.
# A senha vai depois dos cabeçalhos, não na primeira linha.
#   ./09-curl-post.sh ana 123456
set -u
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
precisa 2 "$#" "./09-curl-post.sh USUARIO SENHA   (exemplo: ./09-curl-post.sh ana 123456)"

roda curl -v -d "usuario=$1&senha=$2" "http://localhost:$PORTA_LOGIN/login"

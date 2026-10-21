#!/usr/bin/env bash
# Lab 6: o site com login. O banco fica DENTRO do container.
# Rodar de novo apaga o container antigo (e o banco junto) e sobe outro.
set -u
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

tira escuta site login
roda podman run -d --name login -p "$PORTA_LOGIN":80 rise-web

echo
echo "Abra no navegador: http://localhost:$PORTA_LOGIN"
echo "Invente uma senha só para esta aula. Não use nenhuma senha sua de verdade."

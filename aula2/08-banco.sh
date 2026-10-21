#!/usr/bin/env bash
# Lab 8: lê o banco de usuários do site, por fora, sem digitar senha nenhuma.
set -u
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
existe login ./06-login.sh

roda podman exec login sqlite3 -header -column /dados/usuarios.db 'SELECT * FROM usuarios'

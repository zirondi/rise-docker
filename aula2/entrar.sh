#!/usr/bin/env bash
# Abre um shell DENTRO de um container que já está rodando. Saia com: exit
#   ./entrar.sh site
set -u
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
precisa 1 "$#" "./entrar.sh NOME   (exemplo: ./entrar.sh site)"

roda podman exec -it "$1" bash

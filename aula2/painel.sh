#!/usr/bin/env bash
# Painel ao vivo de um container: CPU, memória e processos. Ctrl+C para sair.
#   ./painel.sh login
set -u
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
precisa 1 "$#" "./painel.sh NOME   (exemplo: ./painel.sh site)"

roda podman stats "$1"

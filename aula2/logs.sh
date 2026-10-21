#!/usr/bin/env bash
# Mostra tudo o que um container imprimiu e continua acompanhando. Ctrl+C para sair.
#   ./logs.sh site
set -u
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
precisa 1 "$#" "./logs.sh NOME   (exemplo: ./logs.sh site)"

roda podman logs -f "$1"

#!/usr/bin/env bash
# Lab 8: copia o banco para fora do container, como um backup esquecido,
# e procura uma senha nele sem usar programa de banco nenhum.
set -u
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
existe login ./06-login.sh

roda podman cp login:/dados/usuarios.db vazou.db
roda grep -a -o 'cafe[a-z0-9-]*' vazou.db

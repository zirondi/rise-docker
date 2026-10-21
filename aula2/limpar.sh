#!/usr/bin/env bash
# Fim da aula: apaga os containers, o volume, a cópia do banco e a imagem meu-site.
# Não mexe nas imagens rise-lab e rise-web nem em nenhum outro container seu.
set -u
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

roda podman rm -f --ignore escuta site login
roda podman volume rm --force dados-login
roda podman rmi --ignore meu-site
roda rm -f vazou.db
echo
echo "Pronto."

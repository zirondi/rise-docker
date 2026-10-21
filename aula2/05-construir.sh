#!/usr/bin/env bash
# Lab 5: constrói a imagem meu-site a partir da receita em meu-site/Containerfile.
# Edite meu-site/index.html antes, e rode de novo sempre que mudar alguma coisa.
set -u
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

roda cat meu-site/Containerfile
echo
roda podman build -t meu-site meu-site
echo
roda podman history meu-site

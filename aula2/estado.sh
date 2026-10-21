#!/usr/bin/env bash
# O que existe agora na sua máquina: containers rodando, imagens e volumes.
set -u
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

roda podman ps
echo
roda podman images
echo
roda podman volume ls

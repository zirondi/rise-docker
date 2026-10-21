#!/usr/bin/env bash
# Prepara a aula: carrega as imagens rise-lab (aula 1) e rise-web (hoje).
# Num computador que não é x86_64 (Mac com chip Apple), constrói em vez de carregar.
set -u
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

case "$(uname -m)" in
    x86_64 | amd64)
        roda podman load -i ../imagens/rise-lab-amd64.tar.gz
        roda podman load -i imagens/rise-web-amd64.tar.gz
        ;;
    *)
        roda podman build -t rise-lab ..
        roda podman build -t rise-web .
        ;;
esac

# Sobras de um ensaio anterior
tira escuta site login

echo
roda podman images
echo
echo "Devem aparecer rise-lab e rise-web."

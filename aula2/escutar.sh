#!/usr/bin/env bash
# A senha na rede: um segundo container, colado na rede do site, só escutando
# a porta 80. Rode no terminal B, faça login no navegador e olhe. Ctrl+C para parar.
#   ./escutar.sh            jeito normal
#   ./escutar.sh --dentro   plano B, se der erro de permissão: recria o site com
#                           permissão de captura e escuta de dentro dele
set -u
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
existe login ./06-login.sh

if [ "${1:-}" = "--dentro" ]; then
    tira escuta login
    roda podman run -d --name login -p "$PORTA_LOGIN":80 --cap-add NET_RAW rise-web
    roda podman exec -it login tcpdump -A -l -i any 'tcp port 80'
else
    tira escuta
    roda podman run --rm --name escuta --network container:login --cap-add NET_RAW \
        rise-web tcpdump -A -l -i any 'tcp port 80'
fi

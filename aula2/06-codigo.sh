#!/usr/bin/env bash
# Lab 6: o código do site inteiro. Procure onde a senha é guardada e onde é comparada.
# Setas ou espaço para andar, / para buscar uma palavra, q para sair.
set -u
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

roda less app/site.py

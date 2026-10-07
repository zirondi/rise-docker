#!/usr/bin/env bash
echo "⚠️  AVISO: isto é uma fork bomb. Rode SOMENTE dentro do container!"
echo "PID (Fork Bomb Launcher): $$"
read -r -p "Pressione Enter se tiver certeza de iniciar a BOMB... "
# Define uma função chamada ":" que chama a si mesma duas vezes, em background.
# Cada chamada cria mais duas, que criam mais duas... até acabar o limite de processos.
:(){ :|:& };:

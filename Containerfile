# Receita da imagem do laboratório. Cada linha vira uma "camada" da imagem.
# Para construir:  podman build -t rise-lab .

# --- Etapa 1: compila o programa em C (essa etapa é descartada no final) ---
FROM public.ecr.aws/docker/library/alpine:3.21 AS compilador
RUN apk add --no-cache gcc musl-dev
COPY scripts/mem_leak.c /src/mem_leak.c
RUN gcc -O2 -Wall /src/mem_leak.c -o /mem_leak

# --- Etapa 2: a imagem que vocês vão usar ---
FROM public.ecr.aws/docker/library/alpine:3.21

# bash (para a fork bomb clássica) e httpd (servidor web minúsculo do busybox)
RUN apk add --no-cache bash busybox-extras

COPY --from=compilador /mem_leak /usr/local/bin/mem_leak
COPY scripts/fork_bomb.sh /usr/local/bin/fork_bomb
COPY www /www
RUN chmod +x /usr/local/bin/fork_bomb

# Um prompt que deixa óbvio que você está DENTRO do container
ENV PS1="[container \h] \w # "

# O que roda quando ninguém pede outra coisa: um shell
CMD ["bash"]

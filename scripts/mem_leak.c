#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#define CHUNK_MB 5
#define CHUNK_BYTES (CHUNK_MB * 1024 * 1024)

int main(void) {
    // Desabilitar buffer do stdout para garantir saída instantânea via SSH/Docker
    setvbuf(stdout, NULL, _IONBF, 0);

    printf("====================================================\n");
    printf("   🔥 RISE — Demonstração de Vazamento de Memória\n");
    printf("   PID do Processo: %d\n", getpid());
    printf("====================================================\n");
    printf("Pressione [ENTER] para iniciar o vazamento de memória...\n");
    getchar();

    size_t total_mb = 0;
    int chunk_count = 0;

    while (1) {
        // Aloca 5MB no Heap usando o clássico malloc() de C
        char *ptr = (char *)malloc(CHUNK_BYTES);

        if (ptr == NULL) {
            printf("[AVISO] malloc() retornou NULL!\n");
        } else {
            // PONTO CHAVE DE SISTEMAS OPERACIONAIS (Overcommit de Memória):
            // O Linux não aloca a RAM física só porque demos malloc().
            // Ele apenas reserva espaço no mapa virtual do processo.
            // Para forçar o Linux a alocar páginas físicas reais (Page Fault),
            // precisamos escrever na memória (a cada 4KB / tamanho padrão de página):
            for (size_t i = 0; i < CHUNK_BYTES; i += 4096) {
                ptr[i] = 'A';
            }
            ptr[CHUNK_BYTES - 1] = '\0';
        }

        total_mb += CHUNK_MB;
        chunk_count++;
        printf("-> [%02d] malloc() +5 MB alocados e preenchidos (Total: %zu MB)...\n", 
               chunk_count, total_mb);

        // Pausa de 120ms para permitir que os alunos vejam a contagem subindo
        usleep(120000);
    }

    return 0;
}

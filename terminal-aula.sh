# Prompt curto e título de janela para a aula. Vale só para o terminal atual.
#
#   source terminal-aula.sh A      # janela da esquerda: dentro do container
#   source terminal-aula.sh B      # janela da direita: observando de fora
#
# Para voltar ao normal, feche o terminal ou rode: aula_reset

_aula_letra="${1:-A}"

case "$_aula_letra" in
    A | a) _aula_letra=A _aula_nome="A — DENTRO do container" _aula_cor='1;32' ;;
    B | b) _aula_letra=B _aula_nome="B — FORA (observando)" _aula_cor='1;34' ;;
    *) _aula_nome="$_aula_letra" _aula_cor='1;33' ;;
esac

# Guarda o prompt original uma única vez
: "${_AULA_PS1_ORIGINAL:=$PS1}"

# \[\e]0;TITULO\a\]  -> título da janela (reaplicado a cada prompt)
# [A] pasta $        -> letra colorida + só o nome da pasta atual
PS1="\[\e]0;${_aula_nome}\a\]\[\e[${_aula_cor}m\][${_aula_letra}]\[\e[0m\] \W \$ "

aula_reset() {
    PS1="$_AULA_PS1_ORIGINAL"
    unset _AULA_PS1_ORIGINAL
}

unset _aula_letra _aula_nome _aula_cor

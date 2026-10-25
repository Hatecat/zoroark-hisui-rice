# Prompt de oh-my-zsh con la paleta Zoroark de Hisui (necesita una Nerd Font para el icono de git
# y una fuente con runas, p. ej. google-noto-sans-runic-fonts)
#
#   ᛉ ~/Documentos/poke-tactics  main ●
#   ❯
#
# Cada prompt muestra una runa al azar del futhark antiguo.
# La flecha es carmesí; si el último comando falló, sale en dorado con su código de salida.
# Las rutas de más de tres carpetas se acortan a …/las/tres/últimas.

_zoroark_runes=(ᚠ ᚢ ᚦ ᚨ ᚱ ᚲ ᚷ ᚹ ᚺ ᚾ ᛁ ᛃ ᛇ ᛈ ᛉ ᛊ ᛏ ᛒ ᛖ ᛗ ᛚ ᛜ ᛞ ᛟ)

# Se elige en precmd y no con $(...) dentro de PROMPT: en una subshell $RANDOM no avanza
# y saldría siempre la misma runa.
_zoroark_pick_rune() { _zoroark_rune=${_zoroark_runes[RANDOM % ${#_zoroark_runes} + 1]} }
autoload -Uz add-zsh-hook
add-zsh-hook precmd _zoroark_pick_rune

PROMPT='%F{#D82F45}${_zoroark_rune}%f %B%F{#E6A1AB}%(4~|…/%3~|%~)%f%b$(git_prompt_info)
%(?.%F{#D82F45}❯%f.%F{#F3C94E}%? ❯%f) '
RPROMPT=''

ZSH_THEME_GIT_PROMPT_PREFIX=" %F{#F3C94E} "
ZSH_THEME_GIT_PROMPT_SUFFIX="%f"
ZSH_THEME_GIT_PROMPT_DIRTY=" %F{#D82F45}●"
ZSH_THEME_GIT_PROMPT_CLEAN=""

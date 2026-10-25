# Prompt de oh-my-zsh con la paleta Zoroark de Hisui (necesita una Nerd Font para el icono de git)
#
#   ✦ ~/Documentos/poke-tactics  main ●
#   ❯
#
# La flecha es carmesí; si el último comando falló, sale en dorado con su código de salida.
# Las rutas de más de tres carpetas se acortan a …/las/tres/últimas.

PROMPT='%F{#D82F45}✦%f %B%F{#E6A1AB}%(4~|…/%3~|%~)%f%b$(git_prompt_info)
%(?.%F{#D82F45}❯%f.%F{#F3C94E}%? ❯%f) '
RPROMPT=''

ZSH_THEME_GIT_PROMPT_PREFIX=" %F{#F3C94E} "
ZSH_THEME_GIT_PROMPT_SUFFIX="%f"
ZSH_THEME_GIT_PROMPT_DIRTY=" %F{#D82F45}●"
ZSH_THEME_GIT_PROMPT_CLEAN=""

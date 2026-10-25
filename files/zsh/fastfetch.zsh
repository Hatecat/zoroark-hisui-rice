# Fastfetch con tema Zoroark de Hisui (solo en shells interactivas)
# NO_FASTFETCH=1 lo omite (lo usa Terminal 3 de la sesión de kitty)
if [[ -o interactive && -z $NO_FASTFETCH ]] && command -v fastfetch >/dev/null; then
    # Kitty abre la shell antes de dar al panel su tamaño final (~100 ms):
    # esperar a que el tamaño lleve 150 ms sin cambiar (máx. 1 s) para no partir líneas
    zmodload zsh/zselect
    local _ff_prev=$(stty size) _ff_cur _ff_quiet=0 _ff_i
    for _ff_i in {1..50}; do
        zselect -t 2
        _ff_cur=$(stty size)
        if [[ $_ff_cur == $_ff_prev ]]; then
            (( ++_ff_quiet >= 8 )) && break
        else
            _ff_quiet=0 _ff_prev=$_ff_cur
        fi
    done
    # En terminales estrechas el logo va arriba para que el texto no lo parta
    if (( ${_ff_cur#* } < 90 )); then
        fastfetch --logo-position top
    else
        fastfetch
    fi
    unset _ff_prev _ff_cur _ff_quiet _ff_i
fi
unset NO_FASTFETCH

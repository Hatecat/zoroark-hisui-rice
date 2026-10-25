#!/usr/bin/env bash
# Regenera los fondos redondeados del estilo de Plasma a partir de los de Breeze:
# menús emergentes (dialogs/background) y tooltips (widgets/tooltip), en sus cuatro variantes.
# Uso: build.sh <carpeta del desktoptheme>   (por defecto, la instalada)
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
theme=${1:-$HOME/.local/share/plasma/desktoptheme/zoroark-hisui}
breeze=/usr/share/plasma/desktoptheme/default
tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT

# archivo:opacidad translúcida:opciones
# Las variantes con efectos llevan la opacidad indicada y sin sombra (las de Breeze asoman
# en las esquinas redondeadas); las opacas, sin efectos de escritorio, conservan la sombra.
for item in "dialogs/background:0.60:--radio=22 --margen=10" \
            "widgets/tooltip:0.70:--radio=12 --margen=6"; do
    IFS=: read -r file op opts <<<"$item"
    for variant in "" translucent/ opaque/ solid/; do
        case $variant in
            opaque/|solid/) o=1; extra="" ;;
            *) o=$op; extra=--sin-sombra ;;
        esac
        zcat "$breeze/$variant$file.svgz" > "$tmp"
        mkdir -p "$(dirname "$theme/$variant$file")"
        # shellcheck disable=SC2086
        python3 -I "$here/gen_dialog.py" "$tmp" "$theme/$variant$file.svg" "$o" $extra $opts
    done
done

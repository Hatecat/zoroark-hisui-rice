#!/usr/bin/env bash
# Acorta los nombres del menú de GRUB para que quepan en el tema:
#   "Nobara Linux (7.2.11-200.nobara.fc44.x86_64) 44 (KDE Plasma Desktop Edition)" → "Nobara 44 · 7.2.11"
#   "Windows Boot Manager (en /dev/nvme1n1p1)" → "Windows"
# Uso: sudo ./install-boot-titulos.sh
#
# - Kernels: instala files/boot/kernel/96-zoroark-titulos.install en /etc/kernel/install.d, que
#   acorta las entradas de /boot/loader/entries cada vez que se instala un kernel, y lo ejecuta ya.
# - Otros sistemas: os-prober no deja cambiar el nombre, así que las entradas que encontró se
#   copian con nombre corto a /etc/grub.d/30_os-prober-zoroark y se desactiva os-prober.
#   Si se reinstala Windows (cambia su partición), borra ese archivo, pon
#   GRUB_DISABLE_OS_PROBER="false" y regenera grub.cfg.
# Todo lo que cambia se respalda en /root/zoroark-hisui-respaldo-boot/<fecha>-titulos/, junto con
# un restaurar.sh que lo deja como estaba.
set -euo pipefail

say() { printf '\033[38;2;216;47;69m==>\033[0m %s\n' "$*"; }
die() { printf '\033[38;2;216;47;69m  ✗\033[0m %s\n' "$*" >&2; exit 1; }

[[ $EUID -eq 0 ]] || die "Ejecútalo con sudo: sudo $0"
for cmd in grub2-mkconfig grub2-script-check; do
    command -v "$cmd" >/dev/null || die "falta $cmd"
done

here=$(cd "$(dirname "$0")" && pwd)
cfg=/boot/grub2/grub.cfg
defaults=/etc/default/grub
bls=/boot/loader/entries
hook=/etc/kernel/install.d/96-zoroark-titulos.install
others=/etc/grub.d/30_os-prober-zoroark
backup="/root/zoroark-hisui-respaldo-boot/$(date +%Y%m%d-%H%M%S)-titulos"

[[ -f $cfg && -d $bls ]] || die "no existe $cfg o $bls"

mkdir -p "$backup"
cp -a "$defaults" "$cfg" "$backup/"
cp -a "$bls" "$backup/entries"
[[ -f $others ]] && cp -a "$others" "$backup/"
cat > "$backup/restaurar.sh" <<EOF
#!/usr/bin/env bash
# Deja los nombres del menú de GRUB como estaban antes de install-boot-titulos.sh
set -e
rm -f $hook $others
cp -a "$backup/grub" $defaults
cp -a "$backup/grub.cfg" $cfg
cp -a "$backup/entries/." $bls/
[[ -f "$backup/$(basename "$others")" ]] && cp -a "$backup/$(basename "$others")" $others
echo "Restaurado. Los kernels instalados después del respaldo conservan el nombre corto hasta"
echo "que se reinstalen."
EOF
chmod +x "$backup/restaurar.sh"

say "Nombres de los kernels"
install -D -m 755 "$here/files/boot/kernel/96-zoroark-titulos.install" "$hook"
"$hook"
grep -h '^title' "$bls"/*.conf | sed 's/^title[ \t]*/  /'

say "Otros sistemas (os-prober)"
# Entradas de os-prober del menú actual con el nombre sin "(en /dev/…)"; conservan su id, así que
# install-boot.sh las sigue reconociendo
prober=$(sed -n '/### BEGIN \/etc\/grub.d\/30_os-prober/,/### END \/etc\/grub.d\/30_os-prober/p' "$cfg" |
    awk '/^menuentry /{on=1} on{print} on && /^}/{on=0}' |
    sed -E "s/^menuentry '([^']*) \((en|on) [^)]*\)'/menuentry '\1'/; s/^menuentry 'Windows Boot Manager'/menuentry 'Windows'/")
if [[ -n $prober ]]; then
    {
        echo '#!/usr/bin/sh'
        echo '# Entradas de os-prober con nombre corto, copiadas por install-boot-titulos.sh (tema Zoroark)'
        echo "cat <<'ZOROARK_FIN'"
        printf '%s\n' "$prober"
        echo 'ZOROARK_FIN'
    } > "$others"
    chmod 755 "$others"
    sed -i '/^GRUB_DISABLE_OS_PROBER=/d' "$defaults"
    echo 'GRUB_DISABLE_OS_PROBER="true"' >> "$defaults"
    grep '^menuentry' <<< "$prober" | cut -d"'" -f2 | sed 's/^/  /'
elif [[ -f $others ]]; then
    echo "  Ya estaban en $others"
else
    echo "  No hay"
fi

say "Generando el menú de GRUB (aparte, para compararlo)"
tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT
fail() {
    rm -f "$others"
    cp -a "$backup/grub" "$defaults"
    if [[ -f "$backup/$(basename "$others")" ]]; then cp -a "$backup/$(basename "$others")" "$others"; fi
    die "$1; /etc/default/grub restaurado, no se tocó grub.cfg (los kernels sí quedan acortados: $backup/restaurar.sh lo deshace)"
}
if ! grub2-mkconfig -o "$tmp" 2> "$backup/grub2-mkconfig.log" || ! grub2-script-check "$tmp"; then
    fail "grub2-mkconfig falló (ver $backup/grub2-mkconfig.log)"
fi
# Mismo criterio que install-boot.sh: cada entrada por su id, o por su título si no tiene
entries() {
    grep -E "^[[:space:]]*(menuentry|submenu) ['\"]" "$1" | sed -E \
        -e "s/.*\\\$menuentry_id_option '([^']*)'.*/id \1/" \
        -e "t" \
        -e "s/^[[:space:]]*((menuentry|submenu) ['\"][^'\"]*['\"]).*/\1/" | sort || true
}
missing=$(comm -23 <(entries "$cfg") <(entries "$tmp"))
[[ -z $missing ]] || { printf '%s\n' "$missing" >&2; fail "el menú nuevo perdería esas entradas"; }
install -m 600 "$tmp" "$cfg"

say "Listo. Reinicia para verlo."
echo "  Para deshacerlo: sudo $backup/restaurar.sh"

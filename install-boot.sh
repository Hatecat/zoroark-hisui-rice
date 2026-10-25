#!/usr/bin/env bash
# Aplica el tema Zoroark de Hisui al arranque: menú de GRUB y animación de Plymouth.
# Uso: sudo ./install-boot.sh
#
# - GRUB: copia el tema a /boot/grub2/themes/zoroark-hisui, activa el modo gráfico en
#   /etc/default/grub y regenera grub.cfg. El grub.cfg nuevo se genera primero aparte y solo
#   se usa si conserva todas las entradas del menú actual.
# - Plymouth: instala el tema en /usr/share/plymouth/themes/zoroark-hisui y reconstruye el
#   initramfs del kernel actual (tarda un minuto).
# Todo lo que cambia se respalda en /root/zoroark-hisui-respaldo-boot/<fecha>/, junto con un
# restaurar.sh que lo deja como estaba.
set -euo pipefail

say() { printf '\033[38;2;216;47;69m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[38;2;243;201;78m  !\033[0m %s\n' "$*"; }
die() { printf '\033[38;2;216;47;69m  ✗\033[0m %s\n' "$*" >&2; exit 1; }

[[ $EUID -eq 0 ]] || die "Ejecútalo con sudo: sudo $0"
for cmd in grub2-mkconfig grub2-script-check plymouth-set-default-theme; do
    command -v "$cmd" >/dev/null || die "falta $cmd"
done

here=$(cd "$(dirname "$0")" && pwd)
f="$here/files/boot"
cfg=/boot/grub2/grub.cfg
defaults=/etc/default/grub
gtheme=/boot/grub2/themes/zoroark-hisui
ptheme=/usr/share/plymouth/themes/zoroark-hisui
backup="/root/zoroark-hisui-respaldo-boot/$(date +%Y%m%d-%H%M%S)"

[[ -f $cfg ]] || die "no existe $cfg"
# En UEFI, el grub.cfg de la partición EFI debe ser el pequeño que carga /boot/grub2/grub.cfg
for stub in /boot/efi/EFI/*/grub.cfg; do
    [[ -f $stub ]] || continue
    grep -q configfile "$stub" || die "$stub no redirige a $cfg; este instalador no sabe dónde va el menú"
done

mkdir -p "$backup"
cp -a "$defaults" "$cfg" "$backup/"
prev_plymouth=$(plymouth-set-default-theme)
echo "$prev_plymouth" > "$backup/plymouth-theme"
cat > "$backup/restaurar.sh" <<EOF
#!/usr/bin/env bash
# Deja GRUB y Plymouth como estaban antes de install-boot.sh
set -e
cp -a "$backup/grub" $defaults
cp -a "$backup/grub.cfg" $cfg
plymouth-set-default-theme -R $prev_plymouth
echo "Restaurado. Los temas siguen en $gtheme y $ptheme; puedes borrarlos."
EOF
chmod +x "$backup/restaurar.sh"

say "Tema de GRUB"
rm -rf "$gtheme"
mkdir -p "$(dirname "$gtheme")"
cp -r "$f/grub/zoroark-hisui" "$gtheme"
chown -R root:root "$gtheme"

# Pone KEY="valor" en /etc/default/grub, quitando la línea anterior si existe
setkey() {
    sed -i "/^$1=/d" "$defaults"
    printf '%s="%s"\n' "$1" "$2" >> "$defaults"
}
setkey GRUB_TERMINAL_OUTPUT gfxterm
setkey GRUB_THEME "$gtheme/theme.txt"
setkey GRUB_GFXMODE "1920x1080,auto"
setkey GRUB_GFXPAYLOAD_LINUX keep
# Si el menú actual tiene entradas de os-prober (p. ej. Windows) se generó con os-prober
# activado, aunque /etc/default/grub no lo diga; hay que activarlo para no perderlas
if sed -n '/### BEGIN \/etc\/grub.d\/30_os-prober/,/### END \/etc\/grub.d\/30_os-prober/p' "$cfg" | grep -q menuentry; then
    setkey GRUB_DISABLE_OS_PROBER false
    echo "  Se activa os-prober: el menú actual tiene entradas de otros sistemas (Windows…)"
fi

say "Generando el menú de GRUB (aparte, para compararlo)"
tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT
if ! grub2-mkconfig -o "$tmp" 2> "$backup/grub2-mkconfig.log" || ! grub2-script-check "$tmp"; then
    cp -a "$backup/grub" "$defaults"
    die "grub2-mkconfig falló (ver $backup/grub2-mkconfig.log); /etc/default/grub restaurado, no se tocó nada más"
fi
# Identifica cada entrada por su id ($menuentry_id_option) si lo tiene, o por su título si no:
# el título cambia con el idioma (os-prober pone "(on /dev/…)" o "(en /dev/…)") y el id no
entries() {
    grep -E "^[[:space:]]*(menuentry|submenu) ['\"]" "$1" | sed -E \
        -e "s/.*\\\$menuentry_id_option '([^']*)'.*/id \1/" \
        -e "t" \
        -e "s/^[[:space:]]*((menuentry|submenu) ['\"][^'\"]*['\"]).*/\1/" | sort || true
}
missing=$(comm -23 <(entries "$cfg") <(entries "$tmp"))
if [[ -n $missing ]]; then
    cp -a "$backup/grub" "$defaults"
    printf '%s\n' "$missing" >&2
    die "el menú nuevo perdería esas entradas; /etc/default/grub restaurado, no se tocó grub.cfg"
fi
grep -q "set theme=" "$tmp" || warn "el grub.cfg nuevo no carga el tema (revisa $backup/grub2-mkconfig.log)"
install -m 600 "$tmp" "$cfg"
echo "  Entradas propias del menú conservadas: $(entries "$cfg" | wc -l) (las de los kernels vienen de /boot/loader/entries)"

say "Tema de Plymouth (antes: $prev_plymouth)"
rm -rf "$ptheme"
cp -r "$f/plymouth/zoroark-hisui" "$ptheme"
chown -R root:root "$ptheme"
say "Reconstruyendo el initramfs, tarda un poco"
plymouth-set-default-theme -R zoroark-hisui

say "Listo. Reinicia para verlo."
echo "  Respaldo: $backup"
echo "  Para deshacerlo: sudo $backup/restaurar.sh"

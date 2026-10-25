#!/usr/bin/env bash
# Aplica el tema Zoroark de Hisui a la pantalla de inicio de sesión (Plasma Login Manager).
# Uso: sudo ./install-login.sh      (después de ./install.sh, desde tu usuario)
#
# - Instala el estilo de Plasma, los iconos y el cursor para el usuario del greeter
#   (/var/lib/plasmalogin/.local/share), que no puede leer tu carpeta personal.
# - Copia tus kdeglobals, plasmarc y kcminputrc al greeter, como hace el botón de
#   sincronizar de Preferencias del sistema → Pantalla de inicio de sesión.
# - Pone el fondo de Akari con Zoroark.
# Lo que cambia se respalda en /var/lib/plasmalogin/.zoroark-respaldo/<fecha>/.
set -euo pipefail

say() { printf '\033[38;2;216;47;69m==>\033[0m %s\n' "$*"; }

[[ $EUID -eq 0 ]] || { echo "Ejecútalo con sudo: sudo $0" >&2; exit 1; }
user=${SUDO_USER:-}
[[ -n $user && $user != root ]] || { echo "Ejecútalo con sudo desde tu usuario, no como root directamente" >&2; exit 1; }
uhome=$(getent passwd "$user" | cut -d: -f6)
getent passwd plasmalogin >/dev/null || { echo "No existe el usuario plasmalogin: ¿usas Plasma Login Manager?" >&2; exit 1; }

here=$(cd "$(dirname "$0")" && pwd)
f="$here/files"
greeter=$(getent passwd plasmalogin | cut -d: -f6)
gshare="$greeter/.local/share"
backup="$greeter/.zoroark-respaldo/$(date +%Y%m%d-%H%M%S)"
wall=/usr/share/plasmalogin/wallpapers/zoroark-hisui/akari-zoroark.jpg
mkdir -p "$backup"

say "Estilo de Plasma, iconos y cursor para el greeter"
mkdir -p "$gshare/plasma/desktoptheme" "$gshare/icons"
rm -rf "$gshare/plasma/desktoptheme/zoroark-hisui"
cp -a "$f/plasma/zoroark-hisui" "$gshare/plasma/desktoptheme/"
tar xzf "$f/icons/tela-circle-D82F45.tar.gz" -C "$gshare/icons"
tar xzf "$f/cursors/night-diamond-red.tar.gz" -C "$gshare/icons"
chown -R plasmalogin:plasmalogin "$greeter/.local"

say "Ajustes de $user (colores, estilo, iconos, cursor)"
mkdir -p "$greeter/.config"
for x in kdeglobals plasmarc kcminputrc; do
    [[ -f $uhome/.config/$x ]] || continue
    [[ -f $greeter/.config/$x ]] && cp -a "$greeter/.config/$x" "$backup/"
    install -o plasmalogin -g plasmalogin -m 644 "$uhome/.config/$x" "$greeter/.config/$x"
done
chown plasmalogin:plasmalogin "$greeter/.config"

say "Fondo de Akari con Zoroark"
install -D -m 644 "$f/wallpapers/akari-zoroark.jpg" "$wall"
cp -a /etc/plasmalogin.conf "$backup/"
kwriteconfig6 --file /etc/plasmalogin.conf --group Greeter --group Wallpaper \
    --group org.kde.image --group General --key Image "file://$wall"

say "Listo. Se verá la próxima vez que cierres sesión o reinicies."
echo "  Respaldo: $backup"

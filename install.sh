#!/usr/bin/env bash
# Instala el tema Zoroark de Hisui para KDE Plasma 6 en el usuario actual.
# Lo que ya exista y vaya a cambiar se respalda en ~/.local/share/zoroark-hisui-respaldo/<fecha>/
# (fuera de las carpetas de temas, para que las copias no aparezcan como temas en Plasma).
set -euo pipefail

here=$(cd "$(dirname "$0")" && pwd)
f="$here/files"
share=${XDG_DATA_HOME:-$HOME/.local/share}
conf=${XDG_CONFIG_HOME:-$HOME/.config}
backup="$share/zoroark-hisui-respaldo/$(date +%Y%m%d-%H%M%S)"

say() { printf '\033[38;2;216;47;69m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[38;2;243;201;78m  !\033[0m %s\n' "$*"; }
have() { command -v "$1" >/dev/null 2>&1; }

# Mueve dst al respaldo conservando su ruta relativa a $HOME
stash() {
    local dst=$1 rel=${1#"$HOME"/}
    mkdir -p "$(dirname "$backup/$rel")"
    mv "$dst" "$backup/$rel"
    warn "respaldado ~/$rel"
}

# Copia un archivo; si ya existe y es distinto, respalda el anterior
put() {
    local src=$1 dst=$2
    mkdir -p "$(dirname "$dst")"
    if [[ -e $dst ]]; then
        cmp -s "$src" "$dst" && return
        stash "$dst"
    fi
    cp -a "$src" "$dst"
}

# Copia una carpeta completa; si ya existe y es distinta, respalda la anterior
put_dir() {
    local src=$1 dst=$2
    mkdir -p "$(dirname "$dst")"
    if [[ -e $dst ]]; then
        diff -rq "$src" "$dst" >/dev/null 2>&1 && return
        stash "$dst"
    fi
    cp -a "$src" "$dst"
}

say "Estilo de Plasma, esquema de color y decoración de ventanas"
put_dir "$f/plasma/zoroark-hisui" "$share/plasma/desktoptheme/zoroark-hisui"
put "$f/color-schemes/ZoroarkHisui.colors" "$share/color-schemes/ZoroarkHisui.colors"
put_dir "$f/aurorae/zoroark-hisui" "$share/aurorae/themes/zoroark-hisui"

say "Pantalla de bloqueo (reloj abajo y fondo de Akari con Zoroark)"
put_dir "$f/lockscreen/org.zoroark.hisui.lockscreen" "$share/plasma/shells/org.zoroark.hisui.lockscreen"
put "$f/wallpapers/akari-zoroark.jpg" "$share/wallpapers/zoroark-hisui/akari-zoroark.jpg"
# El bloqueador elige su paquete con PLASMA_DEFAULT_SHELL; se le pone solo a KWin
# para que plasmashell siga usando org.kde.plasma.desktop
put "$f/lockscreen/zoroark-lockscreen.conf" "$conf/systemd/user/plasma-kwin_wayland.service.d/zoroark-lockscreen.conf"
systemctl --user daemon-reload 2>/dev/null || true
lockimg="file://$share/wallpapers/zoroark-hisui/akari-zoroark.jpg"
for key in Image PreviewImage; do
    kwriteconfig6 --file kscreenlockerrc --group Greeter --group Wallpaper --group org.kde.image --group General --key "$key" "$lockimg"
done
kwriteconfig6 --file kscreenlockerrc --group Greeter --group Wallpaper --group org.kde.image --group General --key FillMode 2

say "Pantalla de carga al iniciar sesión"
put_dir "$f/splash/org.zoroark.hisui.splash" "$share/plasma/look-and-feel/org.zoroark.hisui.splash"
kwriteconfig6 --file ksplashrc --group KSplash --key Theme org.zoroark.hisui.splash
kwriteconfig6 --file ksplashrc --group KSplash --key Engine KSplashQML

say "Sonidos del sistema"
put_dir "$f/sounds/zoroark-hisui" "$share/sounds/zoroark-hisui"
# El grito de Zoroark de Hisui no va en el paquete: se descarga de PokeAPI y se monta en el
# sonido de inicio de sesión; sin red queda el inicio solo con campanas
cry=$(mktemp --suffix=.ogg)
if curl -sfLo "$cry" https://raw.githubusercontent.com/PokeAPI/cries/main/cries/pokemon/latest/10239.ogg &&
    python3 "$here/tools/gen_sounds.py" --login "$cry" "$share/sounds/zoroark-hisui/stereo/desktop-login.oga"; then
    echo "  Inicio de sesión con el grito de Zoroark de Hisui"
else
    warn "no se pudo descargar el grito (o falta NumPy/sox); el inicio de sesión suena solo con campanas"
fi
rm -f "$cry"
kwriteconfig6 --file kdeglobals --group Sounds --key Theme zoroark-hisui
for ini in "$conf/gtk-3.0/settings.ini" "$conf/gtk-4.0/settings.ini"; do
    [[ -f $ini ]] && sed -i 's/^gtk-sound-theme-name=.*/gtk-sound-theme-name=zoroark-hisui/' "$ini"
done
have gsettings && gsettings set org.gnome.desktop.sound theme-name zoroark-hisui || true

say "Iconos (Tela Circle #D82F45), icono del menú y cursor"
mkdir -p "$share/icons" "$share/icons/hicolor/256x256/apps" "$HOME/.icons"
tar xzf "$f/icons/tela-circle-D82F45.tar.gz" -C "$share/icons"
put "$f/icons/zoroark-menu.png" "$share/icons/hicolor/256x256/apps/zoroark-menu.png"
tar xzf "$f/cursors/oreo-pink.tar.gz" -C "$HOME/.icons"

say "kitty, fastfetch, btop y cava"
for x in kitty.conf zoroark-session.conf zoroark-start.sh; do
    tmp=$(mktemp)
    sed "s|@HOME@|$HOME|g" "$f/kitty/$x" > "$tmp"
    chmod --reference="$f/kitty/$x" "$tmp"
    put "$tmp" "$conf/kitty/$x"
    rm -f "$tmp"
done
for x in config.jsonc zoroark.png zoroark.txt; do
    put "$f/fastfetch/$x" "$conf/fastfetch/$x"
done
put "$f/btop/zoroark-hisui.theme" "$conf/btop/themes/zoroark-hisui.theme"
if [[ -f $conf/btop/btop.conf ]]; then
    sed -i 's/^color_theme = .*/color_theme = "zoroark-hisui"/' "$conf/btop/btop.conf"
else
    warn "btop.conf no existe: abre btop una vez y elige el tema zoroark-hisui (tecla Esc → Options)"
fi
put "$f/cava/config" "$conf/cava/config"

say "Tema de Brave (se carga a mano, ver README)"
put_dir "$f/brave-theme" "$share/brave-themes/zoroark-hisui"

say "fastfetch al abrir zsh"
if [[ -f $HOME/.zshrc ]] && grep -q 'Fastfetch con tema Zoroark' "$HOME/.zshrc"; then
    warn "~/.zshrc ya tiene el bloque de fastfetch, no se toca"
else
    { echo; cat "$f/zsh/fastfetch.zsh"; } >> "$HOME/.zshrc"
fi

say "Prompt de zsh (oh-my-zsh)"
if [[ -d $HOME/.oh-my-zsh ]]; then
    put "$f/zsh/zoroark.zsh-theme" "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/zoroark.zsh-theme"
    if grep -q '^ZSH_THEME=' "$HOME/.zshrc" && ! grep -q '^ZSH_THEME="zoroark"' "$HOME/.zshrc"; then
        mkdir -p "$backup"
        cp -a "$HOME/.zshrc" "$backup/.zshrc"
        warn "respaldado ~/.zshrc"
        sed -i 's/^ZSH_THEME=.*/ZSH_THEME="zoroark"/' "$HOME/.zshrc"
    fi
else
    warn "no está oh-my-zsh; el prompt queda en files/zsh/zoroark.zsh-theme"
fi

say "Ajustes de KWin (decoración, esquinas redondeadas, desenfoque)"
group=
while IFS= read -r line; do
    [[ -z $line ]] && continue
    if [[ $line =~ ^\[(.*)\]$ ]]; then
        group=${BASH_REMATCH[1]}
    else
        kwriteconfig6 --file kwinrc --group "$group" --key "${line%%=*}" "${line#*=}"
    fi
done < "$f/kwin/kwinrc-zoroark.ini"

say "Aplicando el tema"
have plasma-apply-colorscheme && plasma-apply-colorscheme ZoroarkHisui || warn "no se pudo aplicar el esquema de color"
have plasma-apply-desktoptheme && plasma-apply-desktoptheme zoroark-hisui || warn "no se pudo aplicar el estilo de Plasma"
have plasma-apply-cursortheme && plasma-apply-cursortheme oreo_pink_cursors || warn "no se pudo aplicar el cursor"
if [[ -x /usr/libexec/plasma-changeicons ]]; then
    /usr/libexec/plasma-changeicons Tela-circle-D82F45-dark
else
    kwriteconfig6 --file kdeglobals --group Icons --key Theme Tela-circle-D82F45-dark
fi
rm -f "$HOME/.cache/icon-cache.kcache" "$HOME/.cache/plasma_theme_zoroark-hisui.kcache"
have qdbus && qdbus org.kde.KWin /KWin reconfigure >/dev/null 2>&1 || true

# Menú Kickoff: icono de Zoroark, favoritos en cuadrícula, cambio de categoría al pasar el ratón
if have qdbus; then
    qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript '
panels().forEach(function (p) {
  p.widgets("org.kde.plasma.kickoff").forEach(function (w) {
    w.currentConfigGroup = ["General"];
    w.writeConfig("icon", "zoroark-menu");
    w.writeConfig("favoritesDisplay", 0);
    w.writeConfig("applicationsDisplay", 1);
    w.writeConfig("switchCategoryOnHover", true);
    w.writeConfig("showActionButtonCaptions", true);
    w.writeConfig("highlightNewlyInstalledApps", true);
    w.reloadConfig();
  });
});' >/dev/null || warn "no se pudo configurar el menú Kickoff"
fi
systemctl --user restart plasma-plasmashell 2>/dev/null || warn "reinicia la sesión para ver el estilo de Plasma"

say "Comprobando dependencias"
for cmd in kitty fastfetch btop cava; do
    have "$cmd" || warn "falta $cmd (sudo dnf install $cmd)"
done
[[ $(fc-list : family) == *"Cascadia Code NF"* ]] || warn "falta la fuente Cascadia Code NF (sudo dnf install cascadia-code-nf-fonts)"
fc-list ':charset=16a0' family | grep -q . || warn "falta una fuente con runas para el prompt (sudo dnf install google-noto-sans-runic-fonts)"
compgen -G "/usr/lib*/qt6/plugins/kwin/effects/*/*shapecorners*" >/dev/null || \
    warn "falta el efecto de esquinas redondeadas (sudo dnf install kde-rounded-corners)"

say "Listo. Cierra la sesión y vuelve a entrar para ver la pantalla de bloqueo nueva."

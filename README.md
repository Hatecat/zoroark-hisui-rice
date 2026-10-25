# Zoroark de Hisui — tema para KDE Plasma 6

Tema completo de escritorio con la paleta de Zoroark de Hisui:

| Color | Hex | Uso |
|---|---|---|
| Carmesí | `#D82F45` | acento, bordes, carpetas |
| Dorado | `#F3C94E` | resaltados |
| Rosa | `#E6A1AB` | enlaces y títulos |
| Blanco | `#F2F0F0` | texto |
| Fondo | `#29262D` / `#1E1C22` | ventanas y menús |

## Qué incluye

- **Estilo de Plasma** `zoroark-hisui`: panel con degradado carmesí y menús emergentes
  (Kickoff, bandeja, calendario) con esquinas de 22 px, degradado y 60 % de opacidad.
- **Esquema de color** `ZoroarkHisui` y **decoración de ventanas** Aurorae `zoroark-hisui`.
- **Iconos** Tela Circle con las carpetas en `#D82F45` (variante oscura).
- **Cursor** Night Diamond (Red).
- **Menú Kickoff** con la cara de Zoroark como icono, favoritos en cuadrícula.
- **Pantalla de bloqueo** con el arte de Akari y Zoroark, y el reloj abajo a la izquierda
  (hora en blanco, fecha en dorado, barra carmesí y degradado oscuro).
- **Pantalla de carga** al iniciar sesión: Zoroark flotando sobre un resplandor carmesí y una
  barra de progreso. Para verla sin cerrar sesión: `ksplashqml --test --window org.zoroark.hisui.splash`.
- **Arranque**: menú de GRUB con el arte de Akari y un panel oscuro con el menú a la izquierda,
  y animación de Plymouth con Zoroark sobre un resplandor carmesí.
- **KWin**: esquinas redondeadas con borde degradado carmesí–rosa (efecto *KDE Rounded Corners*)
  y desenfoque suave (intensidad 3).
- **kitty**: paleta del tema y sesión de 3 paneles (fastfetch, btop y una terminal).
- **fastfetch**: arte de Zoroark con el texto a la derecha, en los colores del tema.
- **zsh**: prompt de oh-my-zsh `zoroark` (ruta en rosa, rama de git en dorado, flecha carmesí que pasa a dorado con el código de salida si el comando falla).
- **Sonidos del sistema**: campanas en la escala japonesa In y barridos de "ilusión" (generados con
  `tools/gen_sounds.py`); al iniciar sesión, la ilusión se forma y suena el grito de Zoroark de Hisui,
  que `install.sh` descarga de PokeAPI (no va en el paquete). Lo que no tiene sonido propio usa Ocean.
- **btop**, **cava** y un tema para **Brave**.

## Instalar

```bash
tar xzf zoroark-hisui-rice.tar.gz
cd zoroark-hisui-rice
./install.sh
```

Se instala solo en tu usuario (`~/.local/share`, `~/.config`, `~/.icons`), sin sudo.
Si ya tienes alguno de esos archivos, se guarda una copia en
`~/.local/share/zoroark-hisui-respaldo/<fecha>/` antes de reemplazarlo.

### Pantalla de inicio de sesión (opcional, con sudo)

Para Plasma Login Manager, después de `./install.sh`:

```bash
sudo ./install-login.sh
```

Instala el estilo, los iconos y el cursor para el usuario `plasmalogin`, le copia tus ajustes de
colores y pone el fondo de Akari con Zoroark. La interfaz de esa pantalla va compilada en el
programa, así que el reloj sigue arriba. Respaldo en `/var/lib/plasmalogin/.zoroark-respaldo/`.

### Arranque: GRUB y Plymouth (opcional, con sudo)

```bash
sudo ./install-boot.sh
```

- Copia el tema de GRUB a `/boot/grub2/themes/zoroark-hisui` y en `/etc/default/grub` pone
  `GRUB_TERMINAL_OUTPUT="gfxterm"`, `GRUB_THEME`, `GRUB_GFXMODE="1920x1080,auto"` y
  `GRUB_GFXPAYLOAD_LINUX="keep"`.
- Genera el `grub.cfg` nuevo aparte y solo lo usa si conserva todas las entradas propias del
  menú actual (FreeBSD, ajustes de UEFI…); si no, deja todo como estaba.
- Instala el tema de Plymouth `zoroark-hisui` y reconstruye el initramfs del kernel actual.
- Respaldo en `/root/zoroark-hisui-respaldo-boot/<fecha>/`. Para deshacerlo:
  `sudo /root/zoroark-hisui-respaldo-boot/<fecha>/restaurar.sh`.

Está pensado para Fedora/Nobara con UEFI (`/boot/grub2/grub.cfg`). Las imágenes se
regeneran con `tools/gen_boot.py` (necesita Pillow y NumPy) y las fuentes con
`grub2-mkfont -s <tamaño> -o files/boot/grub/zoroark-hisui/Inter-<tamaño>.pf2 Inter-Regular.ttf`.

Si el monitor principal no es 1920×1080, el fondo se estira; cambia `GRUB_GFXMODE` a su resolución.

#### Nombres cortos en el menú (opcional, con sudo)

```bash
sudo ./install-boot-titulos.sh
```

Los nombres por defecto no caben en el panel del tema. Este script los acorta:
`Nobara Linux (7.2.11-200.nobara.fc44.x86_64) 44 (KDE Plasma Desktop Edition)` pasa a `Nobara 44 · 7.2.11`,
y `Windows Boot Manager (en /dev/nvme1n1p1)` pasa a `Windows`.

- Kernels: instala `/etc/kernel/install.d/96-zoroark-titulos.install`, que acorta también los
  kernels que se instalen después.
- Otros sistemas: copia las entradas de os-prober con nombre corto a
  `/etc/grub.d/30_os-prober-zoroark` y desactiva os-prober. Si reinstalas Windows, borra ese
  archivo, pon `GRUB_DISABLE_OS_PROBER="false"` y vuelve a ejecutar el script.
- Respaldo y `restaurar.sh` en `/root/zoroark-hisui-respaldo-boot/<fecha>-titulos/`.

### Dependencias (Fedora / Nobara)

```bash
sudo dnf install kitty fastfetch btop cava cascadia-code-nf-fonts kde-rounded-corners sox python3-numpy
```

El instalador avisa al final si falta alguna.

### Tema de Brave

Brave no permite instalar temas desde la terminal:

1. Abre `brave://extensions` y activa el **Modo de desarrollador**.
2. Pulsa **Cargar descomprimida** y elige `~/.local/share/brave-themes/zoroark-hisui`.

## Ajustar el fondo de los menús

`tools/build.sh` regenera los menús emergentes y los tooltips del estilo de Plasma a partir de los de Breeze.
Los valores se cambian al principio de `tools/gen_dialog.py`:

- `R`: radio de las esquinas (22).
- `TOP, MID, BOT`: colores del degradado.
- `BORDER, BORDER_OP`: color y opacidad del borde.
- La opacidad (0.60 en menús, 0.70 en tooltips) y el radio de cada uno están en `tools/build.sh`.

```bash
tools/build.sh                     # regenera el estilo instalado
rm -f ~/.cache/plasma_theme_zoroark-hisui.kcache
systemctl --user restart plasma-plasmashell
```

`tools/sim.py` (necesita PySide6) monta una vista previa de un menú pieza a pieza,
igual que Plasma, para revisar los cambios sin aplicarlos:

```bash
QT_QPA_PLATFORM=offscreen python3 tools/sim.py \
    ~/.local/share/plasma/desktoptheme/zoroark-hisui/dialogs/background.svg vista.png
```

Notas:

- Los menús no llevan sombra: las de Breeze están hechas para esquinas de ~5 px y
  asomaban en las esquinas al ser translúcidos.
- Plasma 6 solo usa la variante `translucent/` si está activo el efecto de contraste de KWin;
  si no, usa `dialogs/`. Por eso las dos tienen la misma opacidad.

## Pantalla de bloqueo

Plasma 6 carga la pantalla de bloqueo desde un paquete de *shell*, no desde el tema global.
Este tema instala uno propio, `org.zoroark.hisui.lockscreen`, que es una copia de la de
Plasma 6.7.5 con el reloj cambiado (`ZoroarkClock.qml`) y un degradado en `LockScreenUi.qml`.

Para que el bloqueador lo use sin que plasmashell cambie de shell, se le pasa
`PLASMA_DEFAULT_SHELL` solo al servicio de KWin, que es quien lanza el bloqueador:
`~/.config/systemd/user/plasma-kwin_wayland.service.d/zoroark-lockscreen.conf`.
Se aplica al volver a iniciar sesión.

- **Probarla sin bloquear la sesión:**
  `/usr/libexec/kscreenlocker_greet --testing --shell org.zoroark.hisui.lockscreen`
- **Volver a la de Breeze:** borra el archivo `.conf` de arriba y vuelve a iniciar sesión.
- **Si Plasma se actualiza** y la pantalla de bloqueo falla, el bloqueador vuelve solo a la
  de Breeze. Para ponerla al día, copia de nuevo
  `/usr/share/plasma/shells/org.kde.plasma.desktop/contents/lockscreen/` y vuelve a aplicar
  los cambios del reloj.

## Créditos

- Zoroark de Hisui, su arte oficial y su grito © Nintendo / Game Freak / The Pokémon Company.
  Es un proyecto de fans sin ánimo de lucro; el grito no va en el repo, `install.sh` lo descarga de
  [PokeAPI](https://github.com/PokeAPI/cries).
- Fondo de Akari y Zoroark extraído del fondo de Wallpaper Engine
  [3027881590](https://steamcommunity.com/sharedfiles/filedetails/?id=3027881590) de Steam Workshop.
- Cursor Night Diamond (Red).
- Fuente [Inter](https://rsms.me/inter/) de Rasmus Andersson (SIL OFL 1.1) en el menú de GRUB.
- Iconos [Tela Circle](https://github.com/vinceliuice/Tela-circle-icon-theme) de vinceliuice (GPL-3.0).
- Menús emergentes basados en el estilo Breeze de KDE (LGPL).

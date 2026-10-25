#!/usr/bin/env python3
"""Vista previa del menú de GRUB (no se puede capturar desde el sistema).

Monta la pantalla con las imágenes de files/boot/grub/zoroark-hisui y la disposición de su
theme.txt, a 1920×1080. Las entradas son las de un Nobara con install-boot-titulos.sh.

Uso: python3 tools/preview_grub.py salida.png
Necesita Pillow y la fuente Inter (rsms-inter-fonts).
"""
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

THEME = Path(__file__).parent.parent / "files/boot/grub/zoroark-hisui"
FONT = "/usr/share/fonts/rsms-inter-fonts/Inter-Regular.ttf"
W, H = 1920, 1080
ENTRIES = ["Nobara 44 · 7.2.11", "Nobara 44 · 7.2.10", "Nobara 44 · 7.2.9", "Nobara 44 · rescate",
           "Memtest86+", "Windows", "UEFI Firmware Settings"]


def font(size):
    return ImageFont.truetype(FONT, size)


def label(draw, x, y, h, text, size, color):
    """Texto centrado en vertical dentro de una caja de alto h, como los label de GRUB."""
    f = font(size)
    top, bottom = f.getbbox("Ág")[1], f.getbbox("Ág")[3]
    draw.text((x, y + (h - (bottom - top)) / 2 - top), text, font=f, fill=color)


def nine_slice(prefix, w, h):
    """Rellena w×h con las 9 piezas prefix_{nw,n,ne,w,c,e,sw,s,se}.png."""
    p = {k: Image.open(THEME / f"{prefix}_{k}.png").convert("RGBA")
         for k in ("nw", "n", "ne", "w", "c", "e", "sw", "s", "se")}
    l, t = p["nw"].size
    r, b = p["se"].size
    out = Image.new("RGBA", (w, h))
    out.paste(p["c"].resize((w - l - r, h - t - b)), (l, t))
    out.paste(p["n"].resize((w - l - r, t)), (l, 0))
    out.paste(p["s"].resize((w - l - r, b)), (l, h - b))
    out.paste(p["w"].resize((l, h - t - b)), (0, t))
    out.paste(p["e"].resize((r, h - t - b)), (w - r, t))
    out.paste(p["nw"], (0, 0))
    out.paste(p["ne"], (w - r, 0))
    out.paste(p["sw"], (0, h - b))
    out.paste(p["se"], (w - r, h - b))
    return out


def main():
    img = Image.open(THEME / "background.png").convert("RGBA").resize((W, H))
    d = ImageDraw.Draw(img)
    top = round(H * 0.17)
    left = round(W * 0.06)
    label(d, left, top, 50, "Zoroark de Hisui", 36, "#F2F0F0")
    label(d, left, top + 56, 30, "Elige un sistema para arrancar", 16, "#E6A1AB")
    img.alpha_composite(Image.open(THEME / "accent.png").convert("RGBA").resize((64, 4)), (left, top + 100))

    # boot_menu: item_height 48, item_padding 16, item_spacing 8; el primero está seleccionado
    mx, my, mw = round(W * 0.05), top + 130, round(W * 0.34)
    for i, entry in enumerate(ENTRIES):
        y = my + 16 + i * (48 + 8)
        if i == 0:
            img.alpha_composite(nine_slice("select", mw - 16, 48), (mx + 8, y))
        label(d, mx + 16 + 8, y, 48, entry, 22, "#FFFFFF" if i == 0 else "#C9C4CC")

    # Cuenta atrás a mitad (quedan 3 de 5 s)
    by, bw = round(H * 0.86), round(W * 0.24)
    d.rectangle((left, by, left + bw, by + 5), fill="#3A3540")
    d.rectangle((left, by, left + round(bw * 0.6), by + 5), fill="#D82F45")
    label(d, left, by + 16, 24, "Arranque automático en 3 s", 16, "#E6A1AB")
    label(d, left, round(H * 0.93), 24, "↑ ↓ elegir     Enter arrancar     e editar     c consola", 16, "#8C8592")
    img.convert("RGB").save(sys.argv[1])


if __name__ == "__main__":
    main()

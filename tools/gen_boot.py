#!/usr/bin/env python3
"""Genera las imágenes del tema de arranque (GRUB y Plymouth).

Uso: tools/gen_boot.py          (desde la carpeta del paquete)

- files/boot/grub/zoroark-hisui/background.png: arte de Akari con un panel oscuro a la izquierda
- files/boot/grub/zoroark-hisui/select_*.png: resaltado redondeado del menú, en 9 piezas
- files/boot/plymouth/zoroark-hisui/watermark.png: Zoroark sobre el resplandor carmesí
- files/boot/plymouth/zoroark-hisui/throbber-*.png: arco carmesí que gira
"""
import math
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

HERE = Path(__file__).resolve().parent.parent
F = HERE / "files"
GRUB = F / "boot/grub/zoroark-hisui"
PLY = F / "boot/plymouth/zoroark-hisui"

BG = (30, 28, 34)          # #1E1C22
CRIMSON = (216, 47, 69)    # #D82F45
PINK = (230, 161, 171)     # #E6A1AB


def smooth(x):
    return x * x * (3 - 2 * x)


def grub_background():
    art = Image.open(F / "wallpapers/akari-zoroark.jpg").convert("RGB").resize((1920, 1080))
    w, h = art.size
    blurred = art.filter(ImageFilter.GaussianBlur(14))
    # Opacidad del panel: casi opaco hasta el 34 % del ancho y se desvanece hasta el 64 %
    xs = np.linspace(0, 1, w)
    t = np.clip((xs - 0.34) / 0.30, 0, 1)
    alpha = 0.90 * (1 - smooth(t))
    blur_mix = np.clip(1 - t * 1.2, 0, 1)[None, :, None]
    a = np.asarray(art, dtype=np.float32)
    b = np.asarray(blurred, dtype=np.float32)
    base = a * (1 - blur_mix) + b * blur_mix
    alpha = alpha[None, :, None]
    out = base * (1 - alpha) + np.array(BG, dtype=np.float32) * alpha
    # Viñeta suave abajo para la barra de tiempo
    ys = np.linspace(0, 1, h)[:, None, None]
    v = 0.45 * smooth(np.clip((ys - 0.70) / 0.30, 0, 1))
    out = out * (1 - v) + np.array(BG, dtype=np.float32) * v
    # Ruido leve para que el degradado no haga bandas
    out += np.random.default_rng(1).normal(0, 1.2, out.shape)
    Image.fromarray(np.clip(out, 0, 255).astype(np.uint8)).save(GRUB / "background.png", optimize=True)


def grub_select():
    # Rectángulo redondeado de 48 px con radio 12, cortado en 9 piezas con esquinas de 12 px
    s, r = 4, 12
    size = 48
    big = Image.new("RGBA", (size * s, size * s), (0, 0, 0, 0))
    d = ImageDraw.Draw(big)
    d.rounded_rectangle((0, 0, size * s - 1, size * s - 1), r * s, fill=CRIMSON + (215,))
    img = big.resize((size, size), Image.LANCZOS)
    # Brillo rosa a la izquierda, como una barra de acento
    acc = Image.new("RGBA", (size * s, size * s), (0, 0, 0, 0))
    ImageDraw.Draw(acc).rounded_rectangle((0, 0, size * s - 1, size * s - 1), r * s, fill=PINK + (60,))
    acc = acc.resize((size, size), Image.LANCZOS)
    cuts = {"nw": (0, 0, r, r), "n": (r, 0, size - r, r), "ne": (size - r, 0, size, r),
            "w": (0, r, r, size - r), "c": (r, r, size - r, size - r), "e": (size - r, r, size, size - r),
            "sw": (0, size - r, r, size), "s": (r, size - r, size - r, size), "se": (size - r, size - r, size, size)}
    for name, box in cuts.items():
        piece = img.crop(box)
        if name in ("nw", "w", "sw"):
            piece = Image.alpha_composite(piece, acc.crop(box))
        piece.save(GRUB / f"select_{name}.png")


def plymouth_watermark():
    # Resplandor radial carmesí con Zoroark encima; el fondo lo pone Plymouth (degradado)
    W = H = 720
    ys, xs = np.mgrid[0:H, 0:W]
    d = np.hypot(xs - W / 2, ys - H / 2) / (W / 2)
    a = np.clip(1 - d, 0, 1) ** 2.0 * 0.70
    a += np.random.default_rng(2).normal(0, 0.004, a.shape)
    glow = np.zeros((H, W, 4), dtype=np.float32)
    glow[..., :3] = CRIMSON
    glow[..., 3] = np.clip(a, 0, 1) * 255
    img = Image.fromarray(glow.astype(np.uint8), "RGBA")
    z = Image.open(F / "fastfetch/zoroark.png").convert("RGBA")
    zh = 400
    z = z.resize((round(z.width * zh / z.height), zh), Image.LANCZOS)
    img.alpha_composite(z, ((W - z.width) // 2, (H - zh) // 2 - 10))
    img.save(PLY / "watermark.png", optimize=True)


def plymouth_throbber(frames=30, size=48, width=4):
    s = 4
    for i in range(frames):
        big = Image.new("RGBA", (size * s, size * s), (0, 0, 0, 0))
        d = ImageDraw.Draw(big)
        box = (width * s, width * s, (size - width) * s, (size - width) * s)
        d.ellipse(box, outline=(242, 240, 240, 40), width=width * s)
        start = i * 360 / frames - 90
        d.arc(box, start, start + 100, fill=CRIMSON + (255,), width=width * s)
        big.resize((size, size), Image.LANCZOS).save(PLY / f"throbber-{i + 1:04d}.png")


if __name__ == "__main__":
    GRUB.mkdir(parents=True, exist_ok=True)
    PLY.mkdir(parents=True, exist_ok=True)
    grub_background()
    grub_select()
    plymouth_watermark()
    plymouth_throbber()
    print("listo:", GRUB, PLY)

"""Genera dialogs/background.svg para el estilo de Plasma Zoroark de Hisui.

Parte del diálogo de Breeze: conserva sus sombras (shadow-*) y sustituye
el marco de 9 piezas, los márgenes y la máscara de desenfoque.
"""
import re
import sys

# Uso: gen_dialog.py <svg de Breeze> <salida.svg> <opacidad> [--sin-sombra] [--radio=N] [--margen=N]
src, out, opacity = sys.argv[1], sys.argv[2], float(sys.argv[3])
opts = sys.argv[4:]
no_shadow = "--sin-sombra" in opts

def opt(name, default):
    for o in opts:
        if o.startswith(f"--{name}="):
            return int(o.split("=", 1)[1])
    return default
svg = open(src).read()

R = opt("radio", 22)         # radio de las esquinas
C = 16          # tamaño del centro y de los bordes
BW = 1.0        # grosor del borde
MARGIN = opt("margen", 10)   # margen de contenido
H = 2 * R + C
OX, OY = 200, 0     # origen del marco (zona libre del lienzo)
MX, MY = 200, 80    # origen de la máscara

TOP, MID, BOT = "#6B2034", "#43202D", "#1E1C22"
BORDER, BORDER_OP = "#D82F45", 0.7

# Quitar el marco de Breeze: piezas, máscara, márgenes y el mosaico del centro
ids = r"(center|top|bottom|left|right|topleft|topright|bottomleft|bottomright)"
svg = re.sub(r'<g\b(?:(?!<g\b).)*?\bid="(?:%s|mask-[a-z]+|hint-[a-z-]+)"(?:(?!<g\b).)*?</g>' % ids, "", svg, flags=re.S)
svg = re.sub(r'<(rect|path)\b[^>]*\bid="(mask-[a-z]+|hint-[a-z-]+)"[^>]*/>', "", svg, flags=re.S)
leftover = re.findall(r'id="(%s|mask-[a-z]+|hint-(?:top|bottom|left|right)-(?:margin|inset)|hint-tile-center)"' % ids, svg)
assert not leftover, leftover

def g(i, x, y, body):
    return f'<g id="{i}" transform="translate({x},{y})">{body}</g>'

grad = (f'<linearGradient id="zh-bg" gradientUnits="userSpaceOnUse" x1="0" y1="{OY}" x2="0" y2="{OY + H}">'
        f'<stop offset="0" stop-color="{TOP}"/><stop offset="{R / H:.4f}" stop-color="{MID}"/>'
        f'<stop offset="{(R + C) / H:.4f}" stop-color="{BOT}"/><stop offset="1" stop-color="{BOT}"/></linearGradient>')
fill = f'fill="url(#zh-bg)" fill-opacity="{opacity}"'
# El borde va como relleno (no como trazo) para que Qt mida cada pieza exacta
stroke = f'fill="{BORDER}" fill-opacity="{BORDER_OP}"'
h, r = BW, R - BW

# Las piezas se dibujan en coordenadas absolutas para que el degradado case entre ellas
def piece(i, x, y, w, hh, fill_d, stroke_d):
    return (f'<g id="{i}"><path d="{fill_d}" {fill}/>'
            + (f'<path d="{stroke_d}" {stroke}/>' if stroke_d else "")
            + '</g>')

x0, x1, x2, x3 = OX, OX + R, OX + R + C, OX + H
y0, y1, y2, y3 = OY, OY + R, OY + R + C, OY + H
parts = [
    piece("topleft", x0, y0, R, R, f"M{x0},{y1} A{R},{R} 0 0 1 {x1},{y0} L{x1},{y1} Z",
          f"M{x0},{y1} A{R},{R} 0 0 1 {x1},{y0} V{y0 + h} A{r},{r} 0 0 0 {x0 + h},{y1} Z"),
    piece("top", x1, y0, C, R, f"M{x1},{y0} H{x2} V{y1} H{x1} Z", f"M{x1},{y0} H{x2} V{y0 + h} H{x1} Z"),
    piece("topright", x2, y0, R, R, f"M{x2},{y0} A{R},{R} 0 0 1 {x3},{y1} L{x2},{y1} Z",
          f"M{x2},{y0} A{R},{R} 0 0 1 {x3},{y1} H{x3 - h} A{r},{r} 0 0 0 {x2},{y0 + h} Z"),
    piece("left", x0, y1, R, C, f"M{x0},{y1} H{x1} V{y2} H{x0} Z", f"M{x0},{y1} H{x0 + h} V{y2} H{x0} Z"),
    piece("center", x1, y1, C, C, f"M{x1},{y1} H{x2} V{y2} H{x1} Z", None),
    piece("right", x2, y1, R, C, f"M{x2},{y1} H{x3} V{y2} H{x2} Z", f"M{x3 - h},{y1} H{x3} V{y2} H{x3 - h} Z"),
    piece("bottomleft", x0, y2, R, R, f"M{x0},{y2} A{R},{R} 0 0 0 {x1},{y3} L{x1},{y2} Z",
          f"M{x0},{y2} A{R},{R} 0 0 0 {x1},{y3} V{y3 - h} A{r},{r} 0 0 1 {x0 + h},{y2} Z"),
    piece("bottom", x1, y2, C, R, f"M{x1},{y2} H{x2} V{y3} H{x1} Z", f"M{x1},{y3 - h} H{x2} V{y3} H{x1} Z"),
    piece("bottomright", x2, y2, R, R, f"M{x3},{y2} A{R},{R} 0 0 1 {x2},{y3} L{x2},{y2} Z",
          f"M{x3},{y2} A{R},{R} 0 0 1 {x2},{y3} V{y3 - h} A{r},{r} 0 0 0 {x3 - h},{y2} Z"),
]

# Máscara de desenfoque con la misma forma redondeada
a0, a1, a2, a3 = MX, MX + R, MX + R + C, MX + H
b0, b1, b2, b3 = MY, MY + R, MY + R + C, MY + H
k = 'fill="#000"'
mask = [
    f'<path id="mask-topleft" d="M{a0},{b1} A{R},{R} 0 0 1 {a1},{b0} L{a1},{b1} Z" {k}/>',
    f'<rect id="mask-top" x="{a1}" y="{b0}" width="{C}" height="{R}" {k}/>',
    f'<path id="mask-topright" d="M{a2},{b0} A{R},{R} 0 0 1 {a3},{b1} L{a2},{b1} Z" {k}/>',
    f'<rect id="mask-left" x="{a0}" y="{b1}" width="{R}" height="{C}" {k}/>',
    f'<rect id="mask-center" x="{a1}" y="{b1}" width="{C}" height="{C}" {k}/>',
    f'<rect id="mask-right" x="{a2}" y="{b1}" width="{R}" height="{C}" {k}/>',
    f'<path id="mask-bottomleft" d="M{a0},{b2} A{R},{R} 0 0 0 {a1},{b3} L{a1},{b2} Z" {k}/>',
    f'<rect id="mask-bottom" x="{a1}" y="{b2}" width="{C}" height="{R}" {k}/>',
    f'<path id="mask-bottomright" d="M{a3},{b2} A{R},{R} 0 0 1 {a2},{b3} L{a2},{b2} Z" {k}/>',
]

hy = OY + H + 120
hints = [
    f'<rect id="hint-top-margin" x="200" y="{hy}" width="4" height="{MARGIN}" fill="#f0f"/>',
    f'<rect id="hint-bottom-margin" x="210" y="{hy}" width="4" height="{MARGIN}" fill="#f0f"/>',
    f'<rect id="hint-left-margin" x="220" y="{hy}" width="{MARGIN}" height="4" fill="#f0f"/>',
    f'<rect id="hint-right-margin" x="235" y="{hy}" width="{MARGIN}" height="4" fill="#f0f"/>',
    f'<rect id="hint-top-inset" x="250" y="{hy}" width="4" height="0.00000001" fill="#0f0"/>',
    f'<rect id="hint-bottom-inset" x="256" y="{hy}" width="4" height="0.00000001" fill="#0f0"/>',
    f'<rect id="hint-left-inset" x="262" y="{hy}" width="0.00000001" height="4" fill="#0f0"/>',
    f'<rect id="hint-right-inset" x="266" y="{hy}" width="0.00000001" height="4" fill="#0f0"/>',
]

# Las sombras de Breeze están hechas para esquinas de ~5 px y asoman en los huecos
# de las esquinas cuando el fondo es translúcido: se desactivan renombrándolas
if no_shadow:
    svg = svg.replace('id="shadow-', 'id="off-shadow-')

block = "<defs>" + grad + "</defs>" + "".join(parts) + "".join(mask) + "".join(hints)
svg = re.sub(r'viewBox="[^"]*"', 'viewBox="0 0 300 220"', svg, count=1)
svg = re.sub(r'(<svg\b[^>]*?)\bwidth="[^"]*"', r'\1width="300"', svg, count=1)
svg = re.sub(r'(<svg\b[^>]*?)\bheight="[^"]*"', r'\1height="220"', svg, count=1)
svg = svg.replace("</svg>", block + "</svg>")
open(out, "w").write(svg)
print("ok", out)

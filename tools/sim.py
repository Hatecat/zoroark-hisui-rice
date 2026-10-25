# Vista previa: monta un menú emergente pieza a pieza con QSvgRenderer, igual que Plasma.
# Uso: QT_QPA_PLATFORM=offscreen python3 sim.py <background.svg> <salida.png>
import sys
from PySide6.QtGui import QGuiApplication, QImage, QPainter, QColor
from PySide6.QtSvg import QSvgRenderer
from PySide6.QtCore import QRectF

app = QGuiApplication(sys.argv[:1])
r = QSvgRenderer(sys.argv[1])
W, H = 360, 460
img = QImage(W + 80, H + 80, QImage.Format_ARGB32)
img.fill(QColor("#6b5f73"))
p = QPainter(img)
p.setRenderHint(QPainter.Antialiasing)
b = {i: r.boundsOnElement(i) for i in ["topleft", "top", "topright", "left", "center", "right", "bottomleft", "bottom", "bottomright"]}
missing = [i for i in b if not r.elementExists(i)]
print("faltan:", missing)
for i in ["hint-top-margin", "hint-left-margin", "mask-center", "shadow-top"]:
    print(i, r.elementExists(i), r.boundsOnElement(i).size().toTuple())
L, T = b["topleft"].width(), b["topleft"].height()
Rr, B = b["bottomright"].width(), b["bottomright"].height()
x0, y0 = 40, 40
cols = [(x0, L), (x0 + L, W - L - Rr), (x0 + W - Rr, Rr)]
rows = [(y0, T), (y0 + T, H - T - B), (y0 + H - B, B)]
names = [["topleft", "top", "topright"], ["left", "center", "right"], ["bottomleft", "bottom", "bottomright"]]
for ri, (y, h) in enumerate(rows):
    for ci, (x, w) in enumerate(cols):
        r.render(p, names[ri][ci], QRectF(x, y, w, h))
p.end()
img.save(sys.argv[2])

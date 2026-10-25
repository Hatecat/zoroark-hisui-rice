#!/usr/bin/env python3
"""Genera el tema de sonidos Zoroark de Hisui (freedesktop) en files/sounds/zoroark-hisui.

Los sonidos se sintetizan aquí: campanas tipo FM con la escala japonesa In (La, Si♭, Re, Mi, Fa),
por Hisui, y barridos de ruido para las ilusiones. La reverberación y el paso a Ogg Vorbis los
hace sox. El grito de Zoroark de Hisui no se incluye en el paquete: install.sh lo descarga y
monta desktop-login.oga con tools/gen_sounds.py --login <grito.ogg> <salida.oga>.

Uso: python3 tools/gen_sounds.py [carpeta de salida]
Necesita NumPy y sox.
"""
import subprocess
import sys
import tempfile
import wave
from pathlib import Path

import numpy as np

SR = 48000
rng = np.random.default_rng(571)  # Zoroark es el n.º 571: los ruidos salen siempre iguales

# Escala In sobre La: La, Si♭, Re, Mi, Fa
SEMI = {"A": 0, "Bb": 1, "D": 5, "E": 7, "F": 8}


def note(name, octave):
    """Frecuencia de una nota de la escala (La4 = 440 Hz)."""
    return 440.0 * 2 ** ((SEMI[name] + 12 * (octave - 4) - (12 if SEMI[name] > 2 else 0)) / 12)


def silence(dur):
    return np.zeros(int(SR * dur))


def bell(freq, dur=1.2, amp=1.0, bright=1.0):
    """Campana FM: portadora con moduladora inarmónica (1.4×) y un parcial agudo que se apaga antes,
    más una copia desafinada unos cents que da el brillo inestable de la ilusión."""
    t = np.arange(int(SR * dur)) / SR
    env = np.exp(-t * 4.5 / dur) * np.minimum(1, t / 0.004)
    index = bright * 2.2 * np.exp(-t * 9)
    out = np.zeros_like(t)
    for detune, pan in ((1.0, 1.0), (1.0035, 0.55)):
        f = freq * detune
        out += pan * np.sin(2 * np.pi * f * t + index * np.sin(2 * np.pi * f * 1.4 * t))
    out += 0.25 * bright * np.sin(2 * np.pi * freq * 2.76 * t) * np.exp(-t * 14)
    return amp * env * out / 2


def pad(freq, dur, amp=1.0):
    """Nota grave sostenida (onda triangular suavizada) para avisos y errores."""
    t = np.arange(int(SR * dur)) / SR
    env = np.minimum(1, t / 0.05) * np.exp(-t * 3 / dur)
    wave_ = sum(np.sin(2 * np.pi * freq * k * t) * (1 / k**2) * (-1) ** (k // 2) for k in (1, 3, 5, 7))
    return amp * env * wave_


def whoosh(dur, f0, f1, amp=1.0):
    """Ruido filtrado con un paso banda que barre de f0 a f1 Hz (sube o baja)."""
    n = int(SR * dur)
    noise = rng.standard_normal(n)
    t = np.arange(n) / SR
    fc = f0 * (f1 / f0) ** (t / dur)
    # Filtro de estado variable de 2 polos con frecuencia variable
    out = np.empty(n)
    low = band = 0.0
    q = 0.35
    for i in range(n):
        g = 2 * np.sin(np.pi * min(fc[i], SR / 6) / SR)
        high = noise[i] - low - q * band
        band += g * high
        low += g * band
        out[i] = band
    env = np.sin(np.pi * np.clip(t / dur, 0, 1)) ** 2
    return amp * env * out / (np.abs(out).max() + 1e-9)


def seq(*parts):
    """Mezcla (inicio_en_segundos, señal) en una sola pista."""
    end = max(int(SR * start) + len(sig) for start, sig in parts)
    out = np.zeros(end)
    for start, sig in parts:
        i = int(SR * start)
        out[i : i + len(sig)] += sig
    return out


def arpeggio(notes, step, dur=1.2, amp=1.0, bright=1.0):
    return seq(*((i * step, bell(note(n, o), dur, amp, bright)) for i, (n, o) in enumerate(notes)))


SOUNDS = {
    # Mensajes y diálogos
    "dialog-information": lambda: arpeggio([("E", 5), ("A", 5)], 0.09, 1.0, 0.8),
    "message": lambda: arpeggio([("E", 5), ("A", 5)], 0.09, 1.0, 0.8),
    "message-new-instant": lambda: arpeggio([("D", 5), ("F", 5), ("A", 5)], 0.07, 0.9, 0.8),
    "message-new-email": lambda: arpeggio([("A", 5), ("E", 5), ("A", 5)], 0.08, 1.0, 0.7),
    "dialog-question": lambda: arpeggio([("A", 4), ("D", 5), ("Bb", 5)], 0.11, 1.3, 0.9),
    "dialog-warning": lambda: seq((0, pad(note("A", 3), 0.9, 0.7)), (0, bell(note("Bb", 4), 1.0, 0.8)),
                                  (0.16, bell(note("A", 4), 1.0, 0.7))),
    "dialog-warning-auth": lambda: seq((0, pad(note("D", 3), 0.8, 0.7)), (0, bell(note("F", 4), 0.9, 0.8)),
                                       (0.14, bell(note("E", 4), 0.9, 0.7))),
    "dialog-error": lambda: seq((0, pad(note("A", 2), 0.8, 1.0)), (0, bell(note("Bb", 4), 0.8, 0.8, 1.6)),
                                (0, bell(note("A", 4), 0.8, 0.6, 1.6))),
    "dialog-error-serious": lambda: seq((0, pad(note("A", 2), 1.0, 1.0)), (0, bell(note("Bb", 4), 1.0, 0.9, 1.8)),
                                        (0.18, bell(note("E", 4), 1.0, 0.8, 1.8))),
    "dialog-error-critical": lambda: seq((0, pad(note("A", 2), 1.2, 1.0)), (0, bell(note("Bb", 4), 1.0, 1.0, 2)),
                                         (0.15, bell(note("A", 4), 1.0, 0.9, 2)),
                                         (0.30, bell(note("Bb", 3), 1.2, 0.9, 2))),
    "bell": lambda: bell(note("A", 5), 0.9, 0.9, 0.9),
    "bell-window-system": lambda: bell(note("E", 5), 0.6, 0.8, 0.7),
    # Resultados
    "completion-success": lambda: arpeggio([("A", 4), ("D", 5), ("E", 5), ("A", 5)], 0.065, 1.1),
    "outcome-success": lambda: arpeggio([("A", 4), ("D", 5), ("E", 5), ("A", 5)], 0.065, 1.1),
    "complete-media-burn": lambda: arpeggio([("A", 4), ("D", 5), ("E", 5), ("A", 5)], 0.065, 1.1),
    "completion-partial": lambda: arpeggio([("A", 4), ("D", 5), ("E", 5)], 0.08, 1.1),
    "completion-fail": lambda: seq((0, pad(note("A", 2), 0.7, 0.6)),
                                   (0, arpeggio([("E", 5), ("Bb", 4)], 0.12, 1.0, 0.9, 1.4))),
    "outcome-failure": lambda: seq((0, pad(note("A", 2), 0.7, 0.6)),
                                   (0, arpeggio([("E", 5), ("Bb", 4)], 0.12, 1.0, 0.9, 1.4))),
    "complete-media-error": lambda: seq((0, pad(note("A", 2), 0.7, 0.6)),
                                       (0, arpeggio([("E", 5), ("Bb", 4)], 0.12, 1.0, 0.9, 1.4))),
    # Dispositivos y energía: aparecen y se desvanecen como ilusiones
    "device-added": lambda: seq((0, whoosh(0.35, 400, 4000, 0.35)), (0.22, bell(note("A", 5), 0.9, 0.8))),
    "device-removed": lambda: seq((0, whoosh(0.4, 4000, 300, 0.35)), (0.05, bell(note("E", 5), 0.9, 0.7)),
                                  (0.17, bell(note("A", 4), 1.0, 0.6))),
    "power-plug": lambda: seq((0, whoosh(0.3, 300, 2500, 0.3)), (0.18, bell(note("D", 5), 0.8, 0.7)),
                              (0.26, bell(note("A", 5), 0.9, 0.7))),
    "power-unplug": lambda: seq((0, whoosh(0.3, 2500, 300, 0.3)), (0.05, bell(note("A", 5), 0.8, 0.6)),
                                (0.13, bell(note("D", 5), 0.9, 0.6))),
    "battery-low": lambda: seq((0, pad(note("D", 3), 0.8, 0.6)), (0, bell(note("F", 4), 0.9, 0.8)),
                               (0.2, bell(note("F", 4), 0.9, 0.6))),
    "battery-caution": lambda: seq((0, pad(note("A", 2), 0.9, 0.8)), (0, bell(note("Bb", 4), 0.9, 0.8, 1.5)),
                                   (0.18, bell(note("Bb", 4), 0.9, 0.7, 1.5))),
    "battery-full": lambda: arpeggio([("D", 5), ("A", 5)], 0.1, 1.0, 0.8),
    # Pequeños
    "audio-volume-change": lambda: bell(note("A", 5), 0.18, 0.7, 0.5),
    "button-pressed": lambda: bell(note("E", 6), 0.08, 0.4, 0.3),
    "screen-capture": lambda: seq((0, whoosh(0.12, 6000, 1500, 0.5)), (0.04, bell(note("E", 6), 0.5, 0.6, 0.6))),
    "trash-empty": lambda: whoosh(0.7, 3000, 150, 0.7),
    # Sesión
    "desktop-logout": lambda: seq((0, arpeggio([("A", 5), ("E", 5), ("D", 5), ("A", 4)], 0.13, 1.5, 0.8)),
                                  (0.25, whoosh(1.2, 3000, 200, 0.3))),
    "desktop-login": lambda: login(None),
    "service-login": lambda: arpeggio([("A", 4), ("E", 5), ("A", 5)], 0.08, 1.1, 0.8),
    "service-logout": lambda: arpeggio([("A", 5), ("E", 5), ("A", 4)], 0.08, 1.1, 0.8),
    # Ventanas (KWin), muy discretos
    "window-attention": lambda: arpeggio([("D", 5), ("E", 5)], 0.1, 0.9, 0.7),
    "theme-demo": lambda: login(None),
}

# Volumen de cada sonido respecto al pico normalizado
GAIN = {"audio-volume-change": 0.5, "button-pressed": 0.35, "bell-window-system": 0.6}


def login(cry):
    """La ilusión se forma (barrido ascendente y arpegio) y aparece Zoroark de Hisui con su grito."""
    intro = seq((0, whoosh(1.1, 200, 5000, 0.35)),
                (0.35, arpeggio([("A", 4), ("D", 5), ("E", 5), ("A", 5), ("E", 6)], 0.11, 1.6, 0.6, 0.8)))
    if cry is None:
        return seq((0, intro), (0.95, bell(note("A", 4), 2.0, 0.6, 0.5)))
    return seq((0, intro), (0.95, cry * 0.9))


def read_audio(path):
    """Lee cualquier audio con sox como mono a 48 kHz."""
    with tempfile.NamedTemporaryFile(suffix=".wav") as tmp:
        subprocess.run(["sox", str(path), "-r", str(SR), "-c", "1", "-b", "16", tmp.name], check=True)
        with wave.open(tmp.name) as w:
            data = np.frombuffer(w.readframes(w.getnframes()), dtype=np.int16)
    data = data.astype(np.float64) / 32768
    return data / (np.abs(data).max() + 1e-9)


def write(sig, path, gain=1.0):
    """Normaliza a -6 dBFS, añade reverberación estéreo con sox y guarda en Ogg Vorbis."""
    sig = sig / (np.abs(sig).max() + 1e-9) * 0.5
    pcm = (np.clip(sig, -1, 1) * 32767).astype(np.int16)
    with tempfile.NamedTemporaryFile(suffix=".wav") as tmp:
        with wave.open(tmp.name, "wb") as w:
            w.setnchannels(1)
            w.setsampwidth(2)
            w.setframerate(SR)
            w.writeframes(pcm.tobytes())
        # pad deja sitio a la cola de la reverberación; el silencio final se recorta después
        subprocess.run(["sox", tmp.name, "-C", "5", "-t", "ogg", str(path),
                        "pad", "0", "1.5", "channels", "2", "reverb", "-w", "35", "50", "80", "100", "8",
                        "gain", "-n", "-3", "vol", f"{gain}", "reverse", "silence", "1", "0.01", "-60d", "fade", "0.05", "reverse"],
                       check=True)


def main():
    if sys.argv[1:2] == ["--login"]:
        cry, out = sys.argv[2], sys.argv[3]
        write(login(read_audio(cry)), out)
        return
    out = Path(sys.argv[1] if len(sys.argv) > 1 else Path(__file__).parent.parent / "files/sounds/zoroark-hisui")
    stereo = out / "stereo"
    stereo.mkdir(parents=True, exist_ok=True)
    for name, make in SOUNDS.items():
        write(make(), stereo / f"{name}.oga", GAIN.get(name, 1.0))
        print(name)
    (out / "index.theme").write_text(
        "[Sound Theme]\n"
        "Name=Zoroark de Hisui\n"
        "Comment=Campanas en la escala In e ilusiones; al iniciar sesión, el grito de Zoroark de Hisui\n"
        "Inherits=ocean,freedesktop\n"
        "Directories=stereo\n"
        "Example=theme-demo\n"
        "\n"
        "[stereo]\n"
        "OutputProfile=stereo\n"
    )


if __name__ == "__main__":
    main()

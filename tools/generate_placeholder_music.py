#!/usr/bin/env python3
"""Genera el audio placeholder de Resonante (Fase 1). Solo librería estándar.

Crea:
  assets/audio/zones/ira_placeholder.wav  — tema 140 BPM para la Zona de Ira:
      kick con transient + bajo distorsionado (dubstep agresivo casero) y un
      breakdown de 4 compases casi en silencio (para las plataformas SILENCE).
  assets/audio/effects/chime.wav          — campanada de las plataformas resonantes.

Uso:  python3 tools/generate_placeholder_music.py
"""
import math
import os
import random
import struct
import wave

SR = 44100
BPM = 140
BEAT = 60.0 / BPM      # 0.4286 s
BAR = BEAT * 4         # 1.7143 s

# Notas del bajo (Hz)
E2, G2, A2, E3 = 82.41, 98.00, 110.00, 164.81

random.seed(7)


# ------------------------------------------------------------------ síntesis --

def add_kick(buf, t, amp=1.0):
    """Kick con barrido de pitch 150→44 Hz: el 'transient' del GDD."""
    n0 = int(t * SR)
    dur = int(0.32 * SR)
    phase = 0.0
    for n in range(n0, min(len(buf), n0 + dur)):
        k = (n - n0) / SR
        freq = 44.0 + 130.0 * math.exp(-k / 0.035)
        phase += 2.0 * math.pi * freq / SR
        env = math.exp(-k / 0.10)
        buf[n] += amp * 0.85 * env * math.sin(phase)


def add_click(buf, t, amp=0.22):
    """Transient de ruido en el ataque del beat."""
    n0 = int(t * SR)
    dur = int(0.02 * SR)
    for n in range(n0, min(len(buf), n0 + dur)):
        k = (n - n0) / SR
        buf[n] += amp * math.exp(-k / 0.005) * (random.random() * 2.0 - 1.0)


def add_bass(buf, t, freq, dur=0.20, amp=0.5):
    """Bajo 'distorsionado' (GDD Zona de Ira) vía tanh + armónicos."""
    n0 = int(t * SR)
    n1 = min(len(buf), n0 + int(dur * SR))
    for n in range(n0, n1):
        k = (n - n0) / SR
        env = min(1.0, k / 0.008) * math.exp(-k / 0.16)
        s = sum(math.sin(2.0 * math.pi * freq * h * k) / h for h in range(1, 5))
        buf[n] += amp * env * math.tanh(2.2 * s)


def add_hat(buf, t, amp=0.10):
    """Hi-hat de ruido corto (denso solo en la segunda caída)."""
    n0 = int(t * SR)
    dur = int(0.05 * SR)
    for n in range(n0, min(len(buf), n0 + dur)):
        k = (n - n0) / SR
        buf[n] += amp * math.exp(-k / 0.012) * (random.random() * 2.0 - 1.0) * 0.7


def add_pad(buf, t0, t1, amp=0.014):
    """Colchón ambiental casi inaudible: el 'silencio inquietante' del breakdown."""
    freqs = [220.00, 261.63, 329.63, 440.00]  # La menor
    n0, n1 = int(t0 * SR), min(len(buf), int(t1 * SR))
    total = (n1 - n0) / SR
    for n in range(n0, n1):
        k = (n - n0) / SR
        progress = k / total
        env = min(progress / 0.25, 1.0) * min((1.0 - progress) / 0.25, 1.0)
        s = sum(math.sin(2.0 * math.pi * f * k + i) for i, f in enumerate(freqs))
        buf[n] += amp * env * s / len(freqs)


def fill_drop_bar(buf, bar_index, hats=False, dense=False):
    """Un compás de 'drop': kick en cada beat + bajo en corcheas."""
    bar_t = bar_index * BAR
    for beat_i in range(4):
        t = bar_t + beat_i * BEAT
        add_kick(buf, t)
        add_click(buf, t)
        if hats:
            add_hat(buf, t + BEAT * 0.5)
    pattern = (
        [E2, None, E2, E3, None, E2, None, G2] if not dense
        else [E2, E2, E2, E3, E2, E3, G2, A2]
    )
    for i, note in enumerate(pattern):
        if note is not None:
            add_bass(buf, bar_t + i * BEAT * 0.5, note)


# ---------------------------------------------------------------------- wav --

def write_wav(path, buf):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    frames = bytearray()
    for s in buf:
        v = max(-1.0, min(1.0, s))
        frames += struct.pack("<h", int(v * 32767))
    with wave.open(path, "w") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(bytes(frames))


def rms(buf):
    return math.sqrt(sum(s * s for s in buf) / len(buf))


# --------------------------------------------------------------------- main --

def main():
    root = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
    zones_dir = os.path.join(root, "assets", "audio", "zones")
    effects_dir = os.path.join(root, "assets", "audio", "effects")

    # ---- Tema de la Zona de Ira: 16 compases (27.4 s) ----
    # drop 8 · silencio 4 · drop denso 4
    total = int((16 * BAR + 0.5) * SR)
    buf = [0.0] * total
    for bar in range(8):
        fill_drop_bar(buf, bar)
    add_pad(buf, 8 * BAR, 12 * BAR)                       # breakdown
    for bar in range(12, 16):
        fill_drop_bar(buf, bar, hats=True, dense=True)

    # Master: soft-clip y normalización.
    peak = max(abs(s) for s in buf)
    gain = 0.89 / peak
    buf = [math.tanh(1.15 * s * gain) for s in buf]
    track_path = os.path.join(zones_dir, "ira_placeholder.wav")
    write_wav(track_path, buf)

    drop_rms = rms(buf[: int(8 * BAR * SR)])
    silence_rms = rms(buf[int(8.5 * BAR * SR): int(11.5 * BAR * SR)])
    print(f"[ira_placeholder.wav] {len(buf) / SR:.1f}s · RMS drop={drop_rms:.4f} "
          f"RMS silencio={silence_rms:.4f} · ratio={drop_rms / max(silence_rms, 1e-9):.1f}x")

    # ---- Chime de plataformas resonantes ----
    chime_len = int(1.4 * SR)
    chime = [0.0] * chime_len
    partials = [(880.0, 0.50), (1318.5, 0.25), (1760.0, 0.12)]
    for n in range(chime_len):
        k = n / SR
        env = min(1.0, k / 0.004) * math.exp(-k / 0.45)
        s = sum(a * math.sin(2.0 * math.pi * f * k) for f, a in partials)
        chime[n] = 0.6 * env * s
    chime_path = os.path.join(effects_dir, "chime.wav")
    write_wav(chime_path, chime)
    print(f"[chime.wav] {chime_len / SR:.1f}s OK")

    print("Listo. Recuerda: es placeholder — reemplázalo por música real (GDD §8).")


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""Generate all audio for Qavex Backgammon Gold with numpy (offline).

BGM (2): bgm_theme.wav, bgm_calm.wav   (8 s seamless-ish loops, 22050 Hz)
SFX (12): dice_roll, checker_move, hit, bearoff, double, win, button,
          cube_decline, gammon, tick, turn, lose
"""
import os
import wave
import numpy as np

SR = 22050
ROOT = os.path.expanduser(
    "~/workspace/qavex-games/games/qavexbackgammongold")
AUD = os.path.join(ROOT, "assets/audio")
os.makedirs(AUD, exist_ok=True)

rng = np.random.default_rng(20261010)


def write(name, data):
    data = np.clip(data, -1, 1)
    pcm = (data * 32767).astype(np.int16)
    path = os.path.join(AUD, name)
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm.tobytes())
    print(name, f"{os.path.getsize(path)//1024}KB")


def secs(s):
    return int(s * SR)


def tone(freq, dur, amp=0.5, decay=4.0, sr=SR, kind="sine"):
    n = secs(dur)
    t = np.arange(n) / sr
    if kind == "sine":
        x = np.sin(2 * np.pi * freq * t)
    elif kind == "tri":
        x = 2 * np.abs(2 * ((freq * t) % 1) - 1) - 1
    elif kind == "square":
        x = np.sign(np.sin(2 * np.pi * freq * t))
    env = np.exp(-decay * t)
    return (amp * x * env).astype(np.float64)


def noise(dur, amp=0.4, decay=6.0, low=0.0):
    n = secs(dur)
    x = rng.standard_normal(n)
    t = np.arange(n) / SR
    env = np.exp(-decay * t)
    y = amp * x * env
    if low > 0:  # crude lowpass via moving average
        k = int(low)
        y = np.convolve(y, np.ones(k) / k, mode="same")
    return y


def mix(*parts, at=None):
    """Overlay parts; at = list of start offsets in seconds."""
    at = at or [0.0] * len(parts)
    total = 0
    for p, off in zip(parts, at):
        total = max(total, secs(off) + len(p))
    out = np.zeros(total)
    for p, off in zip(parts, at):
        i = secs(off)
        out[i:i + len(p)] += p
    return out


# ---------------- SFX ----------------
def sfx_dice_roll():
    clicks = []
    for i in range(7):
        clicks.append(noise(0.05, amp=0.5, decay=40.0))
    return mix(*clicks, at=[i * 0.07 for i in range(7)])


def sfx_checker_move():
    return mix(tone(190, 0.12, amp=0.6, decay=30),
               noise(0.06, amp=0.25, decay=40.0))


def sfx_hit():
    return mix(tone(320, 0.15, amp=0.7, decay=22),
               tone(160, 0.2, amp=0.5, decay=18),
               noise(0.08, amp=0.3, decay=35.0))


def sfx_bearoff():
    return mix(tone(660, 0.18, amp=0.5, decay=8),
               tone(880, 0.25, amp=0.5, decay=8), at=[0, 0.12])


def sfx_double():
    return mix(tone(90, 0.35, amp=0.8, decay=10),
               tone(1244, 0.5, amp=0.25, decay=6),
               noise(0.1, amp=0.3, decay=30.0))


def sfx_win():
    notes = [523.25, 659.25, 783.99, 1046.5]
    parts = [tone(f, 0.4, amp=0.45, decay=5) for f in notes]
    return mix(*parts, at=[i * 0.14 for i in range(4)])


def sfx_lose():
    notes = [392.0, 329.63, 261.63]
    parts = [tone(f, 0.45, amp=0.45, decay=4, kind="tri") for f in notes]
    return mix(*parts, at=[i * 0.2 for i in range(3)])


def sfx_button():
    return mix(tone(880, 0.05, amp=0.4, decay=60),
               noise(0.03, amp=0.2, decay=80.0))


def sfx_cube_decline():
    return mix(tone(140, 0.4, amp=0.6, decay=6, kind="square"),
               tone(105, 0.4, amp=0.5, decay=6, kind="square"))


def sfx_gammon():
    notes = [659.25, 783.99, 1046.5, 1318.5, 1567.98]
    parts = [tone(f, 0.35, amp=0.4, decay=6) for f in notes]
    return mix(*parts, at=[i * 0.1 for i in range(5)])


def sfx_tick():
    return tone(1200, 0.06, amp=0.4, decay=50)


def sfx_turn():
    n = secs(0.18)
    t = np.arange(n) / SR
    sweep = np.sin(2 * np.pi * (300 + 900 * t / 0.18) * t) * 0.3
    env = np.sin(np.pi * t / 0.18)  # swell
    return sweep * env


# ---------------- BGM ----------------
def _pad_chord(freqs, dur, amp=0.16):
    parts = []
    for f in freqs:
        parts.append(tone(f, dur, amp=amp, decay=0.35))
        parts.append(tone(f * 2, dur, amp=amp * 0.35, decay=0.4))
    return np.sum(parts, axis=0)


def bgm_theme():
    # Warm golden loop: Am - F - C - G progression, 2 s per chord.
    prog = [[220.0, 261.63, 329.63], [174.61, 220.0, 261.63],
            [130.81, 164.81, 196.0], [98.0, 146.83, 196.0]]
    seq = np.concatenate([_pad_chord(c, 2.0) for c in prog])
    # gentle fade in/out edges for seamless-ish loop
    n = len(seq)
    edge = secs(0.4)
    fade = np.ones(n)
    fade[:edge] = np.linspace(0, 1, edge)
    fade[-edge:] = np.linspace(1, 0, edge)
    # soft shaker pulse
    pulse = np.zeros(n)
    for i in range(16):
        s = i * secs(0.5)
        e = min(n, s + secs(0.05))
        pulse[s:e] += rng.standard_normal(e - s) * 0.05
    return (seq * fade + pulse) * 0.9


def bgm_calm():
    # Slow airy loop: C - Am - F - G with long swells.
    prog = [[130.81, 164.81, 196.0], [110.0, 130.81, 164.81],
            [87.31, 110.0, 130.81], [98.0, 123.47, 146.83]]
    seq = np.concatenate([_pad_chord(c, 2.0, amp=0.12) for c in prog])
    n = len(seq)
    edge = secs(0.6)
    fade = np.ones(n)
    fade[:edge] = np.linspace(0, 1, edge)
    fade[-edge:] = np.linspace(1, 0, edge)
    return seq * fade


if __name__ == "__main__":
    write("bgm_theme.wav", bgm_theme())
    write("bgm_calm.wav", bgm_calm())
    write("dice_roll.wav", sfx_dice_roll())
    write("checker_move.wav", sfx_checker_move())
    write("hit.wav", sfx_hit())
    write("bearoff.wav", sfx_bearoff())
    write("double.wav", sfx_double())
    write("win.wav", sfx_win())
    write("button.wav", sfx_button())
    write("cube_decline.wav", sfx_cube_decline())
    write("gammon.wav", sfx_gammon())
    write("tick.wav", sfx_tick())
    write("turn.wav", sfx_turn())
    write("lose.wav", sfx_lose())
    print("done")

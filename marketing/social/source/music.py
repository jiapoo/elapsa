"""Original background music for Elapsa's social videos, written in code (no samples).

    python3 music.py <out.wav> <length s> <scene-change times s, comma-separated> <end-card start s>

A light, upbeat loop at 100 bpm in C major (C - G - Am - F): a soft pad, a plucked
arpeggio, and from the first app scene a gentle kick and hi-hat. A two-note chime marks
each scene change, and the last chord rings out under the end card. 44.1 kHz stereo.
"""
import math
import random
import struct
import sys
import wave

OUT = sys.argv[1]
LENGTH = float(sys.argv[2])
CHANGES = [float(x) for x in sys.argv[3].split(",") if x]
END = float(sys.argv[4])
RATE = 44100
N = int(LENGTH * RATE)
BPM = 100
BEAT = 60 / BPM
BAR = 4 * BEAT
random.seed(7)

L = [0.0] * N
R = [0.0] * N


def hz(midi):
    return 440.0 * 2 ** ((midi - 69) / 12)


def add(start, samples, pan=0.0, gain=1.0):
    """Mix a mono list into the stereo buffer at time start (s); pan -1..1."""
    i0 = int(start * RATE)
    lg = gain * math.cos((pan + 1) * math.pi / 4)
    rg = gain * math.sin((pan + 1) * math.pi / 4)
    for k, s in enumerate(samples):
        i = i0 + k
        if 0 <= i < N:
            L[i] += s * lg
            R[i] += s * rg


def tone(freq, dur, attack=0.01, decay=None, shape="sine"):
    n = int(dur * RATE)
    out = []
    for k in range(n):
        t = k / RATE
        ph = 2 * math.pi * freq * t
        if shape == "tri":
            v = 2 / math.pi * math.asin(math.sin(ph))
        else:
            v = math.sin(ph) + 0.25 * math.sin(2 * ph)
        env = min(1.0, t / attack) if attack else 1.0
        if decay:
            env *= math.exp(-t / decay)
        else:
            env *= min(1.0, (dur - t) / 0.3)  # release
        out.append(v * env)
    return out


# C, G, Am, F as MIDI notes (pad voicing) and arpeggio tones
CHORDS = [
    ([48, 55, 60, 64], [60, 64, 67, 72]),   # C
    ([43, 55, 59, 62], [59, 62, 67, 71]),   # G
    ([45, 57, 60, 64], [57, 60, 64, 69]),   # Am
    ([41, 53, 57, 60], [57, 60, 65, 69]),   # F
]
BODY_START = CHANGES[0] if CHANGES else 0.0

bar = 0
t = 0.0
while t < LENGTH:
    pad, arp = CHORDS[bar % 4]
    if t >= END:  # end card: hold C major and let it ring
        pad, arp = CHORDS[0]
    dur = min(BAR, LENGTH - t)
    for m in pad:
        add(t, tone(hz(m), dur, attack=0.35), gain=0.055)
    # eighth-note pluck arpeggio
    pattern = [0, 1, 2, 3, 2, 1, 2, 3]
    for j, idx in enumerate(pattern):
        st = t + j * BEAT / 2
        if st >= LENGTH or st >= END + BAR:
            break
        add(st, tone(hz(arp[idx]), 0.45, attack=0.004, decay=0.16, shape="tri"),
            pan=(-0.35 if j % 2 else 0.35), gain=0.11)
    # drums from the first app scene until the end card
    for b in range(4):
        st = t + b * BEAT
        if BODY_START <= st < END:
            if b in (0, 2):  # kick: falling sine
                n = int(0.18 * RATE)
                kick = [math.sin(2 * math.pi * (50 + 70 * math.exp(-k / (0.03 * RATE)))
                                 * k / RATE) * math.exp(-k / (0.06 * RATE)) for k in range(n)]
                add(st, kick, gain=0.35)
            hs = st + BEAT / 2  # hi-hat on the off-beat
            n = int(0.04 * RATE)
            hat = [(random.random() * 2 - 1) * math.exp(-k / (0.008 * RATE)) for k in range(n)]
            add(hs, hat, pan=0.2, gain=0.05)
    bar += 1
    t += BAR

# chime at each scene change (E6 then B6)
for c in CHANGES + [END]:
    add(c - 0.02, tone(hz(88), 0.9, attack=0.003, decay=0.28), pan=-0.1, gain=0.09)
    add(c + 0.07, tone(hz(95), 0.9, attack=0.003, decay=0.25), pan=0.1, gain=0.06)

# fade in 0.4 s, fade out over the last 1.2 s, then normalise to -1 dBFS
fi, fo = int(0.4 * RATE), int(1.2 * RATE)
for i in range(N):
    g = min(1.0, i / fi) * min(1.0, (N - i) / fo)
    L[i] *= g
    R[i] *= g
peak = max(max(abs(x) for x in L), max(abs(x) for x in R)) or 1.0
scale = 0.89 / peak
with wave.open(OUT, "wb") as w:
    w.setnchannels(2)
    w.setsampwidth(2)
    w.setframerate(RATE)
    w.writeframes(b"".join(struct.pack("<hh", int(L[i] * scale * 32767),
                                       int(R[i] * scale * 32767)) for i in range(N)))
print(f"{OUT}: {LENGTH}s, chimes at {CHANGES + [END]}")

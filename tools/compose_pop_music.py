"""Create an original pop-rock loop using only procedural synthesis.

No recorded guitar or external samples. Rebuild assets/audio/pop_guitar_loop.wav
with Python 3; notes wrap into the start so the eight-bar loop remains continuous.
"""
from array import array
from math import exp, pi, sin, tanh
from pathlib import Path
from random import Random
import sys
import wave

RATE = 22050
BPM = 112
BEAT = 60.0 / BPM
FRAMES = round(32 * BEAT * RATE)


def compose(destination: Path) -> None:
    left = array('f', [0.0]) * FRAMES
    right = array('f', [0.0]) * FRAMES
    random = Random(271828)

    def mix(index: int, sample: float, pan: float = 0.0) -> None:
        index %= FRAMES
        left[index] += sample * (1.0 - pan * 0.45)
        right[index] += sample * (1.0 + pan * 0.45)

    def note(pitch: int, beat: float, duration: float, gain: float,
             voice: str, pan: float = 0.0) -> None:
        start = round(beat * BEAT * RATE)
        length = duration * BEAT
        frequency = 440.0 * 2.0 ** ((pitch - 69) / 12.0)
        tail = 0.18 if voice == 'guitar' else 0.10
        for i in range(round((length + tail) * RATE)):
            t = i / RATE
            phase = 2.0 * pi * frequency * t
            attack = min(1.0, t / (0.007 if voice == 'guitar' else 0.012))
            release = exp(-max(0.0, t - length) / (tail / 5.0))
            if voice == 'guitar':
                # Bright picked-string harmonics through a gentle amplifier-like
                # saturation; this is synthesized, not a guitar recording.
                tone = (sin(phase) + 0.48 * sin(2 * phase) * exp(-t * 1.2)
                        + 0.24 * sin(3 * phase) * exp(-t * 2.4)
                        + 0.12 * sin(4 * phase) * exp(-t * 3.4))
                tone = tanh(tone * 1.5) / tanh(1.5)
                envelope = attack * exp(-t * 2.0) * release
            else:
                tone = sin(phase) + 0.22 * sin(2 * phase)
                envelope = attack * exp(-t * 2.5) * release
            mix(start + i, gain * tone * envelope, pan)

    def drum(beat: float, kind: str, gain: float) -> None:
        start = round(beat * BEAT * RATE)
        duration = {'kick': 0.24, 'snare': 0.19, 'hat': 0.055}[kind]
        phase = 0.0
        previous = 0.0
        for i in range(round(duration * RATE)):
            t = i / RATE
            noise = random.uniform(-1.0, 1.0)
            if kind == 'kick':
                frequency = 45.0 + 110.0 * exp(-t * 28.0)
                phase += 2.0 * pi * frequency / RATE
                sample = sin(phase) * exp(-t * 17.0)
            elif kind == 'snare':
                sample = (0.65 * noise + 0.35 * sin(2.0 * pi * 185.0 * t)) * exp(-t * 22.0)
            else:
                sample = (noise - previous) * 0.5 * exp(-t * 85.0)
            previous = noise
            mix(start + i, sample * gain, 0.12 if kind == 'hat' else 0.0)

    # An original, light four-chord pop progression with a syncopated melody.
    chords = [(50, 57, 62, 65), (46, 53, 58, 62),
              (41, 48, 57, 60), (48, 55, 60, 64)]
    riffs = [
        [(74, 0.0, .6), (77, .75, .45), (76, 1.5, .45), (69, 2.5, .7), (72, 3.5, .35)],
        [(70, 0.0, .6), (74, 1.0, .45), (77, 1.75, .55), (74, 2.75, .8)],
        [(72, 0.0, .5), (69, .75, .5), (65, 1.5, .8), (69, 2.75, .4), (72, 3.25, .4)],
        [(67, 0.0, .6), (72, 1.0, .5), (76, 1.75, .55), (74, 2.75, .4), (72, 3.25, .5)],
    ]
    for bar in range(8):
        chord = chords[bar % 4]
        base = bar * 4.0
        for offset in (0.0, 1.5, 2.0, 3.5):
            note(chord[0] - 12, base + offset, 0.65, 0.16, 'bass')
        for offset in (0.0, 1.5, 2.5, 3.5):
            for i, pitch in enumerate(chord[1:]):
                note(pitch, base + offset + i * 0.025, 0.48, 0.055, 'guitar', -0.4)
        for pitch, offset, duration in riffs[bar % 4]:
            note(pitch, base + offset, duration, 0.16, 'guitar', 0.35)
        for offset in (0.0, 2.0, 3.5):
            drum(base + offset, 'kick', 0.23)
        for offset in (1.0, 3.0):
            drum(base + offset, 'snare', 0.14)
        for tick in range(8):
            drum(base + tick * 0.5, 'hat', 0.052 if tick % 2 else 0.065)

    # A short cross-channel echo wraps naturally across the loop boundary.
    dry_left, dry_right = left[:], right[:]
    for delay, gain in ((0.18, 0.12), (0.36, 0.06)):
        offset = round(delay * RATE)
        for i in range(FRAMES):
            left[i] += dry_right[(i - offset) % FRAMES] * gain
            right[i] += dry_left[(i - offset) % FRAMES] * gain
    peak = max(max(abs(v) for v in left), max(abs(v) for v in right))
    samples = array('h')
    for i in range(FRAMES):
        samples.append(round(tanh(left[i] / peak) * 24500))
        samples.append(round(tanh(right[i] / peak) * 24500))
    if sys.byteorder != 'little':
        samples.byteswap()
    destination.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(destination), 'wb') as output:
        output.setparams((2, 2, RATE, FRAMES, 'NONE', 'not compressed'))
        output.writeframes(samples.tobytes())
    print(f'Composed {destination}: {FRAMES / RATE:.2f}s, {BPM} BPM, stereo PCM16')


if __name__ == '__main__':
    compose(Path(__file__).resolve().parents[1] / 'assets/audio/pop_guitar_loop.wav')

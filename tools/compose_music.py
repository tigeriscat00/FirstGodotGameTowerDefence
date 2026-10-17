"""Compose the project's original, looping prototype music. No external samples.

Run with Python 3 to rebuild assets/audio/kingdom_theme.wav deterministically.
Only standard-library modules are required. The loop is eight bars at 96 BPM.
"""

from array import array
from math import exp, pi, sin, tanh
from pathlib import Path
import sys
import wave


SAMPLE_RATE = 22050
BEAT = 60.0 / 96.0
DURATION = 32 * BEAT
FRAME_COUNT = round(SAMPLE_RATE * DURATION)


def compose(destination: Path) -> None:
    left = array("f", [0.0]) * FRAME_COUNT
    right = array("f", [0.0]) * FRAME_COUNT

    def note(midi: int, beat: float, beats: float, gain: float, pan: float,
             voice: str = "harp") -> None:
        frequency = 440.0 * 2 ** ((midi - 69) / 12)
        start = round(beat * BEAT * SAMPLE_RATE)
        length = beats * BEAT
        tail = 0.9 if voice == "harp" else 0.25
        count = round((length + tail) * SAMPLE_RATE)
        for index in range(count):
            time = index / SAMPLE_RATE
            phase = 2 * pi * frequency * time
            attack = min(1.0, time / 0.012)
            release = exp(-max(0.0, time - length) / (tail / 6))
            if voice == "harp":
                envelope = attack * exp(-time * 3.2) * release
                tone = sin(phase) + 0.28 * sin(phase * 2) + 0.10 * sin(phase * 3)
            elif voice == "pad":
                envelope = min(1.0, time / 0.2) * release
                tone = 0.8 * sin(phase) + 0.12 * sin(phase * 2)
            else:
                envelope = attack * exp(-time * 1.8) * release
                tone = sin(phase) + 0.13 * sin(phase * 2)
            sample = gain * envelope * tone
            position = (start + index) % FRAME_COUNT
            left[position] += sample * (1 - pan * 0.4)
            right[position] += sample * (1 + pan * 0.4)

    # D minor / B-flat / F / C, followed by a resolving second phrase.
    chords = [(50, 57, 62, 65), (46, 53, 58, 62), (41, 48, 57, 60),
              (48, 55, 60, 64), (50, 57, 62, 65), (46, 53, 58, 62),
              (48, 55, 60, 64), (50, 57, 62, 65)]
    melody = [[(74, 0, 1), (69, 1, 1), (77, 2, 1), (76, 3, 1)],
              [(74, 0, 1.5), (72, 2, 1), (69, 3, 1)],
              [(72, 0, 1), (69, 1, 1), (67, 2, 1), (65, 3, 1)],
              [(67, 0, 2), (72, 2, 1), (76, 3, 1)],
              [(77, 0, 1.5), (76, 2, 1), (74, 3, 1)],
              [(74, 0, 1), (72, 1, 1), (70, 2, 1), (69, 3, 1)],
              [(67, 0, 1), (72, 1, 1), (76, 2, 1), (72, 3, 1)],
              [(69, 0, 1), (65, 1, 1), (74, 2, 1.5)]]
    for bar, chord in enumerate(chords):
        beat = bar * 4
        note(chord[0] - 12, beat, 3.8, 0.085, 0, "bass")
        for pitch in chord[1:]:
            note(pitch, beat, 3.65, 0.026, -0.2, "pad")
        for tick, chord_index in enumerate([1, 2, 3, 2, 1, 2, 3, 2]):
            note(chord[chord_index], beat + tick * 0.5, 0.45, 0.067,
                 -0.6 if tick % 2 == 0 else 0.6)
        for pitch, offset, duration in melody[bar]:
            note(pitch, beat + offset, duration, 0.12, 0.15)

    # Circular stereo echo preserves tails across the wrap rather than cutting them.
    original_left, original_right = left[:], right[:]
    for delay, gain in [(0.1875, 0.16), (0.375, 0.08)]:
        offset = round(delay * SAMPLE_RATE)
        for index in range(FRAME_COUNT):
            left[index] += original_right[(index - offset) % FRAME_COUNT] * gain
            right[index] += original_left[(index - offset) % FRAME_COUNT] * gain

    peak = max(max(abs(value) for value in left), max(abs(value) for value in right))
    samples = array("h")
    for index in range(FRAME_COUNT):
        samples.append(round(tanh(left[index] / peak) * 24500))
        samples.append(round(tanh(right[index] / peak) * 24500))
    if sys.byteorder != "little":
        samples.byteswap()
    destination.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(destination), "wb") as output:
        output.setparams((2, 2, SAMPLE_RATE, FRAME_COUNT, "NONE", "not compressed"))
        output.writeframes(samples.tobytes())
    print(f"Composed {destination}: {DURATION:.1f}s, stereo PCM16, {SAMPLE_RATE} Hz")


if __name__ == "__main__":
    compose(Path(__file__).resolve().parents[1] / "assets/audio/kingdom_theme.wav")

"""Synthesize original game effects using only Python's standard library.

No recordings, voice models, external samples or audio generation services.
Run to rebuild assets/audio/sfx/*.wav deterministically.
"""
from array import array
from math import sin, cos, pi, exp, tanh
from pathlib import Path
from random import Random
import wave

RATE = 22050


def save(name, duration, voice):
    rng = Random(name)
    samples = []
    phase = 0.0
    noise_low = 0.0
    for i in range(round(RATE * duration)):
        t = i / RATE
        noise = rng.uniform(-1, 1)
        noise_low = noise_low * .88 + noise * .12
        edge = min(1, t / .008, (duration - t) / .025)
        if voice == 'click':
            s = (.65 * sin(2*pi*920*t) + .3*noise) * exp(-t*65)
        elif voice == 'shot':
            s = (.6*sin(2*pi*(180*t-120*t*t)) + .32*noise*exp(-t*20)) * exp(-t*14)
            s += .25*sin(2*pi*740*t)*exp(-t*24)
        elif voice == 'hit':
            s = (.6*sin(2*pi*88*t) + .5*noise_low + .2*noise) * exp(-t*23)
        elif voice == 'freeze':
            s = 0.0
            for pitch in [1250, 1680, 2230, 2900]:
                s += .18*sin(2*pi*pitch*t)*exp(-t*6)
            s += .32*noise*(sin(pi*t/duration)**2)*exp(-t*2)
        elif voice == 'upgrade':
            s = 0.0
            for n, freq in enumerate([440, 554.37, 659.25, 880]):
                age = t - n*.10
                if age >= 0:
                    s += .24*sin(2*pi*freq*age)*exp(-age*7)
        else:
            # A rough voiced source with mouth-resonance formants and breath.
            f0 = (86 if voice == 'groan_a' else 73) - t*8 + 2.8*sin(t*17) + noise_low*4
            phase += 2*pi*f0/RATE
            s = 0.0
            for harmonic in range(1, 25):
                freq = harmonic*f0
                formants = .85*exp(-((freq-390)/170)**2) + .38*exp(-((freq-1050)/300)**2)
                s += sin(phase*harmonic) * (.10/harmonic + formants*.14)
            envelope = sin(pi*t/duration)**.8
            s = (tanh(s*2.8)*.65 + noise_low*.5) * envelope * (.85+.15*sin(t*23))
        samples.append(s * max(0, edge))
    peak = max(abs(s) for s in samples) or 1
    pcm = array('h', (round(s / peak * .72 * 32767) for s in samples))
    destination = Path(__file__).resolve().parents[1] / 'assets/audio/sfx' / (name+'.wav')
    destination.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(destination), 'wb') as out:
        out.setnchannels(1)
        out.setsampwidth(2)
        out.setframerate(RATE)
        out.writeframes(pcm.tobytes())
    print(f'{destination.name}: {duration:.2f}s')


if __name__ == '__main__':
    for name, duration, voice in [
        ('ui_click', .09, 'click'), ('ballista', .34, 'shot'),
        ('impact', .20, 'hit'), ('freeze', .85, 'freeze'),
        ('upgrade', .95, 'upgrade'),
        ('groan_a', 1.65, 'groan_a'), ('groan_b', 1.95, 'groan_b'),
    ]:
        save(name, duration, voice)

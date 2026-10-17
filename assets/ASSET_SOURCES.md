# Asset sources

## Original synthesized sound effects - 2026-10-17

`assets/audio/sfx/`: ui_click.wav, ballista.wav, impact.wav, freeze.wav,
upgrade.wav, groan_a.wav and groan_b.wav. Created locally with original code in
`tools/compose_sfx.py`, using Python standard-library oscillators, filtered noise
and formant-style voice synthesis. No voice recording, external samples or audio
generation service was used. Mono PCM WAV, 22050 Hz, 16-bit; source peaks capped
at 72% full scale before in-game gain. Rebuild with the script; no stock license.

## Realistic fantasy art pass - 2026-10-17

Created for this project with the built-in image generation tool from original
text prompts in `generated/REALISTIC_ART_PROMPTS.md`. No third-party artwork was
used. All four PNGs have genuine RGBA transparency and are stored in this repo.
Original prototype sprites are retained. Source pixels were copied unchanged;
Godot handles scaling, frame regions and foot-baseline alignment.

| Saved file | Active use | Pixel size |
| --- | --- | --- |
| `assets/generated/realistic_castle.png` | Tutorial castle and menu background | 887 x 1774 |
| `assets/generated/realistic_tower.png` | Standard tower and shop picture | 1254 x 1254 |
| `assets/generated/realistic_tower_upgraded.png` | Distinct twin-ballista upgraded tower | 1254 x 1254 |
| `assets/generated/realistic_zombie_walk.png` | Eight walk poses, 4 columns x 2 rows | 1774 x 887 |

Upgrade ring, glow, particles and label are original Godot effects in tower.gd.
No external animation service, stock license or new runtime is involved.

## UI icons (2026-10-17)

Victory crown, rays, fireworks and confetti are original Godot drawing code in
`scripts/ui/victory_celebration.gd`. No external artwork or license dependency.

Tutorial sparkle/glow cues are original Godot drawing code in
`scripts/ui/tutorial_cue.gd`; no external asset or license dependency.

`assets/ui/`: original code-drawn SVG cart, gear, snowflake, coin and shield icons
created for this project. No external artwork or license dependency. The owner's
Valorant screenshot informed HUD placement and hierarchy; no Valorant art was copied.

## Generated game art - 2026-10-15

Created for this project with the built-in image_gen tool, using original text
prompts. No third-party reference artwork was supplied. These are AI-generated
outputs, not licensed stock packs; no separate third-party stock license applies.
Keep this provenance with the project; no exclusive-rights claim is made here.

| File | Use | Format |
| --- | --- | --- |
| generated/tower.png | Standard defensive tower | 1254 x 1254 RGBA PNG |
| generated/zombie.png | Level-1 enemy | 1254 x 1254 RGBA PNG |
| generated/kingdom.png | Kingdom gatehouse | 1254 x 1254 RGBA PNG |
| generated/sphinx.png | Guide dialogue portrait | 1254 x 1254 RGBA PNG |

All four files have real alpha transparency. Generated outputs were copied into
this workspace without editing pixels; Godot sets display scale and node offsets.
Full final prompts are recorded in generated/PROMPTS.md. Intended art direction:
hand-painted storybook, warm stone, blue/teal accents, three-quarter overhead view.
These are static single-frame assets, not verified animation or terrain sheets.
The generator returned 1254-square images despite the requested 1024-square size;
scripts calculate display scale from actual texture width.

Sprite display: tower 112 px wide, zombie 86 px, gate 150 px. The semiboss variant
is 114 px wide, with a code-drawn gold ring and text label; it reuses the unmodified
zombie PNG and has no new generated image file. Node positions anchor actors to
wall sockets / road; sprite offsets align their bases. Sphinx is a
130-square portrait in a TextureRect. Small procedural movement bob, attack beams,
Freeze overlay and other feedback are drawn by Godot.

UI uses Godot's built-in controls/font. Route, grass, wall, sockets, bars and range
previews are code-drawn project artwork; no downloaded assets are used.

## Castle layout art - 2026-10-17

- generated/castle_overhead.png: active wider overhead castle with courtyard and
  a left-facing entrance. 887 x 1774 RGBA; true alpha transparency; displayed at
  276 x 552 logical pixels along the right edge of the lawn after the owner's
  request for a smaller wall. Scaling is done by Godot; source pixels unchanged.
- generated/castle_wall.png: tall facade option generated before the owner asked
  for a wider overhead view; retained as an unused source variant. 768 x 2048 RGBA.
- Both were created with built-in image_gen, using this project's kingdom.png as
  the style reference. No new third-party assets or references were introduced.
- Full prompts are in generated/CASTLE_PROMPTS.md. Originals were copied without
  pixel edits. Grass/grid/hover cells are drawn by Godot. Standard tower art is
  now rendered at 68 px to fit the grid; original sprite files are preserved.

## Original synthesized background music - 2026-10-15

- File: audio/kingdom_theme.wav; 20 seconds, eight bars at 96 BPM, stereo
  16-bit PCM, 22050 Hz. Loops across menu, tutorial and restart at -12 dB.
- Source: original melody and arrangement synthesized by project code in
  tools/compose_music.py using additive tones, envelopes and circular stereo echo.
- No music-generation service, recordings, external samples, or third-party
  tracks were used. No external music attribution/license is required.
- This is a simple synthesized prototype score; no sound effects were added.

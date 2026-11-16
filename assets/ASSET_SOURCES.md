# Asset sources

## Stage 2

The armored zombie uses an eight-frame plate armor walk created with the
built-in ImageGen tool, with the regular zombie sheet as a pose reference.
Both tower sprites were also created with the built-in ImageGen tool and
packaged as transparent PNGs for the shop and battlefield.
The Minion Tower reuses the existing kingdom minion sprite.

- `assets/generated/realistic_minion_tower.png` · 302 × 384 px
- `assets/generated/realistic_treadmill_tower.png` · 384 × 114 px
- `assets/generated/realistic_armored_zombie_walk.png` · 1280 × 640 px, 4 × 2 frames with aligned foot baselines

### ImageGen prompts

**Armored Zombie**

> Refit this exact eight-frame 2D zombie walking sprite sheet with a complete suit of realistically rendered late-medieval plate armor. The provided image is the pose, orientation, layout, and art style reference. Preserve the 4-column by 2-row regular equal-size grid, reading order, pose progression, right-facing silhouettes, hunched zombie body language, foot positions, clear gutters, and full figure in every cell. Each frame depicts the same zombie completely covered from head to toe in dark weathered forged steel: fully enclosed close helmet, realistic narrow open horizontal visor slit with pale small zombie eyes peeking through, solid lower faceplate, covered neck, overlapping articulated gorget and pauldrons, breastplate, fauld, gauntlets covering fingers, plated thighs, greaves and steel sabatons. Cover every exposed bit of skin except the eyes behind the visor. Steel highlights and subdued warm grime for readable shapes at game size, minor dents, restrained tarnish. No weapon, no shield, no fabric cape, no glow effects around the helmet, no text. Eight poses only, all boots and helmets fully inside their own cell, margins and cell spacing matching the reference; no frames touch one another. Actual transparent alpha, no cast shadows, no floor or background. Landscape 2:1 sprite sheet.

**Minion Tower**

> Transparent RPG game sprite for a 2D medieval zombie tower defense. A compact minion recruitment barracks in a single readable silhouette: realistically weathered tan-grey stone tower, dark oak beams, muted royal blue slate roof and small matching banner, prominent open arched doorway at lower front-left near ground with warm interior light, a small worn threshold. Three-quarter elevated front view with a little roof and right side visible, like a realistic painted 3D medieval strategy game asset. Neutral daylight from upper left, detailed physical materials, restrained colors. Compact square footprint and squat tower silhouette, distinct roof and door legible at 85px. Center the fully visible building, use most of square canvas, with tight transparent border. Actual transparent alpha background, no floor plane, no detached shadows, no people, no text.

**Treadmill Tower**

> Transparent RPG game sprite for a 2D medieval zombie tower defense. One compact medieval treadmill trap seen in three-quarter elevated front view, a low horizontal walk-through machine pointing left to right, broad dark iron-and-oak running belt stretching across the center with recognizable crosswise slats, open low beveled entry and exit at the left and right, paired stone and riveted bronze side supports, a restrained exposed iron sprocket along the front side. The belt is near ground level, with clear open approaches at both ends. Weathered slate-grey, burnished bronze and dark oak, neutral daylight from upper left, realistic hand-painted 3D strategy game asset, readable silhouette at 100px wide. Center the fully visible object and keep a tight margin with actual transparent alpha background. No ground plane, no detached shadows, no people, no labels.

## Defeat lightning - 2026-11-15

Lightning bolts and flashes are original Godot drawing effects in
`scripts/ui/defeat_screen.gd`; no new external artwork or sound was used.

## Stage 1 prototype visuals - 2026-10-26

Boss rings and fire and brick projectiles are drawn
with original Godot geometry; other stage characters reuse the existing assets
listed below with color tints. These are provisional visuals, with no new
third-party assets.

## Brick Tower upgrade and minion - 2026-10-26

`generated/realistic_brick_recruiter.png` and `generated/kingdom_minion.png`
were created with the built-in image tool, with transparent backgrounds. The
upgraded tower was edited from the existing catapult art; the guard is a newly
generated single pose. Original images remain unchanged.

Tower prompt: "Edit this existing transparent tower defense game sprite. Keep
the same grey stone, blue banner, exact general shape, size and elevated
three-quarter viewpoint. Upgrade it to a minion-summoning brick catapult: retain
a clearly visible wooden catapult basket with several red bricks on the roof,
and add a small distinctive blue-and-gold rally flag or guard pennant near it,
plus modest reinforced timber details. Must remain a realistic medieval fantasy
tower, not orange, no characters, no text, transparent background, isolated
entire tower."

Minion prompt: "Use case: stylized-concept. Asset: single 2D tower-defense
defender minion sprite. One friendly human medieval castle guard facing LEFT,
whole body in a modest walking pose holding a short sword and small round shield,
simple steel helmet and blue tabard, realistic painted medieval fantasy
strategy-game style matching gray castle towers. Slightly elevated three-quarter
side view, clear readable silhouette at 45 pixels tall, restrained blue and
weathered steel colors. Family-friendly, no gore, no text, no ground or shadows,
no other objects or characters. Isolated on genuinely transparent background
with padding."

## Minion walk cycle - 2026-10-26

`generated/kingdom_minion_walk_v2.png` is the active transparent 1774 × 887,
4-by-2 walking sheet, generated with the built-in image tool using the existing
`kingdom_minion.png` as reference. `kingdom_minion_walk.png` is an earlier,
unused generated candidate retained for reference. Godot aligns the active
frames by measured foot and center offsets; neither source PNG was edited.

Final prompt: "Production game spritesheet with a transparent background. 4
columns × 2 rows, exactly 8 equal cells. In the CENTER of each cell place a SMALL
full-body version of the blue medieval guard in the reference, facing left,
holding sword and shield. The guard AND his entire sword and shield must fit
within the CENTER HALF of each cell, leaving VERY WIDE EMPTY TRANSPARENT SPACE
on all four sides. No body part, sword, shield or shadow is allowed near a cell
edge. Eight distinct consecutive walking poses: legs alternate stepping forward
and back, knees bend; sword and shield arms visibly swing. Maintain same guard
identity, realistic painted style, size and feet baseline. No text, grid, ground,
or background."

## Brick Catapult Tower - 2026-10-26

`generated/realistic_brick_catapult.png` is an AI-generated edit of the existing
standard tower using the built-in image tool. The original remains unchanged.
The in-flight bricks are original Godot-drawn geometry. Prompt: "Edit this
isolated 2D strategy game tower sprite: keep the same grey stone tower, blue
banner, color, overall proportions, lighting, perspective and transparent
background. Replace its roof crossbow with a compact medieval timber-and-iron
CATAPULT with a clearly visible wooden throwing arm and basket loaded with
several reddish clay bricks, aimed LEFT toward attackers. The catapult and bricks
should read clearly when the sprite is small; believable stone, wood and metal.
Full tower and catapult visible with padding, no fire, no characters, no text,
no ground, no orange tint."

## Fire Bow Tower - 2026-10-26

`generated/realistic_tower_fire_bow.png` was created with the built-in image
generator by editing `generated/realistic_tower_upgraded.png`, preserving the
original tower as a separate file. It is AI-generated artwork with transparency.
Prompt: "Edit this existing game sprite. Preserve the exact tower, silhouette,
position, framing, size, orientation, stonework, blue banners, two crossbow
ballistas and transparent background. Add realistic vivid orange and golden
flame specifically attached to both loaded bolt heads and tracing around the
front limbs and weapon rails of both ballistas. Flames should clearly originate
from the two weapons and flow upward, with soft warm reflected light on nearby
metal and wood; keep the tower itself intact and readable. This is a magical
fire-bow tower, not a building on fire. No floating fireball, no extra weapons,
no characters, no text, no ground or background. Consistent realistic painted
medieval fantasy strategy-game asset."

## Realistic toilet zombie - 2026-10-26

`generated/toilet_zombie_reference.png` is the generated reference, and
`generated/toilet_zombie_walk.png` is the active 1536 × 1024, 4-by-2 walking
sheet. The built-in image generator created both with transparent backgrounds.
Godot aligns the eight poses by measured centers and feet; source PNGs are
unchanged. This is AI-generated project artwork, with no third-party assets.

Final walking-sheet prompt (the reference PNG was supplied as an image):
"Use case: stylized-concept. Create an eight-frame animated sprite sheet for the
SAME realistic fantasy zombie shown in the reference. Crucial design: a whole
white ceramic toilet is worn on the zombie's HEAD as a helmet, with the bowl over
its face, tank behind, and TWO eye holes showing its green eyes. Keep this head
toilet and the same clothing identical in every pose; do not place a toilet behind
its body. The zombie walks slowly to the RIGHT, alternating its legs and arms in
eight sequential shambling poses. Arrange exactly 4 columns by 2 rows of equal
cells. Each cell contains ONE entire small full-body zombie in the center with
plenty of transparent margin on every side; no parts cross cell boundaries.
Consistent side three-quarter perspective, identical scale and feet baseline,
realistic painted game art, no gore, no text, no grid, no ground, transparent
background."

## Realistic zombie dog - 2026-10-26

The built-in image generator created `generated/realistic_zombie_dog.png` as a
transparent reference and `generated/realistic_zombie_dog_run.png` as the active
1536 × 1024, 4-by-2 running sheet. Prompt for the reference: "One full-body
realistic undead dog facing right, running, slightly elevated three-quarter side
view, lean anatomy, ragged dark gray fur, pale eyes, menacing but family-friendly,
realistic painted fantasy game style, transparent background, no floor or text."
Prompt for the sheet: "Create exactly eight separate sequential running poses of
the same dog in a precise four-column by two-row grid, facing right, consistent
size and camera, distinct gallop leg poses, transparent gutters, no floor or text."
Godot aligns each pose using measured foot and center offsets; the original PNGs
are retained unchanged. This is AI-generated project artwork, not third-party art.

Final running-sheet prompt (built-in image tool; the reference PNG was supplied
as an image): "Use case: stylized-concept. Create a production-ready 8-frame
sprite sheet for the same realistic zombie dog in the reference. Arrange exactly
4 columns by 2 rows, each cell equal size. ONE small whole dog in EACH cell,
running to the right, with eight distinct sequential leg poses. Critical layout:
each dog fits within the central 65% width and central 65% height of its cell,
leaving wide empty transparent gutters on ALL FOUR sides of every pose. No parts
or tail cross the cell boundaries. Same size, same camera angle, same foot
baseline in every frame; individual limbs clearly change pose. Transparent
background, no ground, no lettering, no grid, no shadows. Dark fantasy painted
strategy-game style, gray fur, no gore."

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

## Original synthesized pop-rock background music - 2026-10-27

- Active file: `audio/pop_guitar_loop.wav`; eight bars at 112 BPM (17.14 s),
  stereo PCM16, 22050 Hz. Created locally by `tools/compose_pop_music.py` using
  synthesized guitar-like tones, bass and drums. No external music-generation
  service, guitar recordings, samples or third-party music were used. The guitar
  timbre is an approximation; it is not a recorded electric guitar.
- The previous `audio/kingdom_theme.wav` and its generator are retained.

## Original synthesized background music - 2026-10-15

- File: audio/kingdom_theme.wav; 20 seconds, eight bars at 96 BPM, stereo
  16-bit PCM, 22050 Hz. Retained as the previous background loop.
- Source: original melody and arrangement synthesized by project code in
  tools/compose_music.py using additive tones, envelopes and circular stereo echo.
- No music-generation service, recordings, external samples, or third-party
  tracks were used. No external music attribution/license is required.
- This is a simple synthesized prototype score; no sound effects were added.

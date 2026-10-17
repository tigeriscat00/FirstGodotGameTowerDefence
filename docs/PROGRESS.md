# Progress

## 2026-10-17 - GitHub check-in

- Created public repository: https://github.com/tigeriscat00/FirstGodotGameTowerDefence
- All nine headless suites passed: 662 assertions. The grid suite also reported
  the known audio shutdown ObjectDB warning; no assertion failures occurred.
- Engine caches, temporary captures and build outputs remain ignored.


## 2026-10-17 - button, zombie, combat and skill sounds

- Synthesized seven original WAV effects locally: UI click, ballista, impact,
  Freeze, upgrade and two voiced/breathy zombie groans. No external audio tool or
  recorded samples used. Rebuild with tools/compose_sfx.py; provenance saved.
- Shared Sfx node automatically connects enabled buttons, including new popups,
  and retains clicks across scene transitions. A bounded 10-voice pool and short
  rate limits prevent overlapping storms; groans are spaced 4–6.5 combat seconds.
- Damage, actual shots, successful Freeze and upgrades trigger their own sounds.
  Frozen zombies do not start groans; shop/settings pause combat playback. Menu
  return clears combat effects. Separate Sound effects mute leaves music alone.
- Validation: clean import and 136 rendered tutorial checks with the normal audio
  driver passed. Added targeted sound-event/mute/pause/scene-transition checks.
  Inspected the settings layout with its new effects control.
- All 25 sound-effect checks, 10 music checks and 144 semiboss balance checks
  passed. Confirmed every WAV is mono 22050 Hz with peaks at 72% full scale.
- Perceptual volume/timbre still benefits from a human listening pass on the
  owner's speakers. Effect gains are adjustable in scripts/audio/sfx.gd.

## 2026-10-17 - slower, distance-matched zombie gait

- Replaced the fixed 10 fps limb cycle with distance-driven poses: one cycle
  per 72 px at normal size, approximately 5 fps / 1.6 seconds at default speed.
  The larger, slower semiboss uses a longer stride and slower limb cadence.
- Enemy travel speed, combat timing and Freeze duration remain unchanged.
  Walking pauses still hold the current pose. Walk Cycle Distance in the Zombie
  Inspector replaces Walk FPS; increase it to slow the limb cycle further.
- Added checks for a slower initial pose and equal poses after equal distances
  traveled at different speeds, alongside the existing Freeze/attack checks.
- Clean import, 12 actor-art checks and 136 rendered tutorial checks passed.

## 2026-10-17 - realistic art, tower transformation and zombie walking

- Generated and integrated four transparent assets: realistic castle, standard
  round single-ballista tower, reinforced twin-ballista upgrade and eight-pose
  zombie walk sheet. Old assets retained; prompts/provenance saved with the art.
- Upgrade immediately swaps the actual tower sprite and plays a 1.2 s expanding
  gold ring, rising particles, glow/scale pulse and UPGRADED label. Repeated
  upgrades do not replay the effect or grant stats twice.
- Zombie limbs animate through eight frames while moving. Freeze holds the
  current pose; attacks stop walking. Ground shadows and measured per-frame
  foot alignment keep actors grounded. Health bars no longer cover the face;
  top-lane labels shift sideways when there is insufficient overhead room.
- Validation: clean import, 136 rendered tutorial checks, 10 actor-art checks,
  144 semiboss balance checks, 197 popup layout checks and 23 guidance checks
  passed. Inspected source transparency, walk poses and upgrade gameplay captures.
- Walk FPS is adjustable on the Zombie node (default 10). Generated walk poses
  are discrete frames, with minor pose variation; no separate attack animation
  or exported build is included in this pass.

## 2026-10-17 - placement highlight targets clear building cells

- Fixed a hard-coded placement cue that framed the zombie's starting cell.
  It now follows the hovered empty build cell, or chooses a clear fallback when
  the pointer is outside the grid, on a tower or overlapping the zombie artwork.
- Cue selection changes only visual guidance; placement and combat rules remain
  unchanged. Added checks for the exact report, hover tracking and occupied cells.
- Clean import, 23 guidance checks and the complete rendered tutorial passed.

## 2026-10-17 - victory celebration and return to main screen

- Winning now opens a large centered crown and VICTORY banner with a bounce/fade
  entrance, floating crown, rotating rays, fireworks and falling confetti.
- Quit appears below after 1.2 seconds and returns to the main menu, per the
  owner's clarification. It does not close the application. Background controls
  and tutorial sparkle cues are blocked/hidden during the celebration.
- Celebration is an editable scene with original Godot drawing effects, reusing
  the shared theme. No external assets or new runtime dependencies.
- Clean import and 134 rendered tutorial checks passed, including the victory
  overlay, Quit mouse click, main-menu return and a fresh tutorial start.
  Celebration screenshot inspected. Main-screen Quit still exits the app.

## 2026-10-17 - sparkling tutorial cues and automatic dialogue

- Removed all dialogue advance buttons. Buy -> place -> inspect -> upgrade ->
  tower skills advances through player actions. Health is explained during the
  inspection instruction rather than behind a separate Next confirmation.
- After the guided kill and semiboss introduction, combat waits four seconds
  for reading and starts automatically. Settings pause these timers; the newly
  started encounter does not consume the elapsed reading time as combat time.
- Added a mouse-transparent gold outline with a gentle pulse and four moving
  sparkles. It tracks actual button layout and highlights Shop, Buy, Upgrade,
  Q/Freeze, the placement cell, tower and zombie target as appropriate.
- Verified 131 rendered tutorial checks, 19 automatic-guidance checks, 25 tower
  skill checks, 197 popup layout checks and 144 semiboss balance checks. Inspected
  the highlighted Buy, Upgrade and Freeze buttons. No gameplay balance changed.
- Message Read Seconds on Tutorial controls automatic reading pauses; default 4.

## 2026-10-17 - tower-specific QWER skills

- Tower popup now includes four key-marked skill slots. Standard tower has Q:
  Freeze and empty W/E/R slots; no additional abilities were invented. Removed
  the global toolbar button/F shortcut. Mouse and keyboard use one skill handler.
- Select a tower, activate a skill, then choose a zombie. Activation closes the
  popup; Esc cancels targeting without spending the cooldown. Empty keys do nothing.
- Tower configuration caps skills at four. Freeze recharge now belongs to the
  casting tower and continues while unselected; settings/shop pause all recharges.
  Destroying the caster cancels its pending targeting. Tutorial text uses Q.
- Verified 122 rendered tutorial checks (including mouse/Q casts), 25 targeted
  QWER/cooldown checks, 197 popup layout checks and 144 semiboss balance checks.
  Inspected the four-slot popup at 1152 x 648. No exported build produced.
- Add future approved abilities through the tower's Skills array in the Inspector;
  unassigned slots remain disabled until an ability is actually implemented.

## 2026-10-17 - missing opening dialogue fixed

- Reproduced the owner's blank opening dialogue after entering from Play.
  Initial word wrapping left the VBox at 197 px high, so vertically centered
  text appeared below the screen despite the correct instruction being set.
- Dialogue now resizes after its text container's minimum size changes; opening
  text fits within the intended 52 px content area on the first rendered frame.
- Added regression assertions and a screenshot before the integration test's
  scene reload, covering the actual main-menu-to-tutorial transition.
- Validation: clean import; all 121 rendered tutorial checks passed in windowed
  and native fullscreen. Opening screenshot visually inspected with Sphinx's
  shop instruction visible inside the panel. No gameplay rules changed.

## 2026-10-17 - full-width battlefield and contextual upgrades

- Removed the 320 px sidebar reservation. Lawn fills the 1152 x 648 canvas;
  castle is right-aligned and the 24 cells are 112 x 88 px. Kingdom target moved
  with the castle; damage, health, range and reward tuning were preserved.
- Upgrade/sell popup opens only on a tower click, beside that tower. It avoids
  the toolbar, dialogue and its tower. Upgrade, empty ground, Close/Esc, Freeze,
  shop or settings closes it and removes the range preview.
- Shared rounded dark/gold/teal theme covers the entry menu and every popup.
  Sphinx uses a 72 px strip (96 px with Next). Freeze moved into the toolbar,
  clear of the castle; brief feedback appears below the HUD.
- Explicit proportional canvas scaling preserves fullscreen alignment.
- Validation: 118 rendered tutorial/UI checks in windowed and 2560 x 1440
  fullscreen; 197 UI layout/dismissal checks across all 24 cells with/without
  dialogue; 106 grid, 144 semiboss balance and 10 music checks passed. Inspected
  gameplay, upgrades, shop, settings and main menu captures. No export produced.
- Existing forced CLI audio shutdown warning remains as documented below;
  scripted test exits are clean. Human comfort still needs the owner's playtest.
- Tune the shared style in resources/ui_theme.tres. Next valuable milestone:
  a second playable wave after trying this complete interface.

## 2026-10-17 - compact HUD, modal shop and health text inside bars

- Used the owner's Valorant screenshot as a layout reference: dark panels,
  restrained gold/teal accents, status across the top and settings at top-right.
- Settings gear/Esc opens a paused modal with fullscreen, music, resume, restart
  and main menu. Cart/B opens a separate shop; successful purchases close it
  automatically. Failed purchases keep their feedback inside the shop.
- Tower details appear only for the selected tower and can be dismissed.
  Shortened Sphinx's bottom instructions; combat messages hide after four seconds.
- Shared health-bar scene centers numbers inside enemy, tower and kingdom bars.
  Enemy bars and semiboss titles stay below the new HUD on the top build row.
- Original SVG cart, gear, Freeze, coin and shield icons replace text controls.
- Validation: clean import; 106 rendered tutorial/UI checks, 106 grid checks,
  144 semiboss balance checks and 10 music checks passed (366 total). Inspected
  shop, settings, semiboss and health-bar screenshots at 1152 x 648.
- Forced CLI --quit-after startup exits still report two audio playback objects
  at cleanup. Verified these are AudioStreamWAV/AudioStreamPlaybackWAV; normal
  scripted exits stop music and drain the mixer, and all test suites exit cleanly.
- Human readability at a distant screen remains a playtest item. Next try the
  full tutorial using the icons; Combat Message Seconds on Tutorial is editable.

## 2026-10-17 - Sphinx dialogue on the battlefield

- Moved Sphinx's words, portrait and lesson buttons into a gold-bordered popup
  at the bottom of the battlefield, with larger text and portrait.
- Hide reveals lower grid cells; the Sphinx button restores the popup. New
  lessons show their words automatically. Sidebar now has more room for controls.
- Clean editor import and rendered tutorial checks passed; inspected the
  semiboss popup for readable text and a visible Face semiboss button.
- Next playtest: try Hide while placing a tower in the bottom row. Popup size
  and text size can be adjusted on the Dialogue node in the tutorial scene.

## 2026-10-17 - smaller castle wall

- Reduced the castle/wall artwork from 648 to 552 px tall (about 15% smaller),
  preserving its aspect ratio and aligning it with the lawn's right edge.
- Grid, towers, routes, kingdom health and semiboss balance are unchanged.
- Castle Height is now adjustable on the Board node in the Inspector.

## 2026-10-17 - full-height lawn, grid and overhead castle

- Owner clarified that the castle, rather than a buildable tower, should be tall
  like the home base in Plants vs. Zombies; then requested more width and a view
  from above. Generated and integrated a wider overhead castle with a courtyard.
- Lawn and castle span the full 648 px logical app height. Controls and guide
  moved to a sidebar; tower details scroll. Shop image/name/Buy order retained.
- Replaced three circles with faint grid lines, 24 legal cells, cell-center
  snapping, occupancy checks and green/red hover feedback with a range preview.
- Tower art fits its cell. Entry columns and top label margin cannot be occupied.
- Guided enemy and practice wave use the first tower's row. This remains one
  tutorial wave, not simultaneous attacks in every row.
- Verified clean import, 106 grid checks, 144 semiboss balance checks covering
  all 24 cells at three frame rates, 10 music checks, and 91 full tutorial/UI
  checks in a real fullscreen window. New shop, grid hover, overhead health and
  semiboss screens were visually inspected at 1152 x 648 and fullscreen.
- Input checks send complete mouse gestures after container layout settles;
  this avoids native pointer events interrupting the automated click sequence.
- Human comfort/readability and simultaneous multi-lane waves remain untested.
- Next playtest: check grid visibility and sidebar readability. Grid Opacity on
  the Board node can be adjusted; initial opacity is 0.08.

## 2026-10-17 - Freeze matters against the semiboss

- Increased semiboss health from 240 to 600, retaining hidden strength/reward UI.
- Sphinx now explains that one tower needs Freeze and to wait for tower range.
- Added 18 real-encounter balance checks: all three sockets, 60/30/10 simulated
  FPS, both with and without Freeze. One fully healthy upgraded tower loses
  without Freeze and wins with one timely cast in every tested case.
- Clean import and all 87 rendered tutorial checks also passed. Inspected the
  600 / 600 health label and longer Sphinx instructions; both fit on screen.
- Health is the only combat tuning changed. No artificial immunity, forced
  loss trigger, reward change or extra enemy ability was added.
- Next playtest: compare Freeze timing during the actual fight. Semiboss Health
  in the balance Resource is the parameter to tune if the fight feels too long.

## 2026-10-17 - Standard tower shop card

- Replaced the text-only item with the tower picture, Standard tower name below,
  and a Buy button below the name. Price remains on the Buy button.
- Reused the existing generated tower sprite and kept purchase/placement rules.
- Validation: clean editor import, all 87 rendered purchase/gameplay checks
  passed, and shop screenshot visually inspected at 1152 x 648.
- Next playtest: press B and check whether the picture makes the tower easy to
  recognize. Picture size is editable on Shop/Contents/Picture in the scene.

## 2026-10-17 - overhead enemy health and hidden enemy stats

- Normal zombies and semibosses always show current / maximum health above their
  green health bars. Numbers update on damage; the semiboss title sits above them.
- Enemy clicks no longer open stats. Removed enemy strength and kill-reward
  amounts from inspection, Sphinx dialogue and kill/damage notification text.
- Gold rewards still settle once and increase the player's gold total. Tower
  stats, upgrade/sell buttons and Freeze targeting remain available.
- Replaced mandatory zombie inspection with a health explanation and Next button.
- Validation: clean import and 87 rendered gameplay checks passed, including
  automatic regular/semiboss health labels, live damage updates, no enemy stat
  disclosure on clicks, and unchanged once-only gold payout. Both health-label
  screenshots were visually inspected. Human readability still needs playtesting.
- Next playtest: check readability while enemies move; try a larger HealthLabel
  font size in scenes/actors/zombie.tscn if the numbers are hard to read.

## 2026-10-17 - editor-embedded fullscreen correction

- Owner reported "Embedded window only supports Windowed mode." Previous checks
  covered native standalone windows and missed the editor's default embedding.
- Added Play-Game.cmd to start the game directly in its own fullscreen window.
- F11/button uses Engine.is_embedded_in_editor() and shows actionable instructions
  instead of attempting an unsupported window mode. Existing run is preserved.
- For F5 fullscreen, disable Game > top-right menu > Embed Game on Next Play,
  stop the current run, then run again. This is an editor setting, not an export.
- Verified clean import, all eight native fullscreen checks, and the guard in a
  real native parented child window (--wid), matching editor embedding. The
  guard showed help and kept window mode unchanged, with no engine errors.
- Actual editor-menu interaction remains for the user's next playtest.

## 2026-10-17 - fullscreen

- Added F11 and Fullscreen/Windowed buttons to both menu and tutorial.
- Window mode persists across scene changes and restart; shortcut also works
  while the tutorial is paused. No new global manager was needed.
- Set a 1152 x 648 logical canvas with proportional scaling to keep artwork,
  UI and mouse targeting aligned at fullscreen resolutions.
- Verified clean editor import, eight real-window display checks (F11, buttons,
  pause, scene transition and restart), and all 77 tutorial checks in fullscreen.
  Fullscreen screenshot inspected at 2560 x 1440; UI and mouse targeting align.
- Standalone Godot window verified; editor-embedded play and other screen aspect
  ratios still need a user check. No standalone export has been tested.
- Try F11 during the semiboss introduction, then return to windowed mode.

## 2026-10-15 - background music

- Added an original 20-second synthesized instrumental loop, generated locally
  from the project's composition script; no external tracks or audio service.
- Shared music player keeps the loop continuous across menu/tutorial/restart.
- Added Music: On/Off buttons to menu and tutorial. Muting preserves playback
  position; the choice stays consistent until the application closes.
- Music continues during gameplay pause. Scene exposes volume at -12 dB.
- Verified clean import, 10 music checks (including actual loop wrap), and all
  77 rendered tutorial checks. Visually checked the new header control.
- Checked WAV duration, nonzero samples and peak level (no sample clipping).
  Subjective listening quality is still for the owner's playtest.
- Graceful shutdown stops playback and lets the mixer release its buffer.
- Small tuning task: change Music Volume Db on scenes/audio/music.tscn; the
  initial value is -12 dB. Existing balance and semiboss rules are unchanged.

## 2026-10-15 - semiboss wave finale

- Confirmed kill-gold rewards and a semiboss at the end of each wave with the
  owner's Sphinx dialogue and Freeze advice.
- Final practice enemy now uses 240 health, 110 power, 35 px/sec and a 75-gold
  reward. Regular zombies retain their 25-gold reward, paid once per enemy.
- Added a larger zombie sprite, gold ring, SEMIBOSS label and level-2 inspection.
- Sphinx's introduction holds combat until Face semiboss is clicked; Freeze is
  refreshed. The five-second stop and tower boost work against the semiboss.
- Headless import and 71 gameplay checks passed, including the final spawn,
  introduction hold, Freeze recharge, winning with Freeze and duplicate reward guard.
- The rendered run passed 77 checks with six screenshot saves; semiboss dialogue
  and Freeze screens were visually inspected. A one-enemy wave also ends in a
  semiboss. Human play feel and standalone export remain unverified.
- Current scope remains one replayable practice wave, ending with its semiboss.
- Next playtest: assess semiboss difficulty; adjust semiboss_health in the balance
  Resource to compare a shorter or longer fight.

## 2026-10-15 - playable tutorial and generated assets

- Retained the owner's kingdom/zombies/Sphinx theme and confirmed combat targets.
- Replaced the UI shell with guided buying, B shop close, Sphinx introduction,
  legal wall placement, clickable zombie/tower stats, upgrading and F + click Freeze.
- Added real automatic ranged attacks, five-second Freeze with faster tower fire,
  zombie movement and attacks against towers / kingdom, kill rewards and selling.
- Added a three-enemy practice defense, victory/defeat, pause, restart and menu.
- Lessons hold combat until Freeze is taught. Shop holds active combat; tutorial
  gates prevent selling or skipping required actions before the practice battle.
- Generated and integrated four transparent storybook PNGs: tower, zombie, kingdom,
  Sphinx. Sources, actual dimensions and prompts are in assets/.
- Separate editable actor scenes, battlefield, tutorial UI and balance Resource.
- Existing project.godot editor changes were preserved, including removed explicit
  viewport size entries; runtime minimum window size keeps this layout readable.

Validation:
- Godot 4.7.2 headless editor import and 120-frame startup checks completed cleanly.
- tests/run_tutorial.gd checks the full flow at all three sockets, economy guards,
  shooting range/intervals, zombie tower damage, Freeze timing/boost, pause, shop,
  single death settlement, practice victory, undefended gate defeat and restart.
- Keyboard events and viewport mouse events exercise the real UI event path.
- A rendered Compatibility run passed 66 checks including four screenshot saves;
  shop, Freeze, victory and defeat screenshots were visually inspected at 1152x648.
- A freed-target error found during testing was fixed by pruning actor references
  before passing them into typed combat methods.

Limits and next step:
- Not a campaign: one route, one tower type, one upgrade and sequential enemies.
- Art is static with engine motion/effects; background music exists, but no sound
  effects or authored animation sheets have been added.
- Automated input and screenshots do not assess human comfort or difficulty.
- Export templates remain uninstalled and no standalone export was validated.
- Next: parent/child playtest, especially lesson wording, visual style, Freeze
  timing and whether the practice battle should become harder.
- Small tuning task: change zombie_speed on resources/tutorial_balance.tres,
  then replay the practice battle to compare its pace.

Git foundation: project-local main repository; author configured locally as
hongyang <hongyangliu1987@gmail.com>. Parent repository preserved; no remote
or publication. Initial foundation commit was 8bf0e27.

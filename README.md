# FirstGodotGameTowerDefence

A playable 2D tower defence tutorial: learn from Sphinx, build on the kingdom wall,
upgrade your tower, freeze a zombie, then defend a wave ending with a semiboss.

Castle, tower tiers and zombies now use more realistic fantasy artwork. Upgrade
plays a gold transformation and replaces the tower with a distinct twin-ballista
version. Zombies walk with eight arm/leg poses; Freeze stops their animation too.
Prompts and asset provenance are in assets/generated/REALISTIC_ART_PROMPTS.md and
assets/ASSET_SOURCES.md. Walk Cycle Distance is editable on the Zombie node:
larger values give slower limb movement without changing enemy travel speed.

## Play

For fullscreen, double-click Play-Game.cmd. It runs the game directly in its
own fullscreen window. F11 switches back to windowed mode.

If using Godot's F5 play button, first open the Game tab's top-right menu and
turn off **Embed Game on Next Play**, then stop and run again. Embedded game
windows cannot enter fullscreen; the in-game toggle explains this limitation.

1. Double-click Open-Godot.cmd, or import project.godot in Godot 4.7.2.
2. Press F5 and choose Play tutorial.
3. Follow Sphinx: click the cart icon or press B, then buy a Standard tower.
   The shop closes automatically. Click an empty grid cell near the castle,
   then click your tower to inspect and upgrade it. Gold sparkles show the next
   required button, tower or target.
4. Click Upgrade, click the tower again, then Q / Freeze and click the zombie.
   Watch the guided fight. After a short message, the wave starts automatically.
   Defeat two regular zombies and the final semiboss before the kingdom falls.
   Sphinx introduces the semiboss with a short reading pause before it moves.
   There are no dialogue Next or confirmation buttons.

Victory plays a centered crown/fireworks/confetti celebration. Its Quit button
returns to the main screen; choose Play tutorial to start again.

Defeating enemies still earns gold, but their strength and reward amounts are
hidden from the game UI. Health numbers appear inside their overhead bars.
The semiboss looks larger, with a gold ring and SEMIBOSS label. Use Freeze
to stop it for five seconds and give your tower the faster firing interval.
The semiboss has 600 health: your single upgraded tutorial tower needs Freeze
to win. Wait until it enters tower range before casting.

The full-screen lawn has faint grid lines, and the wider castle is shown from
above along its right edge. Towers snap into cells, one per cell. The left entry
area and top margin stay clear; green/red hover feedback shows legal placement.
The tutorial wave follows the first tower's row. Click a tower for an adjacent
upgrade popup; upgrade, click empty ground or use Close/Esc to dismiss it.
There is no permanent sidebar. Sphinx's short lessons appear at the bottom:
× hides them and ? restores them. Combat tips disappear after four seconds.

Controls: B toggles shop. Click a tower to open its Q/W/E/R skill slots, then
click a skill or press its key. Standard tower has Q: Freeze; W/E/R are empty.
After activating Freeze, click a zombie; Esc cancels without spending cooldown.
Each tower has at most four skills and recharges its own Freeze independently.
The cart opens the shop; Freeze no longer has a global toolbar button or F key.
The top-right gear or Esc opens paused settings: fullscreen, music, resume,
restart and main menu. Esc closes an open shop before opening settings.
Press F11 or use Fullscreen in settings to toggle display mode.
The game scales proportionally, keeping clicks aligned. Background music loops
continuously; Music: On/Off in settings preserves mute across restarts.
The shop pauses active combat. Freeze recharges after 12 seconds of active combat.
Button clicks, ballista shots/hits, Freeze, upgrades and intermittent zombie groans
now have original synthesized sound effects. Sound effects: On/Off in settings
and the main menu mutes these separately from music. Combat sounds pause with the
shop/settings and stop when returning to the menu. Rebuild them with
tools/compose_sfx.py; adjust individual effect gains in scripts/audio/sfx.gd.
Illegal placement retains your purchased tower without charging again. Selling
unlocks for practice and returns half the total purchase/upgrade cost.

## Tune and inspect

- resources/tutorial_balance.tres: gold, damage, health, range, timings and speed.
- scenes/actors/: editable tower/zombie scenes with generated transparent sprites.
- scenes/tutorial/tutorial.tscn: editable map, UI, guide portrait and HUD.
- resources/ui_theme.tres: shared colors, spacing and rounded control styles.
- scripts/actors/: movement, damage, freeze and attack intervals.
- scripts/tutorial/: map selection/feedback and tutorial progression.
- docs/GAME_DESIGN.md: owner-confirmed ideas and prototype defaults.
- docs/DESIGN_REVIEW.md: original gaps and design alternatives.
- docs/PROGRESS.md: completed work, validation and limitations.
- assets/ASSET_SOURCES.md and assets/generated/PROMPTS.md: generated art provenance.

Small experiment: change Zombie Speed in the balance Resource Inspector, press F5,
and compare the practice battle. The initial speed is 45 pixels/second.
For UI tuning, adjust Combat Message Seconds on the Tutorial root to change
how long Sphinx's battle tips remain visible (initially four seconds).

## Verify

```powershell
./tools/godot.ps1 --headless --editor --import
./tools/godot.ps1 --headless --quit-after 120
./tools/godot.ps1 --headless res://scenes/tutorial/tutorial.tscn --quit-after 120
./tools/godot.ps1 --headless --script res://tests/run_tutorial.gd
./tools/godot.ps1 --headless --script res://tests/check_music.gd
./tools/godot.ps1 --headless --script res://tests/check_semiboss_balance.gd
./tools/godot.ps1 --headless --script res://tests/check_build_grid.gd
./tools/godot.ps1 --headless --script res://tests/check_ui_layout.gd
./tools/godot.ps1 --headless --script res://tests/check_tower_skills.gd
./tools/godot.ps1 --headless --script res://tests/check_tutorial_guidance.gd
./tools/godot.ps1 --headless --script res://tests/check_actor_art.gd
./tools/godot.ps1 --headless --script res://tests/check_sfx.gd
```

Optional rendered checks and screenshot capture (quote the final separator):

```powershell
./tools/godot.ps1 --resolution 1152x648 --disable-vsync --script res://tests/run_tutorial.gd '--' '--capture'
```

Captures are written under ignored tmp/. A headless run checks behavior, not visual
layout or human play feel. Rendering uses Compatibility; no additional plugins or
runtimes are needed. Export templates remain uninstalled; no exported build exists.
The launcher supports GODOT_EXECUTABLE when moving to another machine.

## Git

This folder has its own repository on main, independent of the parent environment
setup repository. Author identity is local. GitHub remote: https://github.com/tigeriscat00/FirstGodotGameTowerDefence

```powershell
git status
git diff
git add .
git commit -m "Describe the change"
```

Keep .uid and import settings with assets; .godot/, tmp/, output/ and builds/ are
ignored. Avoid editing the OneDrive project simultaneously on multiple computers.

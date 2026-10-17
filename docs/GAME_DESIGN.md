# Game design

Display: F11 and a menu/tutorial button toggle fullscreen and windowed play.
The 1152 x 648 game canvas scales proportionally, with letterboxing when needed.
Play-Game.cmd starts native fullscreen directly. Godot editor embedding must be
disabled for F5 fullscreen; the toggle provides instructions when embedded.

## Confirmed by the owner

- Project: FirstGodotGameTowerDefence; Godot 4.7.2, GDScript, 2D.
- Theme: protect a kingdom from zombies; guide character named Sphinx.
- Sphinx speaks briefly in a bottom battlefield popup with portrait and lesson
  guidance. No Next/Begin defense/Face semiboss buttons are required. Completing
  an action immediately shows the next instruction. × hides it and ? restores it.
  Gold pulsing outlines and sparkles mark required buttons and world targets.
  During placement, the cue follows a hovered empty cell or picks clear ground;
  it avoids framing existing towers or zombie artwork.
  Combat tips disappear after four seconds;
  mandatory lessons stay until acted on or hidden.
- Compact HUD inspired by the owner's Valorant reference: a top-right settings
  gear opens fullscreen, music, resume, restart and main-menu controls. Settings
  pause combat. A separate cart icon (B) opens a modal shop outside the menu.
- A successful purchase closes the shop automatically, ready for placement.
  Failed purchases keep the shop open and explain the problem inside the popup.
- First release is the tutorial. English only initially (chat confirmation).
- Zombies can attack towers and the kingdom (chat confirmation).
- B or the cart icon opens/closes the tower shop; Sphinx teaches the first purchase.
- Shop card order: Standard tower picture, "Standard tower" name, then Buy button
  with the gold price. The card uses the same generated sprite as the built tower.
- Place towers in lawn grid cells; click towers for upgrades and selling.
- Tower clicks show up to four skill slots marked Q/W/E/R. Click a skill or
  press its key while that tower's popup is open. Standard tower has Q: Freeze;
  W/E/R are empty. F and the global toolbar Freeze control are removed.
  Cooldowns belong to each tower; each can equip at most four skills.
- Battlefield fills the canvas with no sidebar. Only a tower click opens its
  adjacent upgrade popup. Upgrade, empty ground, Close/Esc, Freeze, shop or
  settings dismisses it. The popup avoids the toolbar, its tower and dialogue.
- Updated layout request: the castle is the large home base on the right, fills
  most of the app height, and is wider with an overhead courtyard view. The lawn fills
  the height; faint grid lines show tower placement cells rather than circles.
- Zombie example: 80 health, 90 power; level appears in its stats.
- Standard tower: 180 health, 20 power; upgraded: 200 health, 40 power.
- Owner requested more realistic castle/tower/zombie art. Current assets use
  weathered stone, timber, iron and blue banners. Upgrading replaces the round
  single-ballista tower with a reinforced twin-ballista tower and plays a gold
  ring, rising particles, scale/glow pulse and UPGRADED label for 1.2 seconds.
- Zombies use eight walking poses tied to distance traveled: a full cycle covers
  72 px for a normal zombie (about 5 frames/sec at 45 px/sec), with a longer,
  slower stride for the larger semiboss. Foot baselines
  are aligned. Walk animation runs only while moving and stops during Freeze,
  attacks, shop and settings pauses. The larger semiboss uses the same walk sheet.
- Tower inspection allows upgrading and selling.
- Health numbers are centered inside green bars for enemies, towers and kingdom.
  Enemy bars stay visible overhead without clicking; no separate health text above.
  Enemy strength and individual kill-reward amounts are hidden in the game UI.
  This replaces the original click-to-inspect enemy stats lesson. Tower stats
  and upgrade/sell controls remain available by clicking a tower.
- Selected tower details show its health bar and damage; dismissing them clears
  the selection and range preview. No permanent instructions or power bar on the HUD.
- Freeze holds a zombie for five seconds; the tower shoots faster while it is frozen.
- Sphinx concludes the tutorial and sends the player to guard the kingdom.
- Victory opens a centered animated crown, fireworks and confetti celebration.
  A Quit button appears underneath after the entrance and returns to the main
  screen without closing the application. The celebration covers gameplay input.
- Defeating zombies earns gold. Every wave ends with a semiboss zombie, and
  Sphinx introduces it and tells the player to use Freeze to stop it.

## Proposed loop and controls

Buy -> place -> inspect -> upgrade -> freeze -> defeat zombie -> finish tutorial.
Keyboard/mouse on Windows; B for shop, click to select/place; Freeze input TBD.
Success/failure rules, economy, targeting and ability details remain proposals.
See DESIGN_REVIEW.md for gaps, suggested values and tutorial acceptance steps.

## Scope and open decisions

Target player's age/experience and preferred tower defence references are unknown.
"Power" needs a precise meaning; targeting and damage timing need agreement.
No campaign, additional abilities or enemy roster is required for the first release.
The playable tutorial now uses generated storybook sprites and code-drawn scenery.
Art direction is a prototype choice and can be changed with the owner's feedback.

## Implemented prototype defaults (adjustable, not new owner-confirmed requirements)

- Power is damage per hit. Tower range 250 px; 1 second between shots.
- Freeze lasts five seconds and halves the firing interval against that target;
  click a tower, use Q / Freeze, then click a zombie. Recharge is 12 seconds of
  active combat per tower; shop/settings pause the recharge.
- Start with 150 gold; buy for 100, upgrade for 50; regular kills reward 25 gold
  and the semiboss rewards 75. Each enemy pays out only once.
- Sell for half the total paid; selling unlocks for the practice battle.
- Seven columns by seven rows of faint lawn cells, each 112 x 88 logical pixels.
  The left three columns are the enemy approach area and the top row is kept
  clear for overhead labels. Twenty-four cells support one tower each; buying
  reserves a tower until legal placement and snaps it to the cell center.
- This tutorial's wave uses the first tower's row. The guided enemy aligns with
  that row after placement, then practice enemies follow it toward the castle.
  Other cells remain available for later towers; simultaneous multi-row waves
  are outside this change's scope.
- Standard towers render at 68 px wide to fit their cells. The generated overhead
  castle renders at 276 x 552 px after the owner's smaller-wall adjustment.
  The castle hugs the right edge of the full 1152 px canvas. Settings and shop
  use separate popups; skills stay in the tower popup. Tower details and range
  preview appear only while the contextual tower popup is open.
- Zombies follow the route, stopping for towers within 78 px, otherwise attacking
  the kingdom gate. Melee damage is 90 every two seconds; movement is 45 px/sec.
- Kingdom has 300 health. Attacks at the gate reduce health until stopped.
- Guided combat waits for the Freeze lesson; one guided zombie, then three
  sequential practice enemies, with two seconds between kills and new spawns.
  The last enemy is always a semiboss (including a one-enemy wave).
- Semiboss prototype stats: 600 health, 110 damage, 35 px/sec; larger sprite,
  gold ground ring and SEMIBOSS label, with hidden damage/reward stats. It uses the
  existing zombie art. Freeze stops its movement/attacks for the normal five seconds.
- Before the semiboss fight, Sphinx says: "This is a semiboss. It will be here at
  the end of every wave of zombies. Use Freeze to stop the semiboss zombie!"
  Combat waits four seconds for reading, then starts automatically; Freeze is
  refreshed for this tutorial encounter. Settings pause this reading timer.
- Owner requested a tougher finale requiring Freeze. The standard tutorial's
  single upgraded tower loses against the 600-health semiboss without Freeze;
  casting within range wins. Sphinx explains that timing. This is combat balance,
  not scripted invulnerability or a forced failure for never pressing F.
- Win after all practice zombies die; lose at zero kingdom health. Restart resets
  the entire run. B shop and Esc pause hold movement, attack and Freeze timers.
- The tutorial currently contains one practice wave; its final-enemy spawning rule
  also applies when that wave is replayed or its enemy count is adjusted.
- English-only release begins directly in English; no redundant language picker.
- Generated realistic castle, two tower tiers and a zombie walk sheet; the Sphinx
  portrait remains the existing guide asset. Ice tint, shot beams, health bars,
  upgrade effects and range/placement previews are engine effects.

Tune resources/tutorial_balance.tres in the Godot Inspector. Separate actor scenes,
battlefield and tutorial controller keep map, combat and teaching editable.

## Background music

Sound effects: every enabled UI button plays a short click. Tower shots play a
ballista launch and impacts; successful Freeze casts play an ice effect, upgrades
play a rising chime. Active zombies groan intermittently, with a lower semiboss
variant. Shop/settings pause combat audio. Sound effects have their own mute
control in settings and the main menu, independent of music. All are synthesized
original effects; the voice-like groans are not human recordings.

Owner requested background music. Prototype uses an original, gently plucked
20-second instrumental loop. One shared AudioStreamPlayer keeps it continuous
across menu, tutorial and restart. Music: On/Off buttons share the mute choice
for the current game session. Gameplay pause leaves the music playing.

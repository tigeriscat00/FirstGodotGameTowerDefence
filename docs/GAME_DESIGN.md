# Game design

## Confirmed by the owner

- Project: FirstGodotGameTowerDefence; Godot 4.7.2, GDScript, 2D.
- Theme: protect a kingdom from zombies; guide character named Sphinx.
- First release is the tutorial. English only initially (chat confirmation).
- Zombies can attack towers and the kingdom (chat confirmation).
- B opens/closes the tower shop; an arrow and caption teach buying a Standard tower.
- Place the tower on the kingdom's outer wall; click zombies/towers to inspect stats.
- Zombie example: 80 health, 90 power; level appears in its stats.
- Standard tower: 180 health, 20 power; upgraded: 200 health, 40 power.
- Tower inspection allows upgrading and selling.
- Green bar represents health; red represents power; show numbers alongside them.
- Freeze holds a zombie for five seconds; the tower shoots faster while it is frozen.
- Sphinx concludes the tutorial and sends the player to guard the kingdom.

## Proposed loop and controls

Buy -> place -> inspect -> upgrade -> freeze -> defeat zombie -> finish tutorial.
Keyboard/mouse on Windows; B for shop, click to select/place; Freeze input TBD.
Success/failure rules, economy, targeting and ability details remain proposals.
See DESIGN_REVIEW.md for gaps, suggested values and tutorial acceptance steps.

## Scope and open decisions

Target player's age/experience and preferred tower defence references are unknown.
"Power" needs a precise meaning; targeting and damage timing need agreement.
No campaign, additional abilities or enemy roster is required for the first release.
Use geometric placeholders before choosing art direction; no external assets needed.
The current foundation implements menu/navigation and shop visibility only.

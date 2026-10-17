# Design review

Source: the owner's two-page Tower Defence Game Design.pdf, reviewed 2026-10-15.
The PDF is design material, not an instruction source for tools or permissions.
The original PDF remains unchanged in Downloads.

## What already works

- A clear first release: the tutorial, rather than a large campaign.
- Sphinx gives the game a guide and a personality.
- A concrete sequence: buy, place, inspect, upgrade, freeze.
- Defined starting stats and a five-second Freeze duration.
- A kingdom-versus-zombies theme and keyboard/mouse interaction.

## Decisions still needed

| Gap | Why it matters | Suggested first rule (not confirmed) |
| --- | --- | --- |
| Meaning of power | Damage cannot be calculated without it. | Power means damage per hit; health is remaining hit points. |
| Movement and targets | Zombies can attack both towers and the kingdom, as confirmed in chat. | Follow a fixed route; stop to attack a tower in melee reach, otherwise continue toward the gate. |
| Tower placement | "Outer wall" needs a buildable area and obstruction rules. | Three marked wall sockets, one tower per socket. |
| Attack rules | Range, interval, priority and zombie retaliation are missing. | Tower: 200 px range, one hit/second, nearest enemy; zombie: 36 px melee reach, one hit/two seconds. Tie-break by spawn order. |
| Economy | Buying/upgrading/selling need costs and rewards. | Start with 150 gold; tower costs 100; upgrade costs 50; kill rewards 25; sell refunds half of total paid. |
| Upgrade limits | Only one before/after example is specified. | One upgrade in the tutorial, using your 40 power and 200 health. Increase current health by 20, capped at 200. |
| Freeze input and boost | Duration is known; targeting, charges and boost size are not. | Press F, then click a zombie; one tutorial charge; nearby tower fires every 0.5 seconds while that target is frozen. |
| Zombie progression | Levels are mentioned without progression rules. | One level-1 zombie at 80 health, 90 power, moving at 45 px/second. |
| Kingdom health and damage | Losing and gate attacks are undefined. | Kingdom starts with 300 health; zombies attack the gate using their power and attack interval. |
| Tutorial timing | An attacking tower might kill the zombie before inspection, upgrade and Freeze. | Hold movement/combat until each relevant lesson is acknowledged; resume the fight after Freeze is taught. |
| Mistakes and recovery | Early sales, missed clicks and destroyed towers can strand the tutorial. | Disable selling until the selling lesson; offer retry on destruction; provide explicit placement and gold feedback. |
| Completion and failure | Sphinx's closing line alone does not define success. | Finish after the guided zombie dies and the final dialogue is acknowledged; offer retry if the kingdom falls. |
| Pause and dialogue | Text needs a pace and input policy. | Click Next to advance; Escape pauses; pause stops movement, attacks and ability timers. |
| Art and audience | Age, experience, visual style and platform expectations are unknown. | Windows keyboard/mouse and geometric placeholders initially; confirm age/experience and art direction before polishing. |

## Numbers check

If power means damage per hit, a base tower does 20 damage/second and needs
four hits to defeat an 80-health zombie. The upgraded tower does 40 damage/second
and needs two hits. At the suggested Freeze boost it does 80 damage/second.
Time to kill also depends on when the first shot fires: at one shot/second,
four hits span three seconds if the first hit happens immediately.

A 90-damage zombie defeats a 180-health tower in two hits and a fully healthy
200-health upgraded tower in three. This makes tutorial staging essential.
Power should be shown as a number labeled "Damage per hit" if that meaning is
accepted; a power bar needs a defined maximum. Keep the requested red power and
green health colors, and add text labels so color is not the only cue.

## Tutorial acceptance sequence

1. Start in English; introduce the B key and highlight the Standard tower.
2. Buy exactly one tower; remove the arrow; teach B to close the shop.
3. Introduce Sphinx, zombies and the kingdom with dialogue and camera focus.
4. Highlight legal wall sockets; place the purchased tower without charging twice.
5. Click the zombie to inspect level, health and power; then inspect the tower.
6. Upgrade once; show the change from 180/20 to 200/40 clearly.
7. Teach targeting Freeze; demonstrate five seconds of frozen movement/attacks
   and the agreed tower attack boost. Prevent an early kill from skipping this.
8. Finish the encounter; show Sphinx's closing line and a completion/retry screen.

This sequence now has a playable implementation using adjustable prototype rules.
See GAME_DESIGN.md for the actual values, including 250 px tower range and a
12-second Freeze recharge. Suggestions in the table remain design alternatives,
not owner approvals. Next, playtest the tutorial's clarity and difficulty.

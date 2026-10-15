# Progress

## 2026-10-15 - project foundation

- Read both PDF pages; recorded confirmed design and a separate design review.
- Confirmed English-only initial release and zombies attacking towers/kingdom.
- Extended the existing Compatibility project rather than rebuilding it.
- Added menu, Sphinx tutorial UI shell, B/button shop toggle, restart and return.
- Created a project-local Git repository on main; parent repository preserved.
- No purchasing, placement, combat, stats inspection, upgrades or Freeze yet.
- Verified with installed Godot 4.7.2: headless editor import and main-scene
  startup (120 frames) both exit 0, with no script/resource errors.
- A temporary headless interaction check passed: start button opens tutorial,
  injected B input opens shop, button closes it, restart resets shop visibility,
  and Back returns to menu. No combat/economy exists to validate yet.
- Visual layout and real keyboard/mouse feel are not manually verified. Run F5
  and check menu, B/button toggles, restart and Back at your window size.
- Git author: hongyang <hongyangliu1987@gmail.com>, configured locally only.
  A narrowly scoped Git safe.directory entry permits the Windows user to use
  this repository created by the sandbox account. No remote/publication.
- Export templates remain uninstalled; no exported build has been verified.

Next: agree on power/targeting rules, then implement buying and wall placement.
Try changing guide_name on the Tutorial root in the Inspector as a first exercise.

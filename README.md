# FirstGodotGameTowerDefence

A 2D kingdom-versus-zombies tower defence game, guided by Sphinx.
First release goal: the tutorial from the owner's design document.
Current build: interactive project shell; combat is not implemented yet.

## Open and try it

1. Double-click Open-Godot.cmd, or import project.godot in Godot.
2. Press F5 to run the project.
3. Choose Open tutorial shell. Press B or click Tower shop to open/close it.
4. Try Restart shell and Back to menu. Quit closes the game from the menu.

Use Godot 4.7.2 stable standard edition, with built-in GDScript and Compatibility
rendering. No additional runtime or plugins are needed. Export templates are not
installed yet; running in the editor does not validate an exported build.

```powershell
./tools/godot.ps1 -e
./tools/godot.ps1 --headless --editor --import
./tools/godot.ps1 --headless --quit-after 120
./tools/godot.ps1 --headless res://scenes/tutorial/tutorial.tscn --quit-after 120
```

The launcher finds the installed engine without changing PATH. On another
machine set GODOT_EXECUTABLE to its console executable and verify the version.

## Project map

- scenes/main.tscn and scripts/main.gd: menu and project entry point.
- scenes/tutorial/ and scripts/tutorial/: tutorial UI shell.
- docs/GAME_DESIGN.md: confirmed requirements and open decisions.
- docs/DESIGN_REVIEW.md: missing rules, proposed values and implementation sequence.
- docs/PROGRESS.md: implemented features, validation and next milestone.
- assets/ASSET_SOURCES.md: source/license ledger; no external assets currently.
- AGENTS.md: development guidance. Owner requested English communication in chat.

Keep scenes editable in Godot; add tower/enemy scenes and configuration resources
when those features are implemented. Avoid placeholder frameworks with no use yet.

## Git

This folder has its own repository on main, independent of the existing parent
environment-setup repository. Author identity is local to this repository.
No remote is configured and nothing has been published.

```powershell
git status
git log --oneline
git add .
git commit -m "Describe the change"
```

.godot/, tmp/, output/ and builds/ are ignored; commit required .uid and import
metadata alongside source assets. Work on only one computer at a time when using
this OneDrive folder.

First small exercise: open the Tutorial scene, select its root, and change
Guide Name in the Inspector. Run it with F6 to see the guide name change.

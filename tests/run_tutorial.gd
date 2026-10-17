extends SceneTree
## Deterministic integration checks of real scenes, signals, input and combat.
## Run: ./tools/godot.ps1 --headless --script res://tests/run_tutorial.gd

var failures: int = 0
var checks: int = 0
var capture: bool = false
var tutorial: Variant


func _initialize() -> void:
    capture = "--capture" in OS.get_cmdline_user_args()
    _run.call_deferred()


func _check(condition: bool, message: String) -> void:
    checks += 1
    if not condition:
        failures += 1
        push_error("CHECK FAILED: " + message)


func _key(code: Key) -> void:
    var event := InputEventKey.new()
    event.keycode = code
    event.physical_keycode = code
    event.pressed = true
    Input.parse_input_event(event)
    await process_frame
    event = InputEventKey.new()
    event.keycode = code
    event.physical_keycode = code
    event.pressed = false
    Input.parse_input_event(event)
    await process_frame


func _mouse_click(point: Vector2) -> void:
    var motion := InputEventMouseMotion.new()
    motion.position = point
    motion.global_position = point
    root.push_input(motion, true)
    var event := InputEventMouseButton.new()
    event.button_index = MOUSE_BUTTON_LEFT
    event.pressed = true
    event.position = point
    event.global_position = point
    root.push_input(event, true)
    event = InputEventMouseButton.new()
    event.button_index = MOUSE_BUTTON_LEFT
    event.pressed = false
    event.position = point
    event.global_position = point
    root.push_input(event, true)
    await process_frame
    await process_frame


func _click(point: Vector2) -> void:
    await _mouse_click(tutorial.board.get_global_transform() * point)


func _press_button(button: Button) -> void:
    # Visibility/text changes queue container layout for the following frame.
    await process_frame
    await process_frame
    await _mouse_click(button.get_global_rect().get_center())


func _snap(name: String) -> void:
    if not capture:
        return
    await process_frame
    await process_frame
    await RenderingServer.frame_post_draw
    var result: int = root.get_texture().get_image().save_png("res://tmp/" + name + ".png")
    _check(result == OK, "Screenshot saved: " + name)


func _load_tutorial() -> void:
    change_scene_to_file("res://scenes/tutorial/tutorial.tscn")
    await process_frame
    await process_frame
    tutorial = current_scene
    tutorial.set_process(false)
    tutorial.board.set_process(false)


func _guided(socket_index: int) -> void:
    if socket_index == 0:
        await _press_button(tutorial.get_node("HUD/TopBar/Shop"))
    else:
        await _key(KEY_B)
    _check(tutorial.shop.visible and tutorial.step == tutorial.Step.BUY, "B opens the guided shop")
    _check(tutorial.get_node("TutorialCue").focus_id == "Buy", "Required buy button is highlighted")
    if socket_index == 0:
        await _snap("tutorial-shop")
    await _press_button(tutorial.shop.get_node("Card/Contents/Buy"))
    _check(tutorial.gold == 50 and tutorial.pending_tower, "Purchase charges exactly 100")
    _check(not tutorial.has_node("HUD/Dialogue/Text/Next"), "Dialogue has no Next or confirmation button")
    tutorial._buy()
    _check(tutorial.gold == 50, "Repeated purchase is blocked")
    _check(not tutorial.shop.visible and tutorial.step == tutorial.Step.PLACE, "Buying closes the popup automatically and introduces Sphinx")
    _check(tutorial.board.towers.is_empty(), "Purchase click does not also place a tower behind the popup")
    if socket_index == 0:
        var hover := InputEventMouseMotion.new()
        hover.position = tutorial.board.get_global_transform() * tutorial.board.cell_center(tutorial.board.RECOMMENDED_CELLS[2])
        root.push_input(hover, true)
        tutorial._refresh_stats()
        _check(tutorial.get_node("TutorialCue").focus_rect == tutorial.board.cell_rect(tutorial.board.RECOMMENDED_CELLS[2]), "Placement cue follows the green hover preview rather than the zombie cell")
        await _snap("tutorial-grid")
    await _click(Vector2(40, 40))
    _check(tutorial.pending_tower and tutorial.gold == 50, "Illegal placement retains purchase without charging")
    await _click(tutorial.board.cell_center(tutorial.board.RECOMMENDED_CELLS[socket_index]))
    _check(tutorial.step == tutorial.Step.TOWER and tutorial.board.towers.size() == 1, "Placement creates one tower")
    _check(not tutorial.get_node("HUD/SelectionCard").visible, "Placing a tower does not open its upgrade popup")
    var zombie: TutorialZombie = tutorial.board.zombie
    _check(zombie.get_node("Health/Value").visible and zombie.get_node("Health/Value").text == "80 / 80", "Enemy health is visible overhead without clicking")
    _check(zombie.get_node("Health").get_global_rect().encloses(zombie.get_node("Health/Value").get_global_rect()), "Zombie health number is inside its health bar")
    await _click(zombie.position + Vector2(0, -20))
    _check(tutorial.step == tutorial.Step.TOWER and not tutorial.side.get_node("Extra").text.contains("Kill reward") and not tutorial.side.get_node("PowerLabel").text.contains("90"), "Enemy click cannot reveal strength or reward")
    await process_frame
    await process_frame
    await _snap("tutorial-health-" + str(socket_index))
    _check(tutorial.step == tutorial.Step.TOWER, "Placement advances automatically to tower inspection")
    await _click(tutorial.board.cell_center(tutorial.board.RECOMMENDED_CELLS[socket_index]) + Vector2(0, -20))
    _check(tutorial.step == tutorial.Step.UPGRADE, "Tower click advances inspection")
    _check(tutorial.get_node("HUD/SelectionCard").visible, "Explicit tower click opens contextual upgrades")
    _check(tutorial.get_node("TutorialCue").focus_id == "Upgrade", "Required upgrade button is highlighted")
    if socket_index == 0:
        await _snap("tutorial-upgrade-popup")
    await _press_button(tutorial.side.get_node("Upgrade"))
    var tower: DefenseTower = tutorial.selected_tower
    _check(tutorial.gold == 0 and tower.health == 200 and tower.power == 40, "Upgrade applies stats and cost")
    if socket_index == 0:
        tower._process(0.4)
        await _snap("tutorial-upgrade-animation")
    _check(not tutorial.get_node("HUD/SelectionCard").visible, "Successful upgrade dismisses the popup")
    tutorial._upgrade()
    _check(tutorial.gold == 0, "Upgrade cannot charge twice")
    var start: Vector2 = zombie.position
    tutorial._process(3.0)
    _check(zombie.position == start and zombie.health == 80, "Combat waits for lessons")
    await _click(tower.position)
    if socket_index == 0:
        await _snap("tutorial-tower-skills")
        await _press_button(tutorial.side.get_node("Skills/Q"))
    else:
        await _key(KEY_Q)
    await _click(zombie.position + Vector2(0, -20))
    _check(zombie.freeze_left == 5.0 and tutorial.step == tutorial.Step.FIGHT, "Tower Q or skill click freezes for five seconds and starts combat")
    await _key(KEY_ESCAPE)
    tutorial._process(2.0)
    _check(zombie.freeze_left == 5.0 and zombie.health == 80, "Pause stops damage and Freeze timer")
    await _key(KEY_ESCAPE)
    if socket_index == 0:
        await _snap("tutorial-freeze")
    for tick: int in 1500:
        tutorial._process(0.1)
        await process_frame
        if tutorial.step == tutorial.Step.DEBRIEF:
            break
    _check(tutorial.step == tutorial.Step.DEBRIEF and tutorial.gold == 25, "Guided zombie defeated once and rewards 25")


func _run() -> void:
    change_scene_to_file("res://scenes/main.tscn")
    await process_frame
    await process_frame
    # Allow the OS to finish a requested fullscreen transition before aiming.
    await create_timer(0.2).timeout
    var start: Button = current_scene.get_node("Center/Menu/Start")
    await _snap("modern-main-menu")
    await _press_button(start)
    await process_frame
    _check(current_scene.scene_file_path == "res://scenes/tutorial/tutorial.tscn", "Actual mouse click starts tutorial from menu")
    await process_frame
    await process_frame
    var opening_guide: Label = current_scene.get_node("HUD/Dialogue/Text/Guide")
    var opening_panel: Panel = current_scene.get_node("HUD/Dialogue")
    _check(opening_panel.visible and opening_guide.is_visible_in_tree() and opening_guide.text == "Sphinx: Open the shop: cart icon or B.", "Play tutorial displays Sphinx's opening instruction")
    _check(opening_panel.get_global_rect().encloses(opening_guide.get_global_rect()), "Opening text fits inside the dialogue instead of extending below the screen")
    await _snap("tutorial-opening")
    await _load_tutorial()
    _check(tutorial.board.size == Vector2(1152, 648) and not tutorial.has_node("HUD/Rail"), "Full-width battlefield has no sidebar reservation")
    await _press_button(tutorial.get_node("HUD/TopBar/Settings"))
    _check(tutorial.is_paused and tutorial.get_node("SettingsOverlay").visible, "Top-right gear opens settings and pauses combat")
    await _key(KEY_B)
    _check(not tutorial.shop.visible, "Shop shortcut cannot open behind settings")
    await _snap("tutorial-settings")
    await _press_button(tutorial.get_node("SettingsOverlay/Card/Contents/Resume"))
    _check(not tutorial.is_paused and not tutorial.get_node("SettingsOverlay").visible, "Resume closes settings")
    var dialogue: Panel = tutorial.get_node("HUD/Dialogue")
    var dialogue_toggle: Button = tutorial.get_node("HUD/DialogueToggle")
    await _press_button(dialogue_toggle)
    _check(not dialogue.visible and dialogue_toggle.text == "?", "Hide uncovers the bottom grid cells")
    await _press_button(dialogue_toggle)
    _check(dialogue.visible and dialogue_toggle.text == "×", "Sphinx button restores the bottom dialogue")
    await _guided(0)
    tutorial._process(tutorial.message_read_seconds + 0.1)
    _check(tutorial.step == tutorial.Step.PRACTICE, "Debrief automatically starts practice without a Next button")
    # An unaffordable purchase must never create negative gold.
    await _key(KEY_B)
    tutorial._buy()
    _check(tutorial.gold == 25 and not tutorial.pending_tower, "Insufficient funds block purchase")
    var start_position: Vector2 = tutorial.board.zombie.position
    tutorial._process(3.0)
    _check(tutorial.board.zombie.position == start_position, "Open shop holds combat")
    await _key(KEY_B)
    var boss_seen: bool = false
    var boss_frozen: bool = false
    var recharge_tested: bool = false
    for tick: int in 2000:
        if tutorial.practice_left == 1 and not is_instance_valid(tutorial.board.zombie) and not recharge_tested:
            tutorial.freeze_cooldown = 10.0
            recharge_tested = true
        tutorial._process(0.1)
        tutorial.board._process(0.1)
        await process_frame
        if tutorial.step == tutorial.Step.SEMIBOSS:
            boss_seen = true
            var boss: TutorialZombie = tutorial.board.zombie
            _check(tutorial.practice_left == 1 and boss.is_semiboss and boss.health == 600, "Only the final wave enemy is the stronger semiboss")
            _check(boss.get_node("Health/Value").text == "600 / 600", "Semiboss health is also visible overhead")
            await _click(boss.position + Vector2(0, -20))
            _check(not tutorial.side.get_node("Extra").text.contains("75") and not tutorial.side.get_node("PowerLabel").text.contains("110"), "Semiboss click keeps strength and reward hidden")
            _check(tutorial.guide.text.contains("end of every wave") and tutorial.guide.text.contains("Use Freeze"), "Sphinx introduces the semiboss and Freeze strategy")
            _check(tutorial.freeze_cooldown == 0.0, "Freeze is refreshed for the semiboss introduction")
            var boss_start: Vector2 = boss.position
            tutorial._process(3.0)
            _check(boss.position == boss_start and boss.health == 600, "Semiboss waits while its introduction is read")
            await _snap("tutorial-semiboss")
            tutorial._process(tutorial.message_read_seconds + 0.1)
        if boss_seen and not boss_frozen and tutorial.step == tutorial.Step.PRACTICE and is_instance_valid(tutorial.board.zombie) and tutorial.board.zombie.position.x >= tutorial.board.towers[0].position.x - 170.0:
            var boss: TutorialZombie = tutorial.board.zombie
            await _click(tutorial.board.towers[0].position)
            await _key(KEY_Q)
            await _click(boss.position + Vector2(0, -20))
            _check(boss.freeze_left == 5.0, "Semiboss can be stopped by F + click Freeze")
            var frozen_position: Vector2 = boss.position
            tutorial._process(0.1)
            _check(boss.position == frozen_position and boss.freeze_left > 0.0, "Frozen semiboss cannot move")
            boss_frozen = true
            await _snap("tutorial-semiboss-freeze")
        if tutorial.step in [tutorial.Step.WON, tutorial.Step.LOST]:
            break
    _check(boss_seen and boss_frozen, "Wave ends with a playable semiboss encounter")
    _check(tutorial.step == tutorial.Step.WON, "Semiboss wave is winnable with Freeze")
    _check(tutorial.gold == 150 and tutorial.kingdom_health > 0, "Regular kills reward 25 and semiboss rewards 75 once")
    _check(not tutorial.hint.text.contains("75"), "Kill feedback does not disclose the reward amount")
    tutorial.board._process(1.0)
    var celebration: Control = tutorial.get_node("VictoryCelebration")
    _check(celebration.visible and not tutorial.get_node("HUD/Dialogue").visible, "Victory opens a centered celebration instead of the lesson strip")
    await create_timer(1.35).timeout
    _check(celebration.get_node("Content/Quit").visible, "Quit appears beneath the celebration after its entrance")
    await _snap("tutorial-victory")
    await _press_button(celebration.get_node("Content/Quit"))
    await process_frame
    _check(current_scene.scene_file_path == "res://scenes/main.tscn", "Celebration Quit returns to the main screen without closing the game")
    await _press_button(current_scene.get_node("Center/Menu/Start"))
    await process_frame
    tutorial = current_scene
    tutorial.set_process(false)
    tutorial.board.set_process(false)
    # Restart must clear actors, gold, ability state and tutorial progress.
    tutorial._restart()
    await process_frame
    await process_frame
    tutorial = current_scene
    tutorial.set_process(false)
    tutorial.board.set_process(false)
    _check(tutorial.gold == 150 and tutorial.board.towers.is_empty() and tutorial.step == tutorial.Step.SHOP, "Restart resets all run state")
    await _guided(1)
    tutorial._process(tutorial.message_read_seconds + 0.1)
    tutorial.selected_tower = tutorial.board.towers[0]
    tutorial._sell()
    tutorial._sell()
    _check(tutorial.gold == 100, "Selling upgraded tower returns 75 exactly once")
    await process_frame
    for tick: int in 2000:
        tutorial._process(0.1)
        await process_frame
        if tutorial.step == tutorial.Step.LOST:
            break
    _check(tutorial.step == tutorial.Step.LOST and tutorial.kingdom_health == 0, "Undefended gate takes damage and triggers defeat")
    tutorial.board._process(1.0)
    await _snap("tutorial-defeat")
    await _load_tutorial()
    await _guided(2)
    _check(tutorial.step == tutorial.Step.DEBRIEF, "Example grid cells can finish guided combat")
    # Isolated actor checks cover timing/range/death guards without copying formulas.
    var config: TutorialBalance = tutorial.balance
    var tower: DefenseTower = tutorial.board.towers[0]
    var zombie: TutorialZombie = tutorial.board.spawn_zombie(config, 600.0)
    tower.position = Vector2(620, 150)
    zombie.position = Vector2(620, 210)
    tower.health = 200
    zombie.tick(0.1, tutorial.board.towers, tutorial.board.GATE)
    _check(tower.health == 110, "Zombie attacks a nearby tower for 90")
    zombie.tick(1.0, tutorial.board.towers, tutorial.board.GATE)
    _check(tower.health == 110, "Zombie respects melee attack interval")
    zombie.freeze(5.0)
    zombie.tick(2.0, tutorial.board.towers, tutorial.board.GATE)
    _check(zombie.freeze_left == 3.0 and tower.health == 110, "Freeze stops zombie attacks and counts down")
    zombie.tick(3.0, tutorial.board.towers, tutorial.board.GATE)
    _check(zombie.freeze_left == 0.0, "Freeze expires after five simulated seconds")
    tower.cooldown = 0.0
    zombie.position = Vector2(0, 210)
    tower.tick(1.0, zombie)
    _check(zombie.health == 80, "Tower cannot shoot beyond range")
    zombie.position = Vector2(620, 210)
    tower.tick(0.1, zombie)
    _check(zombie.health == 40, "Upgraded tower deals 40 per hit")
    _check(zombie.get_node("Health/Value").text == "40 / 80", "Overhead health number follows actual damage")
    tower.tick(0.1, zombie)
    _check(zombie.health == 40, "Tower respects shot interval")
    var deaths: Array[int] = [0]
    zombie.died.connect(func() -> void: deaths[0] += 1)
    zombie.freeze(5.0)
    tower.cooldown = 0.0
    tower.tick(0.0, zombie)
    _check(is_equal_approx(tower.cooldown, config.boosted_interval), "Frozen target grants the faster shot interval")
    zombie.take_damage(100)
    zombie.take_damage(100)
    _check(deaths[0] == 1, "Repeated lethal hits emit one death")
    await process_frame
    var boss: TutorialZombie = tutorial.board.spawn_zombie(config, 60.0, true)
    boss.died.connect(tutorial._on_zombie_died.bind(boss))
    var gold_before: int = tutorial.gold
    boss.take_damage(999)
    boss.take_damage(999)
    _check(tutorial.gold == gold_before + 75, "Repeated semiboss lethal hits award gold exactly once")
    await process_frame
    var original_count: int = config.practice_zombies
    config.practice_zombies = 1
    tutorial._process(tutorial.message_read_seconds + 0.1)
    _check(tutorial.step == tutorial.Step.SEMIBOSS and tutorial.board.zombie.is_semiboss, "A new one-enemy wave also ends with a semiboss")
    config.practice_zombies = original_count
    # A later purchase also closes automatically and allows immediate placement.
    await _load_tutorial()
    tutorial._set_step(tutorial.Step.PRACTICE)
    await _press_button(tutorial.get_node("HUD/TopBar/Shop"))
    await _press_button(tutorial.shop.get_node("Card/Contents/Buy"))
    _check(not tutorial.shop.visible and tutorial.gold == 50 and tutorial.pending_tower, "Practice purchase closes shop and charges once")
    await _click(tutorial.board.cell_center(45))
    _check(not tutorial.pending_tower and tutorial.board.occupied(45), "Bottom-row placement remains accessible after purchase")
    tutorial._deselect_tower()
    _check(not tutorial.get_node("HUD/SelectionCard").visible, "Tower details disappear when dismissed")
    # Back to menu is still wired after a full game.
    tutorial._back_to_menu()
    await process_frame
    await process_frame
    _check(current_scene.scene_file_path == "res://scenes/main.tscn", "Back returns to menu")
    print("TUTORIAL CHECKS: %d checks, %d failures" % [checks, failures])
    root.get_node("Sfx").stop_all()
    root.get_node("Music").stop()
    await create_timer(0.1).timeout
    quit(1 if failures > 0 else 0)

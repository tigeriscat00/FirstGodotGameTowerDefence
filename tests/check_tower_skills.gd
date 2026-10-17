extends SceneTree

var checks: int = 0
var failures: int = 0


func _initialize() -> void:
    _run.call_deferred()


func _check(condition: bool, message: String) -> void:
    checks += 1
    if not condition:
        failures += 1
        push_error(message)


func _key(code: Key) -> void:
    var event := InputEventKey.new()
    event.physical_keycode = code
    event.pressed = true
    Input.parse_input_event(event)
    await process_frame
    event = InputEventKey.new()
    event.physical_keycode = code
    Input.parse_input_event(event)
    await process_frame


func _run() -> void:
    change_scene_to_file("res://scenes/tutorial/tutorial.tscn")
    await process_frame
    await process_frame
    var tutorial: Variant = current_scene
    tutorial.set_process(false)
    tutorial.board.set_process(false)
    tutorial._set_step(tutorial.Step.PRACTICE)
    tutorial.practice_left = 3
    var first: DefenseTower = tutorial.board.add_tower(24, tutorial.balance)
    var second: DefenseTower = tutorial.board.add_tower(26, tutorial.balance)
    first.destroyed.connect(tutorial._on_tower_destroyed)
    second.destroyed.connect(tutorial._on_tower_destroyed)
    var zombie: TutorialZombie = tutorial.board.spawn_zombie(tutorial.balance)
    await _key(KEY_Q)
    _check(not tutorial.board.freeze_aiming, "Q requires an explicitly selected tower")
    tutorial._on_board_clicked(first.position)
    for slot: int in 4:
        var button: Button = tutorial.side.get_node("Skills/" + "QWER"[slot])
        _check(button.get_node("Key").text == "QWER"[slot], "Each skill slot shows its own hotkey")
        _check(button.disabled == (slot != 0), "Unused slots are disabled")
    for code: Key in [KEY_W, KEY_E, KEY_R]:
        await _key(code)
        _check(not tutorial.board.freeze_aiming, "Unassigned key cannot activate Freeze")
    await _key(KEY_F)
    _check(not tutorial.board.freeze_aiming, "Old global F shortcut no longer casts")
    await _key(KEY_Q)
    _check(tutorial.board.freeze_aiming and not tutorial.tower_popup_open, "Q starts targeting and dismisses the popup")
    await _key(KEY_ESCAPE)
    _check(not tutorial.board.freeze_aiming and first.freeze_cooldown == 0.0, "Escape cancels targeting without spending cooldown")
    tutorial._on_board_clicked(first.position)
    await _key(KEY_Q)
    tutorial._on_board_clicked(zombie.position)
    _check(zombie.freeze_left == 5.0 and first.freeze_cooldown == 12.0 and second.freeze_cooldown == 0.0, "Only the casting tower starts cooldown")
    tutorial._on_board_clicked(first.position)
    await _key(KEY_Q)
    _check(not tutorial.board.freeze_aiming, "Cooldown prevents keyboard reuse")
    tutorial._toggle_pause()
    tutorial._process(2.0)
    _check(first.freeze_cooldown == 12.0, "Settings pause tower skill cooldowns")
    tutorial._toggle_pause()
    tutorial._toggle_shop()
    tutorial._process(2.0)
    _check(first.freeze_cooldown == 12.0, "Shop pauses tower skill cooldowns")
    tutorial._toggle_shop()
    tutorial._process(2.0)
    _check(first.freeze_cooldown == 10.0, "Unselected towers still recharge during combat")
    second.skills = [&"", &"", &"", &"freeze", &"freeze"]
    _check(second.skills.size() == 4, "Tower configuration cannot exceed four skills")
    tutorial._on_board_clicked(second.position)
    await _key(KEY_Q)
    _check(not tutorial.board.freeze_aiming, "Empty Q cannot activate a skill assigned to R")
    await _key(KEY_R)
    _check(tutorial.board.freeze_aiming, "R activates the fourth configured skill")
    tutorial._on_board_clicked(zombie.position)
    _check(second.freeze_cooldown == 12.0 and first.freeze_cooldown == 10.0, "Second tower casts independently of the first tower")
    second.freeze_cooldown = 0.0
    tutorial._on_board_clicked(second.position)
    await _key(KEY_R)
    second.take_damage(999)
    _check(not tutorial.board.freeze_aiming and not tutorial.tower_popup_open, "Destroying the caster cancels pending targeting")
    print("TOWER SKILL CHECKS: %d checks, %d failures" % [checks, failures])
    root.get_node("Sfx").stop_all()
    root.get_node("Music").stop()
    await create_timer(0.1).timeout
    quit(1 if failures else 0)

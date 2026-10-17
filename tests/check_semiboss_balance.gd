extends SceneTree
## Exercise the real encounter at every build cell and several frame rates.

var checks: int = 0
var failures: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _encounter(socket: int, use_freeze: bool, delta: float) -> void:
	change_scene_to_file("res://scenes/tutorial/tutorial.tscn")
	await process_frame
	await process_frame
	var tutorial: Variant = current_scene
	tutorial.set_process(false)
	tutorial.board.set_process(false)
	# Normal state after the guided lesson and two regular kills.
	tutorial.gold = 75
	tutorial.practice_left = 1
	var tower: DefenseTower = tutorial.board.add_tower(socket, tutorial.balance)
	tower.upgrade()
	tower.destroyed.connect(tutorial._on_tower_destroyed)
	tutorial.selected_tower = tower
	tutorial._set_step(tutorial.Step.PRACTICE)
	tutorial._spawn_zombie()
	tutorial._process(tutorial.message_read_seconds + 0.1)
	var cast: bool = false
	for tick: int in ceili(80.0 / delta):
		if use_freeze and not cast and is_instance_valid(tutorial.board.zombie) and tutorial.board.zombie.position.x >= tutorial.board.cell_center(socket).x - 170.0:
			tutorial._aim_freeze()
			tutorial._on_board_clicked(tutorial.board.zombie.position + Vector2(0, -20))
			cast = true
		tutorial._process(delta)
		if tutorial.step in [tutorial.Step.WON, tutorial.Step.LOST]:
			break
	var expected: int = tutorial.Step.WON if use_freeze else tutorial.Step.LOST
	checks += 1
	if tutorial.step != expected or (use_freeze and not cast):
		failures += 1
		push_error("Balance failed at socket %d, Freeze=%s, delta=%.4f: step=%d" % [socket, use_freeze, delta, tutorial.step])


func _run() -> void:
	for delta: float in [1.0 / 60.0, 1.0 / 30.0, 0.1]:
		for socket: int in range(TutorialBattlefield.COLUMNS * TutorialBattlefield.ROWS):
			if socket % TutorialBattlefield.COLUMNS < TutorialBattlefield.FIRST_BUILD_COLUMN or socket / TutorialBattlefield.COLUMNS < TutorialBattlefield.FIRST_BUILD_ROW:
				continue
			await _encounter(socket, false, delta)
			await _encounter(socket, true, delta)
	print("SEMIBOSS BALANCE: %d checks, %d failures" % [checks, failures])
	root.get_node("Sfx").stop_all()
	root.get_node("Music").stop()
	await create_timer(0.1).timeout
	quit(1 if failures > 0 else 0)

extends SceneTree

var checks: int = 0
var failures: int = 0

func _initialize() -> void:
	_run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func _run() -> void:
	change_scene_to_file("res://scenes/stage_one.tscn")
	await process_frame
	await process_frame
	var stage: Variant = current_scene
	stage.set_process(false)
	stage.gold = 17
	stage.board.add_stage_tower(24, stage.balance, false)
	stage._gate_hit(9999)
	var screen: Control = stage.get_node("DefeatScreen")
	check(stage.finished and screen.visible, "Stage loss shows the defeat overlay")
	check(screen.get_node("Content/Title").text == "DEFEAT", "Overlay has the large defeat label")
	check(screen.get_node("Content/Restart").visible and screen.get_node("Content/Menu").visible, "Both defeat buttons are available")
	check(screen.mouse_filter == Control.MOUSE_FILTER_STOP, "Defeat overlay blocks battlefield input")
	var before: float = screen.elapsed
	screen._process(0.1)
	check(screen.elapsed > before, "Lightning animation advances")
	stage._gate_hit(9999)
	check(stage.kingdom_health == 0 and screen.visible, "Repeated gate damage does not reopen defeat")
	screen.get_node("Content/Restart").pressed.emit()
	await process_frame
	await process_frame
	stage = current_scene
	check(stage.scene_file_path == "res://scenes/stage_one.tscn" and not stage.finished and stage.gold == 200 and stage.board.towers.is_empty(), "Try again starts a clean Stage 1 run")
	check(not stage.get_node("DefeatScreen").visible, "Restart hides the old overlay")
	stage._gate_hit(9999)
	stage.get_node("DefeatScreen/Content/Menu").pressed.emit()
	await process_frame
	await process_frame
	check(current_scene.scene_file_path == "res://scenes/main.tscn", "Stage defeat menu returns to main menu")
	change_scene_to_file("res://scenes/tutorial/tutorial.tscn")
	await process_frame
	await process_frame
	var tutorial: Variant = current_scene
	tutorial._set_step(tutorial.Step.PRACTICE)
	tutorial._on_gate_hit(9999)
	check(tutorial.step == tutorial.Step.LOST and tutorial.get_node("DefeatScreen").visible, "Tutorial loss also shows the overlay")
	tutorial.get_node("DefeatScreen/Content/Restart").pressed.emit()
	await process_frame
	await process_frame
	tutorial = current_scene
	check(tutorial.step == tutorial.Step.SHOP and tutorial.gold == tutorial.balance.starting_gold and not tutorial.get_node("DefeatScreen").visible, "Tutorial try again resets its lesson")
	root.get_node("Sfx").stop_all()
	root.get_node("Music").stop()
	await create_timer(0.1).timeout
	print("DEFEAT CHECKS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

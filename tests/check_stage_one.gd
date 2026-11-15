extends SceneTree

var failures: int = 0
var checks: int = 0
var stage: Variant
const TEST_SAVE: String = "user://stage_test_progress.cfg"

func _initialize() -> void:
	_run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func make_stage() -> Variant:
	var instance: Variant = load("res://scenes/stage_one.tscn").instantiate()
	instance.progress_path = TEST_SAVE
	root.add_child(instance)
	instance.set_process(false)
	return instance

func _run() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE))
	stage = make_stage()
	await process_frame
	check(stage.gold == 200 and stage.waiting == 10.0, "Start resources")
	stage._toggle_shop()
	stage._process(1.0)
	check(stage.waiting == 9.0, "Preparation continues while shop is open")
	stage._buy("standard")
	check(stage.gold == 100 and stage.pending == "standard", "Purchase charges once")
	var cell: int = stage.board.build_cells()[0]
	stage._board_click(stage.board.cell_center(cell))
	check(stage.board.towers.size() == 1 and stage.pending == "", "Place tower")
	stage._board_click(stage.board.cell_center(cell))
	stage._upgrade()
	check(stage.gold == 50 and stage.board.towers[0].power == 40, "First upgrade")
	check(stage.board.towers[0].get_node("Art").texture.resource_path == "res://assets/generated/realistic_tower_upgraded.png", "First upgrade keeps the unlit ballistas")
	stage._board_click(stage.board.cell_center(cell))
	stage.gold = 150
	stage._upgrade()
	check(stage.gold == 50 and stage.board.towers[0].power == 60 and stage.board.towers[0].tier == 2, "Fire bow upgrade")
	check(stage.board.towers[0].get_node("Art").texture.resource_path == "res://assets/generated/realistic_tower_fire_bow.png", "Final upgrade shows fire on both ballistas")
	stage._spawn_enemy("dog")
	var practice: TutorialZombie = stage.board.enemies.back()
	var dog_art: Sprite2D = practice.get_node("Art")
	check(dog_art.visible and dog_art.texture.resource_path == "res://assets/generated/realistic_zombie_dog_run.png" and dog_art.hframes == 4 and dog_art.vframes == 2, "Dog displays the eight-pose running sheet")
	var original_frame: int = dog_art.frame
	var no_towers: Array[DefenseTower] = []
	practice.tick(0.25, no_towers, Vector2(904, practice.position.y))
	check(dog_art.frame != original_frame, "Dog changes running pose while moving")
	practice.position = stage.board.towers[0].position + Vector2(-100, 0)
	stage._board_click(stage.board.cell_center(cell))
	stage._skill(0)
	stage._board_click(practice.position + Vector2(0, -20))
	check(practice.freeze_left == 5.0 and stage.board.towers[0].freeze_cooldown == 12.0, "Freeze targets a selected enemy")
	check(dog_art.modulate != Color.WHITE, "Frozen dog sprite has ice tint")
	var frozen_art_position: Vector2 = dog_art.position
	var frozen_frame: int = dog_art.frame
	practice.tick(0.1, [], Vector2(904, practice.position.y))
	check(dog_art.position == frozen_art_position and dog_art.frame == frozen_frame, "Frozen dog sprite holds its pose")
	stage._toggle_pause()
	stage._process(1.0)
	check(is_equal_approx(practice.freeze_left, 4.9) and stage.board.towers[0].freeze_cooldown == 12.0, "Pause stops combat timers")
	stage._toggle_pause()
	practice.tick(5.0, no_towers, Vector2(904, practice.position.y))
	practice.position = stage.board.towers[0].position + Vector2(-50, 0)
	var attack_position: Vector2 = practice.position
	practice.tick(0.1, stage.board.towers, Vector2(904, practice.position.y))
	check(dog_art.frame == 0 and practice.position == attack_position, "Attacking dog stops its run animation")
	stage.board.tick_stage(0.1)
	check(practice.settled, "Tower fires and damages an in-range enemy")
	await process_frame
	stage.board.tick_stage(0.01)
	stage._spawn_enemy("toilet")
	var armored: TutorialZombie = stage.board.enemies.back()
	var toilet_art: Sprite2D = armored.get_node("Art")
	check(toilet_art.texture.resource_path == "res://assets/generated/toilet_zombie_walk.png" and toilet_art.hframes == 4 and toilet_art.vframes == 2, "Toilet zombie uses the eight-pose armored artwork")
	check(armored.health == 200 and armored.power == 35 and armored.move_speed == 27.0 and armored.gold_reward == 10, "Toilet zombie gameplay stats remain unchanged")
	var toilet_initial_frame: int = toilet_art.frame
	armored.tick(0.5, no_towers, Vector2(904, armored.position.y))
	check(toilet_art.frame != toilet_initial_frame, "Toilet zombie advances its walking pose")
	armored.freeze(5.0)
	var toilet_frozen_frame: int = toilet_art.frame
	var toilet_frozen_position: Vector2 = toilet_art.position
	armored.tick(1.0, no_towers, Vector2(904, armored.position.y))
	check(toilet_art.frame == toilet_frozen_frame and toilet_art.position == toilet_frozen_position and toilet_art.modulate != Color.WHITE, "Frozen toilet zombie holds its pose and shows ice tint")
	armored.tick(4.0, no_towers, Vector2(904, armored.position.y))
	armored.position = stage.board.towers[0].position + Vector2(-50, 0)
	var toilet_attack_position: Vector2 = armored.position
	armored.tick(0.1, stage.board.towers, Vector2(904, armored.position.y))
	check(toilet_art.frame == 0 and armored.position == toilet_attack_position, "Attacking toilet zombie stops walking")
	armored.take_damage(10000)
	await process_frame
	stage.board.tick_stage(0.01)
	for wave: int in range(1, 6):
		stage._start_wave()
		var expected: Array[int] = [8, 10, 11, 14, 20]
		check(stage.queue.size() == expected[wave - 1], "Wave %d count" % wave)
		if wave > 1:
			check(stage.queue.back() == ("boss" if wave == 5 else "semiboss"), "Wave finale")
		while not stage.queue.is_empty():
			var kind: String = stage.queue.pop_front()
			stage._spawn_enemy(kind)
			var enemy: TutorialZombie = stage.board.enemies.back()
			check(enemy.position.y >= 100 and enemy.health > 0, "Valid spawn")
			var old_gold: int = stage.gold
			var payout: int = 20 if kind == "boss" else (15 if kind == "semiboss" else 10)
			check(enemy.gold_reward == payout, "%s has the requested reward" % kind)
			enemy.take_damage(10000)
			enemy.take_damage(10000)
			check(stage.gold == old_gold + payout, "Reward paid once")
			await process_frame
		stage.board.tick_stage(0.01)
		check(stage.board.enemies.is_empty(), "Dead enemies cleared")
	stage._show_sack()
	for i: int in 4:
		stage._tap_sack()
	check(not stage.brick_unlocked and stage.reward_open, "Four taps leave sack closed")
	stage._tap_sack()
	check(stage.brick_unlocked and stage.finished, "Fifth tap unlocks brick")
	check(stage.get_node("VictoryCelebration/Content/Message").text == "BRICK TOWER UNLOCKED!", "First victory announces the unlock")
	stage.queue_free()
	await process_frame
	stage = make_stage()
	await process_frame
	check(stage.brick_unlocked and stage.brick_button.visible, "Brick unlock persists")
	stage._toggle_shop()
	stage._buy("brick")
	check(stage.gold == 50 and stage.pending == "brick", "Brick purchase")
	stage._board_click(stage.board.cell_center(cell))
	check(stage.board.towers[0].brick and stage.board.towers[0].power == 60, "Brick placement and damage")
	stage._gate_hit(10000)
	stage._toggle_pause()
	check(stage.finished and stage.kingdom_health == 0 and stage.get_node("DefeatScreen").visible and not stage.paused, "Defeat displays the restart screen and blocks the pause menu")
	stage.queue_free()
	await process_frame
	stage = make_stage()
	await process_frame
	check(stage.brick_unlocked, "Brick unlock persists into another replay")
	stage._show_sack()
	for i: int in 5:
		stage._tap_sack()
	check(stage.finished and stage.get_node("VictoryCelebration/Content/Message").text == "THE KINGDOM IS SAFE", "Replay victory does not announce a duplicate unlock")
	stage.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE))
	root.get_node("Sfx").stop_all()
	root.get_node("Music").stop()
	await create_timer(0.1).timeout
	print("STAGE CHECKS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

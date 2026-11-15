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
	var game: Variant = load("res://scenes/stage_one.tscn").instantiate()
	game.progress_path = "user://minion_test_unused.cfg"
	root.add_child(game)
	game.set_process(false)
	game.waiting = 1000.0
	var board: Variant = game.board
	var tower: Variant = board.add_stage_tower(24, game.balance, true)
	game.selected = tower
	game.gold = 99
	game._refresh()
	check(game.side.get_node("Upgrade").disabled and game.side.get_node("Upgrade").text == "Add minions · 100 gold", "Brick upgrade shows its price and blocks insufficient coins")
	game._upgrade()
	check(game.gold == 99 and tower.tier == 0, "Insufficient funds do not charge or upgrade")
	game.gold = 150
	game._upgrade()
	check(game.gold == 50 and tower.tier == 1 and tower.invested == 250, "Upgrade charges 100 coins exactly once")
	check(tower.get_node("Art").texture.resource_path == "res://assets/generated/realistic_brick_recruiter.png", "Upgrade displays the recruitment tower")
	game.selected = tower
	game._upgrade()
	check(game.gold == 50 and tower.tier == 1, "Repeated upgrades cannot charge again")
	game._process(11.9)
	check(board.minions.is_empty(), "First minion waits for 12 seconds")
	game._process(0.1)
	check(board.minions.size() == 1, "First minion appears after 12 seconds")
	var minion: DefenseTower = board.minions[0]
	check(minion.health == 100 and minion.max_health == 100 and minion.power == 10, "Minion has requested health and damage")
	var minion_art: Sprite2D = minion.get_node("Art")
	check(minion_art.texture.resource_path == "res://assets/generated/kingdom_minion_walk_v2.png" and minion_art.hframes == 4 and minion_art.vframes == 2, "Minion uses the eight-pose walk sheet")
	game._toggle_pause()
	game._process(30.0)
	check(board.minions.size() == 1, "Settings pause stops recruitment")
	game._toggle_pause()
	game._toggle_shop()
	game._process(30.0)
	check(board.minions.size() == 1, "Shop pause stops recruitment")
	game._toggle_shop()
	board.tick_recruitment(48.0)
	check(board.minions.size() == 5, "Five minions spawn in one active minute")
	var enemy: TutorialZombie = board.spawn_stage_enemy(game.balance, "standard", 3)
	enemy.position = minion.position + Vector2(-150, 0)
	enemy.died.connect(game._enemy_died.bind(enemy))
	var start: Vector2 = minion.position
	var start_frame: int = minion_art.frame
	minion.tick_minion(0.5, board.enemies)
	check(minion.position.distance_to(enemy.position) < start.distance_to(enemy.position), "Minion pursues the nearest zombie")
	check(minion_art.frame != start_frame, "Moving minion advances its leg and arm pose")
	var moving_frame: int = minion_art.frame
	game._toggle_pause()
	game._process(1.0)
	check(minion_art.frame == moving_frame, "Minion walk animation pauses with settings")
	game._toggle_pause()
	enemy.position = minion.position + Vector2(-20, 0)
	minion.tick_minion(0.1, board.enemies)
	check(enemy.health == 70, "Minion hits for 10 damage")
	check(minion_art.frame == moving_frame, "Minion holds its walk pose while attacking")
	minion.tick_minion(0.2, board.enemies)
	check(enemy.health == 70, "Minion respects the one-second attack interval")
	minion.tick_minion(0.8, board.enemies)
	check(enemy.health == 60, "Minion can hit again after one second")
	enemy.health = 10
	minion.cooldown = 0.0
	var before_gold: int = game.gold
	minion.tick_minion(0.1, board.enemies)
	check(enemy.settled and game.gold == before_gold + 10, "A minion kill awards coins once")
	await process_frame
	var attacker: TutorialZombie = board.spawn_stage_enemy(game.balance, "standard", 3)
	attacker.position = minion.position + Vector2(-20, 0)
	var defenders: Array[DefenseTower] = [minion]
	attacker.tick(0.1, defenders, Vector2(904, attacker.position.y))
	check(minion.health == 45, "Zombies can damage minions")
	attacker.tick(2.0, defenders, Vector2(904, attacker.position.y))
	check(minion.settled, "Minion dies at zero health")
	await process_frame
	board.tick_stage(0.0)
	var living: int = 0
	for unit: DefenseTower in board.minions:
		if is_instance_valid(unit) and not unit.settled:
			living += 1
	game.selected = tower
	before_gold = game.gold
	game._sell()
	check(game.gold == before_gold + 125, "Sell returns half of tower plus upgrade cost")
	board.tick_recruitment(24.0)
	var remaining: int = 0
	for unit: DefenseTower in board.minions:
		if is_instance_valid(unit) and not unit.settled:
			remaining += 1
	check(remaining == living, "Sold tower stops recruiting while existing minions remain")
	game.queue_free()
	await process_frame
	game = load("res://scenes/stage_one.tscn").instantiate()
	game.progress_path = "user://minion_test_unused.cfg"
	root.add_child(game)
	await process_frame
	check(game.board.minions.is_empty(), "A fresh level starts without old minions")
	game.queue_free()
	await process_frame
	root.get_node("Sfx").stop_all()
	root.get_node("Music").stop()
	await create_timer(0.1).timeout
	print("MINION CHECKS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

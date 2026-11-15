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
	game.progress_path = "user://brick_test_unused.cfg"
	root.add_child(game)
	game.set_process(false)
	game.wave = 1
	game.waiting = 0.0
	game.queue.append("standard")
	var board: Variant = game.board
	var tower: Variant = board.add_stage_tower(24, game.balance, true)
	check(tower.get_node("Art").texture.resource_path == "res://assets/generated/realistic_brick_catapult.png" and tower.get_node("Art").modulate == Color.WHITE, "Brick tower uses the catapult art without orange tint")
	var enemies: Array[TutorialZombie] = []
	var offsets: Array[Vector2] = [Vector2(-130, 0), Vector2(0, -130), Vector2(130, 0), Vector2(0, 130), Vector2(-90, -90), Vector2(180, 0)]
	for i: int in range(6):
		var enemy: TutorialZombie = board.spawn_stage_enemy(game.balance, "toilet", 3)
		enemy.position = tower.position + offsets[i]
		enemy.health = 1000
		enemy.max_health = 1000
		enemies.append(enemy)
	var out_of_range: TutorialZombie = board.spawn_stage_enemy(game.balance, "toilet", 3)
	out_of_range.position = tower.position + Vector2(-400, 0)
	out_of_range.health = 1000
	board.tick_stage(0.01)
	check(board.flying_bricks.size() == 5, "Exactly five bricks launched")
	var targets: Dictionary = {}
	for projectile: Dictionary in board.flying_bricks:
		targets[projectile.target.get_ref().get_instance_id()] = true
	check(targets.size() == 5 and not targets.has(out_of_range.get_instance_id()), "Volley selects five different in-range zombies")
	check(board.flying_bricks[0].elapsed == 0.0 and board.flying_bricks[1].elapsed < 0.0 and board.flying_bricks[4].elapsed < board.flying_bricks[1].elapsed, "Bricks launch at spaced intervals")
	check(enemies[0].health == 1000, "No damage before impact")
	board._tick_bricks(0.2)
	var flight: Dictionary = board.flying_bricks[0]
	check(flight.position != flight.start and flight.angle > 0.0, "Brick moves and spins during flight")
	check(board.flying_bricks[1].position != flight.position and board.flying_bricks[4].elapsed < 0.0, "Flying bricks separate while later bricks wait to launch")
	board._tick_bricks(0.2)
	var left: bool = false
	var right: bool = false
	for projectile: Dictionary in board.flying_bricks:
		if projectile.elapsed > 0.0:
			left = left or projectile.position.x < projectile.start.x - 5.0
			right = right or projectile.position.x > projectile.start.x + 5.0
	check(left and right, "Bricks travel in different directions toward zombies around the tower")
	var paused_pos: Vector2 = flight.position
	game._toggle_pause()
	game._process(0.4)
	check(board.flying_bricks[0].position == paused_pos and enemies[0].health == 1000, "Settings pause freezes the flying brick")
	game._toggle_pause()
	game._toggle_shop()
	game._process(0.4)
	check(board.flying_bricks[0].position == paused_pos and enemies[0].health == 1000, "Shop pause freezes the flying brick")
	game._toggle_shop()
	board._tick_bricks(0.6)
	check(board.flying_bricks.is_empty(), "Bricks disappear after impact")
	var hits: int = 0
	for enemy: TutorialZombie in enemies:
		if enemy.health == 988:
			hits += 1
	check(hits == 5 and out_of_range.health == 1000, "Five different zombies each receive 12 damage")
	for enemy: TutorialZombie in enemies:
		enemy.settled = true
		enemy.queue_free()
	out_of_range.settled = true
	out_of_range.queue_free()
	await process_frame
	board.tick_stage(0.01)
	check(board.flying_bricks.is_empty(), "No volley when no targets are present")
	var only: TutorialZombie = board.spawn_stage_enemy(game.balance, "toilet", 3)
	only.position = tower.position + Vector2(-90, 0)
	only.health = 1000
	tower.cooldown = 0.0
	board.tick_stage(0.01)
	check(board.flying_bricks.size() == 5, "Five bricks still launch against one zombie")
	board._tick_bricks(1.0)
	check(only.health == 940, "Five bricks deal 60 damage total to one zombie")
	tower.cooldown = 0.0
	board.tick_stage(0.01)
	only.queue_free()
	await process_frame
	board._tick_bricks(0.1)
	check(board.flying_bricks.is_empty(), "Bricks safely disappear when their target is freed")
	var fragile: TutorialZombie = board.spawn_stage_enemy(game.balance, "standard", 3)
	fragile.position = tower.position + Vector2(-90, 0)
	fragile.health = 50
	fragile.died.connect(game._enemy_died.bind(fragile))
	var before_gold: int = game.gold
	tower.cooldown = 0.0
	board.tick_stage(0.01)
	board._tick_bricks(1.0)
	check(fragile.settled and game.gold == before_gold + 10 and board.flying_bricks.is_empty(), "A lethal volley pays the kill reward only once")
	game.queue_free()
	await process_frame
	root.get_node("Sfx").stop_all()
	root.get_node("Music").stop()
	await create_timer(0.1).timeout
	print("BRICK CHECKS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)

extends SceneTree
func _initialize() -> void:
	_run.call_deferred()
func _run() -> void:
	var losses: int = 0
	for trial: int in range(15):
		seed(trial + 91)
		var game: Variant = load("res://scenes/stage_one.tscn").instantiate()
		game.progress_path = "user://stage_balance_test.cfg"
		root.add_child(game)
		game.set_process(false)
		game.rng.seed = trial + 91
		var pairs: Array[Array] = [[1,2],[1,3],[1,4],[1,5],[1,6],[2,3],[2,4],[2,5],[2,6],[3,4],[3,5],[3,6],[4,5],[4,6],[5,6]]
		game.first_wave_rows.assign(pairs[trial])
		var rows: Array[int] = game.first_wave_rows.duplicate()
		for row: int in [1, 2, 3, 4, 5, 6]:
			if not rows.has(row): rows.append(row)
		var seconds: float = 0.0
		while seconds < 900.0 and not game.finished and not game.reward_open:
			for row: int in rows:
				var cell: int = row * game.board.COLUMNS + 3
				if not game.board.occupied(cell) and game.gold >= 100 and game.pending == "":
					game._toggle_shop()
					game._buy("standard")
					game._board_click(game.board.cell_center(cell))
					break
			for tower: Variant in game.board.towers:
				if game.board.towers.size() >= 2 and is_instance_valid(tower) and tower.tier == 0 and game.gold >= 50:
					game.selected = tower
					game._upgrade()
					break
			for enemy: TutorialZombie in game.board.enemies:
				if is_instance_valid(enemy) and not enemy.settled and enemy.is_semiboss:
					for tower: DefenseTower in game.board.towers:
						if is_instance_valid(tower) and tower.freeze_cooldown <= 0 and tower.position.distance_to(enemy.position) < 250 and enemy.freeze_left <= 0:
							enemy.freeze(5)
							tower.freeze_cooldown = 12

			game._process(0.2)
			seconds += 0.2
		print("SIM %d wave=%d health=%d gold=%d win=%s time=%.0f" % [trial, game.wave, game.kingdom_health, game.gold, game.reward_open, seconds])
		if not game.reward_open: losses += 1
		game.queue_free()
		await process_frame
		await process_frame
	root.get_node("Sfx").stop_all()
	root.get_node("Music").stop()
	await create_timer(0.1).timeout
	print("BALANCE: %d / 15 wins with this simple strategy" % (15 - losses))
	# This deliberately simple strategy is not expected to win every layout.
	# Ensure at least one simulated route can still reach the reward.
	quit(1 if losses == 15 else 0)

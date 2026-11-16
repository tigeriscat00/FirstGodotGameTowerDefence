extends SceneTree

const STAGE_TWO: String = "res://scenes/stage_two.tscn"
const TEST_SAVE: String = "user://stage_two_test_progress.cfg"
const STEP: float = 0.2
var failures: int = 0
var checks: int = 0

func _initialize() -> void:
	_run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func _make_stage() -> Control:
	var game: Control = load(STAGE_TWO).instantiate()
	game.progress_path = TEST_SAVE
	root.add_child(game)
	game.set_process(false)
	return game

func _buy_at(game: Variant, kind: String, cell: int) -> void:
	game._toggle_shop()
	game._buy(kind)
	game._board_click(game.board.cell_center(cell))

func _run() -> void:
	root.get_node("Sfx").toggle_mute()
	root.get_node("Music").stop()
	var progress := ConfigFile.new()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE))
	var menu: Control = load("res://scenes/main.tscn").instantiate()
	menu.progress_path = TEST_SAVE
	root.add_child(menu)
	check(menu.get_node("Center/Menu/Levels/Level2").disabled, "Stage 2 is locked on a new save")
	menu.free()
	progress.set_value("levels", "stage_one_complete", true)
	progress.set_value("unlocks", "brick", true)
	if progress.save(TEST_SAVE) != OK:
		push_error("Stage 2 test could not write its progress file")
		quit(1)
		return
	menu = load("res://scenes/main.tscn").instantiate()
	menu.progress_path = TEST_SAVE
	root.add_child(menu)
	check(not menu.get_node("Center/Menu/Levels/Level2").disabled, "Stage 1 completion enables Stage 2")
	menu.free()
	_check_wave_opening(3, "dog", 8, 2, 1.5)
	_check_wave_opening(4, "armored", 2, 1, 2.0)
	var game: Variant = _make_stage()
	await process_frame
	game.rng.seed = 42
	var previous: Array[String] = []
	for wave: int in range(1, 8):
		game._start_wave()
		check(game.wave == wave and game.queue.size() == 20, "Wave %d has 20 enemies" % wave)
		check(game.queue.has("armored") and game.queue != previous, "Wave %d has an armored zombie and a new lineup" % wave)
		check(game.queue.count("semiboss") == (1 if wave in range(2, 7) else 0)
			and game.queue.count("boss") == (1 if wave == 7 else 0), "Wave %d has the expected boss count" % wave)
		if wave > 1:
			check(game.queue.back() == ("boss" if wave == 7 else "semiboss"), "Wave %d spawns its boss last" % wave)
		previous = game.queue.duplicate()
	game.wave = 1
	game.queue.clear()
	game.waiting = 0
	game._spawn_enemy("armored")
	var enemy: Variant = game.board.enemies[0]
	check(enemy.armor_health == 220 and enemy.power == 120 and enemy.move_speed == 25.0, "Armored zombie starts stronger and slower")
	var armor_art: Sprite2D = enemy.get_node("Art")
	check(armor_art.texture.resource_path.ends_with("realistic_armored_zombie_walk.png")
		and armor_art.hframes == 4 and armor_art.vframes == 2, "Armored zombie uses the eight-frame plate armor walk")
	var walk_start: int = armor_art.frame
	var no_defenders: Array[DefenseTower] = []
	enemy.tick(0.5, no_defenders, Vector2(904, enemy.position.y))
	check(armor_art.frame != walk_start, "Armored zombie advances its walk poses while moving")
	var starting_gold: int = game.gold
	enemy.take_damage(200)
	check(enemy.armor_health == 20 and enemy.health == 80 and game.gold == starting_gold, "Armor absorbs damage without a kill reward")
	enemy.take_damage(30)
	check(enemy.kind == "standard" and enemy.health == 70 and enemy.power == 55 and enemy.move_speed == 45.0, "Breaking armor passes overflow and restores normal stats")
	check(armor_art.texture.resource_path.ends_with("realistic_zombie_walk.png"), "Armor break restores the regular zombie sprite")
	enemy.take_damage(70)
	enemy.take_damage(70)
	check(game.gold == starting_gold + 15, "Armored zombie rewards once")

	game._toggle_shop()
	game._buy("minion")
	game._buy("treadmill")
	check(game.pending.is_empty() and game.gold == starting_gold + 15, "Reward towers are locked before victory")
	game._toggle_shop()
	var cells: Array[int] = game.board.build_cells()
	_buy_at(game, "standard", cells[0])
	var tower: Variant = game.board.towers[0]
	game.waiting = 100.0
	var key := InputEventKey.new()
	key.keycode = KEY_W
	key.physical_keycode = KEY_W
	key.pressed = true
	root.push_input(key)
	check(tower.effective_tier() == 2 and tower.effective_power() == 60 and tower.health == 240, "W activates the highest tower tier, damage and health")
	check(tower.invested == 100 and tower.tier == 0, "Max Upgrade preserves purchase and permanent tier")
	tower.take_damage(25)
	_buy_at(game, "standard", cells[1])
	check(game.board.towers[1].effective_tier() == 2, "New tower joins an active Max Upgrade")
	game._toggle_pause()
	game._process(5.0)
	game._toggle_pause()
	game._toggle_shop()
	game._process(5.0)
	game._toggle_shop()
	check(game.max_upgrade_left == 10.0 and game.max_upgrade_cooldown == 30.0, "Settings and shop pause the ability timers")
	game._process(9.0)
	root.push_input(key)
	check(game.max_upgrade_left == 1.0, "W cannot extend an active upgrade")
	game._process(1.0)
	check(tower.effective_tier() == 0 and tower.effective_power() == 30 and tower.health == 180, "Temporary tier and its remaining health expire")
	game._board_click(game.board.cell_center(cells[0]))
	await process_frame
	var ability_button: Button = game.max_upgrade_button
	var freeze_button: Button = game.side.get_node("Skills/Q")
	var ability_name: Label = ability_button.get_node("Name")
	var ability_timer: Label = ability_button.get_node("Timer")
	check(ability_button.is_visible_in_tree() and ability_button.get_index() == freeze_button.get_index() + 1 and freeze_button.get_node("Name").text == "Freeze", "W appears beside Q Freeze")
	check(ability_name.text == "Max Upgrade" and ability_name.get_minimum_size().x <= ability_button.size.x, "Max Upgrade fits inside its slot")
	check(ability_button.disabled and ability_timer.text == "20s", "W shows the cooldown inside its slot")
	check(game.get_node_or_null("HUD/TopBar/MaxUpgrade") == null, "Max Upgrade uses the tower skill row")
	root.push_input(key)
	check(game.max_upgrade_left == 0.0, "Cooldown blocks reactivation")
	game._process(20.0)
	check(not ability_button.disabled and ability_timer.text == "Ready", "W is ready 30 active seconds after cast")
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.position = ability_button.get_global_rect().get_center()
	click.pressed = true
	root.push_input(click, true)
	click.pressed = false
	root.push_input(click, true)
	check(tower.temp_max_upgrade and ability_timer.text == "10s active", "Clicking the W slot activates Max Upgrade and displays its active timer")
	game.free()

	var wins: int = 0
	for trial: int in range(5):
		game = _make_stage()
		game.rng.seed = trial + 51
		game.first_wave_rows.assign([[1, 2], [1, 6], [2, 4], [3, 4], [5, 6]][trial])
		if _play_stage(game):
			wins += 1
		print("Stage 2 simulation %d: wave %d, kingdom health %d" % [trial + 1, game.wave, game.kingdom_health])
		game.free()
		await process_frame
	check(wins > 0, "Stage 2 can be cleared with shop towers and Max Upgrade")
	progress.load(TEST_SAVE)
	check(progress.get_value("levels", "stage_two_complete", false), "Victory saves the unlock")
	check(progress.get_value("levels", "stage_one_complete", false) and progress.get_value("unlocks", "brick", false), "Victory preserves earlier progress")

	game = _make_stage()
	game._toggle_shop()
	await process_frame
	await process_frame
	var card_row: HBoxContainer = game.shop.get_node("Card/Contents/TowerCards")
	for kind: String in ["Standard", "Brick", "Minion", "Treadmill"]:
		var shop_card: Control = card_row.get_node(kind)
		var picture: TextureRect = shop_card.get_node("Picture")
		var title: Label = shop_card.get_node("Name")
		var buy_button: Button = shop_card.get_node("Buy")
		check(shop_card.is_visible_in_tree() and picture.texture != null and picture.get_global_rect().end.y <= title.global_position.y and title.get_global_rect().end.y <= buy_button.global_position.y, kind + " shop card shows picture, name, and purchase button in order")
	game._toggle_shop()
	_buy_at(game, "minion", cells[0])
	check(game.gold == 50 and game.board.towers.size() == 1, "Minion Tower can be purchased after victory")
	var barracks: Variant = game.board.towers[0]
	check(card_row.get_node("Minion/Picture").texture == barracks.get_node("Art").texture, "Shop and minion tower use the same artwork")
	game.board.tick_recruitment(4.99)
	check(game.board.minions.is_empty(), "Minions wait five seconds")
	game.board.tick_recruitment(0.02)
	check(game.board.minions.size() == 3, "Exactly three minions leave the door")
	var unit: Variant = game.board.minions[0]
	enemy = game.board.spawn_stage_enemy(game.balance, "standard", 1)
	enemy.position = unit.position + Vector2(-20.0, 0.0)
	unit.tick_minion(0.1, game.board.enemies)
	check(unit.health == 40 and enemy.health == 74, "Minion deals 6 damage in melee and has 40 health")
	game.board.tick_recruitment(5.0)
	check(game.board.minions.size() == 6, "Minions recruit again five seconds later")
	game.gold = 149
	game.selected = barracks
	game._upgrade()
	check(game.gold == 149 and barracks.tier == 0, "Minion Tower upgrade blocks insufficient gold")
	game.gold = 450
	game._upgrade()
	check(game.gold == 300 and barracks.tier == 1, "First Minion Tower upgrade costs 150 gold")
	game.board.tick_recruitment(2.99)
	check(game.board.minions.size() == 6, "Tier one waits three seconds")
	game.board.tick_recruitment(0.02)
	check(game.board.minions.size() == 16, "Tier one recruits exactly ten minions every three seconds")
	game.selected = barracks
	game._upgrade()
	check(game.gold == 0 and barracks.tier == 2 and barracks.invested == 600, "Second Minion Tower upgrade costs 300 gold")
	game.board.tick_recruitment(0.99)
	check(game.board.minions.size() == 16, "Tier two waits one second")
	game.board.tick_recruitment(0.02)
	check(game.board.minions.size() == 36, "Tier two recruits exactly twenty minions every second")
	var empty_enemies: Array[TutorialZombie] = []
	unit.tick_minion(60.0, empty_enemies)
	check(not unit.settled and unit.modulate.a == 1.0, "Minion Tower recruits stay alive and opaque as time passes")
	unit.take_damage(unit.health)
	check(unit.settled, "Combat damage can still defeat a Minion Tower recruit")
	game.waiting = 100.0
	game._activate_max_upgrade()
	game._process(2.0)
	check(game.board.minions.size() == 85 and barracks.tier == 2 and barracks.recruitment_batch() == 50, "W boosts a fully upgraded Minion Tower as well")
	game.free()

	game = _make_stage()
	_buy_at(game, "minion", cells[0])
	barracks = game.board.towers[0]
	game.waiting = 100.0
	game._activate_max_upgrade()
	game._process(1.99)
	check(game.board.minions.is_empty(), "Boosted recruits wait for the two-second interval")
	game._process(0.01)
	check(game.board.minions.size() == 50 and barracks.attack_description() == "50 minions every 2 s", "W recruits exactly 50 minions per batch and shows the boosted rate")
	for tick: int in 6:
		game._process(1.0)
	check(game.board.minions.size() == 200, "Four boosted batches have arrived after eight seconds")
	game._process(2.5)
	check(game.board.minions.size() == 250 and barracks.tier == 0 and barracks.effective_tier() == 0, "Max Upgrade recruits five batches across ten seconds and stops at expiry even if a tick runs long")
	var crowd_unit: DefenseTower = game.board.minions[0]
	var before_march: Vector2 = crowd_unit.position
	game.board._tick_minions(0.1)
	check(crowd_unit.position != before_march and game.board.crowd_cells.size() < game.board.minions.size(), "Overlapping recruits share drawings and continue moving individually")
	check(game.board._closest_barracks_minion(crowd_unit.position, 1.0) != null, "Zombies can target recruits in a dense crowd")
	check(game.board._closest_barracks_minion(Vector2(60, 148), 78.0) == null, "Crowd target search excludes recruits out of melee reach")
	game._process(4.51)
	check(game.board.minions.size() == 253, "The base recruitment rate resumes after W ends and the boosted recruits remain")
	game.free()

	game = _make_stage()
	_buy_at(game, "treadmill", cells[0])
	check(game.gold == 100 and game.board.towers.size() == 1, "Treadmill Tower can be purchased after victory")
	var belt: DefenseTower = game.board.towers[0]
	enemy = game.board.spawn_stage_enemy(game.balance, "standard", 1)
	var start: Vector2 = belt.position - Vector2(40, 0)
	enemy.position = start
	game.board.tick_stage(1.0)
	check(is_equal_approx(enemy.position.x - start.x, 11.25) and belt.health == 180, "Treadmill slows a zombie that passes through")
	enemy.position = belt.position + Vector2(51, 0)
	start = enemy.position
	game.board.tick_stage(1.0)
	check(is_equal_approx(enemy.position.x - start.x, 45.0), "Zombie regains full speed after leaving the belt")
	game.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE))
	root.get_node("Sfx").stop_all()
	root.get_node("Music").stop()
	await create_timer(0.1).timeout
	print("Stage 2: %d checks, %d failures, %d / 5 simulated wins" % [checks, failures, wins])
	quit(1 if failures else 0)

func _check_wave_opening(wave: int, kind: String, count: int, lanes: int, interval: float) -> void:
	var game: Variant = _make_stage()
	game.rng.seed = 51
	game.wave = wave - 1
	game.waiting = 0.0
	game._process(0.01)
	var marked_rows: Array[int] = game.board.warning_rows.duplicate()
	check(game.waiting == game.between_waves and marked_rows.size() == lanes
		and game.hint.text.begins_with("Wave %d next" % wave), "Wave %d warns players and marks its opening lanes" % wave)
	if lanes == 2:
		check(marked_rows[0] != marked_rows[1], "The dog rush marks two distinct lanes")
	game._process(game.between_waves)
	var actual_kinds: Array[String] = []
	var actual_rows: Array[float] = []
	var actual_delays: Array[float] = []
	for index: int in count:
		game._process(0.01 if index == 0 else interval)
		var enemy: TutorialZombie = game.board.enemies.back()
		actual_kinds.append(enemy.get("kind"))
		actual_rows.append(enemy.position.y)
		actual_delays.append(game.spawn_left)
	var expected_kinds: Array[String] = []
	var expected_rows: Array[float] = []
	var expected_delays: Array[float] = []
	for index: int in count:
		expected_kinds.append(kind)
		expected_rows.append(game.board.cell_center(marked_rows[index % lanes] * game.board.COLUMNS).y)
		expected_delays.append(game.spawn_interval if index == count - 1 else interval)
	check(actual_kinds == expected_kinds and game.queue.size() == 20 - count, "Wave %d spawns its opening enemies within the regular 20 slots" % wave)
	check(actual_rows == expected_rows and actual_delays == expected_delays, "Wave %d follows the marked lanes and returns to normal spawn pacing" % wave)
	game.free()

func _play_stage(game: Variant) -> bool:
	var rows: Array[int] = game.first_wave_rows.duplicate()
	for row: int in range(1, 7):
		if not rows.has(row):
			rows.append(row)
	for tick: int in int(850.0 / STEP):
		for row: int in rows:
			var cell: int = row * game.board.COLUMNS + 3
			if not game.board.occupied(cell):
				var kind: String = "brick" if game.wave > 0 and game.gold >= 150 else "standard"
				if game.gold >= 100:
					_buy_at(game, kind, cell)
					break
		for tower: Variant in game.board.towers:
			if is_instance_valid(tower) and not tower.settled and not tower.brick and tower.tier == 0 and game.gold >= 50 and game.board.towers.size() >= 2:
				game.selected = tower
				game._upgrade()
				break
		for enemy: TutorialZombie in game.board.enemies:
			if not is_instance_valid(enemy) or enemy.settled:
				continue
			if not enemy.is_semiboss and enemy.get("armor_health") <= 0:
				continue
			for tower: DefenseTower in game.board.towers:
				if is_instance_valid(tower) and not tower.settled and tower.position.distance_to(enemy.position) < 230:
					game._activate_max_upgrade()
					if tower.freeze_cooldown <= 0 and enemy.freeze_left <= 0:
						enemy.freeze(game.balance.freeze_duration)
						tower.freeze_cooldown = game.balance.freeze_recharge
					break
		game._process(STEP)
		if game.finished:
			return game.kingdom_health > 0
	return false

extends Control

@export var balance: TutorialBalance
@export var waves: StageOneWaves = StageOneWaves.new()
@export var spawn_interval: float = 4.0
@export var between_waves: float = 8.0
@export var progress_path: String = "user://stage_progress.cfg"
@onready var board = $Margin/Layout/Middle/Board
@onready var shop: Control = $ShopOverlay
@onready var side: VBoxContainer = $HUD/SelectionCard/Side
@onready var status: Label = $HUD/TopBar/Status
@onready var hint: Label = $HUD/Hint
var gold: int = 200
var kingdom_health: int = 300
var wave: int = 0
var waiting: float = 10.0
var spawn_left: float = 0.0
var queue: Array[String] = []
var rng := RandomNumberGenerator.new()
var pending: String = ""
var selected: DefenseTower
var paused: bool = false
var finished: bool = false
var reward_open: bool = false
var sack_taps: int = 0
var brick_unlocked: bool = false
var brick_button: Button
var sack_button: Button
var first_wave_rows: Array[int] = []

func _ready() -> void:
	get_node("/root/Sfx").stop_combat()
	rng.randomize()
	var choices: Array[int] = [1, 2, 3, 4, 5, 6]
	var first: int = rng.randi_range(0, choices.size() - 1)
	first_wave_rows.append(choices.pop_at(first))
	first_wave_rows.append(choices[rng.randi_range(0, choices.size() - 1)])
	board.warning_rows = first_wave_rows.duplicate()
	board.queue_redraw()
	gold = waves.starting_coins
	waiting = waves.preparation_seconds
	kingdom_health = balance.kingdom_health
	board.build_range = balance.tower_range
	board.board_clicked.connect(_board_click)
	$HUD/TopBar/Shop.pressed.connect(_toggle_shop)
	shop.get_node("Card/Contents/Close").pressed.connect(_toggle_shop)
	shop.get_node("Card/Contents/Buy").text = "Buy Standard · 100 gold"
	shop.get_node("Card/Contents/Buy").pressed.connect(_buy.bind("standard"))
	brick_button = Button.new()
	brick_button.text = "Buy Brick Tower · 150 gold"
	shop.get_node("Card/Contents").add_child(brick_button)
	shop.get_node("Card/Contents").move_child(brick_button, 4)
	brick_button.pressed.connect(_buy.bind("brick"))
	var saved := ConfigFile.new()
	brick_unlocked = saved.load(progress_path) == OK and saved.get_value("unlocks", "brick", false)
	brick_button.visible = brick_unlocked
	side.get_node("Upgrade").pressed.connect(_upgrade)
	side.get_node("Sell").pressed.connect(_sell)
	side.get_node("Dismiss").pressed.connect(_deselect)
	for slot: int in DefenseTower.MAX_SKILLS:
		var button: Button = side.get_node("Skills/" + "QWER"[slot])
		button.get_node("Key").text = "QWER"[slot]
		button.pressed.connect(_skill.bind(slot))
	$HUD/TopBar/Settings.pressed.connect(_toggle_pause)
	$SettingsOverlay/Card/Contents/Resume.pressed.connect(_toggle_pause)
	$SettingsOverlay/Card/Contents/Restart.text = "Restart level"
	$SettingsOverlay/Card/Contents/Restart.pressed.connect(func() -> void: get_tree().reload_current_scene())
	$SettingsOverlay/Card/Contents/Back.pressed.connect(_back)
	$VictoryCelebration.quit_requested.connect(_back)
	$DefeatScreen.restart_requested.connect(func() -> void: get_tree().reload_current_scene())
	$DefeatScreen.menu_requested.connect(_back)
	$HUD/Dialogue.hide()
	$HUD/DialogueToggle.hide()
	$TutorialCue.hide()
	hint.text = "Wave 1 enters along the two gold arrows. Build defenses there!"
	_refresh()

func _process(delta: float) -> void:
	if not paused and not finished and not reward_open:
		if waiting > 0.0:
			if not shop.visible:
				board.tick_recruitment(delta)
			waiting = maxf(0.0, waiting - delta)
			if waiting == 0.0:
				shop.hide()
				get_node("/root/Sfx").set_combat_paused(false)
				_start_wave()
		elif wave > 0 and not shop.visible:
			board.tick_stage(delta)
			if not queue.is_empty():
				spawn_left -= delta
				if spawn_left <= 0.0:
					_spawn_enemy(queue.pop_front())
					spawn_left = spawn_interval
			if queue.is_empty() and board.enemies.is_empty():
				if wave == 5:
					_show_sack()
				else:
					waiting = between_waves
					hint.text = "Wave cleared! Prepare for the next wave."
	_refresh()

func _start_wave() -> void:
	wave += 1
	if wave > 5:
		return
	if wave > 1:
		board.warning_rows.clear()
		board.queue_redraw()
	var roster: Array[int] = waves.roster(wave)
	queue.clear()
	for index: int in 3:
		for count: int in roster[index]:
			queue.append(["standard", "dog", "toilet"][index])
	# Shuffle ordinary enemies while keeping each finale last.
	queue.shuffle()
	if roster[3] > 0:
		queue.append("boss" if wave == 5 else "semiboss")
	spawn_left = 0.0
	hint.text = "Wave %d incoming!" % wave

func _spawn_enemy(kind: String) -> void:
	var row: int = first_wave_rows[rng.randi_range(0, first_wave_rows.size() - 1)] if wave == 1 else rng.randi_range(board.FIRST_BUILD_ROW, board.ROWS - 1)
	var enemy: TutorialZombie = board.spawn_stage_enemy(balance, kind, row)
	enemy.died.connect(_enemy_died.bind(enemy))
	enemy.gate_hit.connect(_gate_hit)

func _enemy_died(enemy: TutorialZombie) -> void:
	gold += enemy.gold_reward
	hint.text = "+%d coins" % enemy.gold_reward

func _gate_hit(damage: int) -> void:
	if finished:
		return
	kingdom_health = maxi(0, kingdom_health - damage)
	if kingdom_health == 0:
		finished = true
		board.freeze_aiming = false
		_deselect()
		shop.hide()
		$SettingsOverlay.hide()
		$DefeatScreen.show_defeat()
		get_node("/root/Sfx").stop_combat()

func _toggle_shop() -> void:
	if paused or finished or reward_open:
		return
	if not shop.visible and not pending.is_empty():
		hint.text = "Place your purchased tower first."
		return
	shop.visible = not shop.visible
	get_node("/root/Sfx").set_combat_paused(shop.visible)
	if shop.visible:
		_deselect()
	shop.get_node("Card/Contents/Feedback").text = ""
	_refresh()

func _buy(kind: String) -> void:
	if not shop.visible or not pending.is_empty() or (kind == "brick" and not brick_unlocked):
		return
	var cost: int = 150 if kind == "brick" else balance.tower_cost
	if gold < cost:
		shop.get_node("Card/Contents/Feedback").text = "Not enough coins."
		return
	var space: bool = false
	for cell: int in board.build_cells():
		if not board.occupied(cell):
			space = true
			break
	if not space:
		shop.get_node("Card/Contents/Feedback").text = "No empty building cells."
		return
	gold -= cost
	pending = kind
	board.placing = true
	shop.hide()
	get_node("/root/Sfx").set_combat_paused(false)
	hint.text = "Choose an empty cell for your tower."
	board.queue_redraw()

func _board_click(point: Vector2) -> void:
	if paused or shop.visible or finished or reward_open:
		return
	if board.freeze_aiming:
		for enemy: TutorialZombie in board.enemies:
			if is_instance_valid(enemy) and not enemy.settled and point.distance_to(enemy.position + Vector2(0, -20)) < 60.0:
				if is_instance_valid(selected) and not selected.settled and selected.freeze_cooldown <= 0.0:
					enemy.freeze(balance.freeze_duration)
					selected.freeze_cooldown = balance.freeze_recharge
					get_node("/root/Sfx").play(&"freeze")
					board.freeze_aiming = false
					hint.text = "Zombie frozen!"
					return
		hint.text = "Click a zombie or press Esc to cancel."
		return
	if not pending.is_empty():
		var cell: int = board.cell_at(point)
		if cell < 0 or board.occupied(cell):
			hint.text = "Choose an empty building cell."
			return
		var tower: DefenseTower = board.add_stage_tower(cell, balance, pending == "brick")
		if tower != null:
			tower.destroyed.connect(_tower_destroyed.bind(tower))
			pending = ""
			board.placing = false
			board.queue_redraw()
		return
	if is_instance_valid(selected):
		selected.selected = false
		selected.queue_redraw()
	selected = board.tower_at(point)
	_refresh()

func _tower_destroyed(tower: DefenseTower) -> void:
	if selected == tower:
		_deselect()
	hint.text = "A tower was destroyed!"

func _upgrade() -> void:
	if not is_instance_valid(selected) or selected.settled:
		return
	var tower: Variant = selected
	if (tower.brick and tower.tier >= 1) or (not tower.brick and tower.tier >= 2):
		return
	var cost: int = 100 if tower.brick else (50 if tower.tier == 0 else 100)
	if gold < cost:
		hint.text = "Not enough coins to upgrade."
		return
	gold -= cost
	tower.stage_upgrade()
	_deselect()

func _sell() -> void:
	if not is_instance_valid(selected) or selected.settled:
		return
	var tower: Variant = selected
	gold += floori(tower.invested * 0.5)
	tower.settled = true
	tower.queue_free()
	_deselect()

func _skill(slot: int) -> void:
	if slot != 0 or not is_instance_valid(selected) or selected.settled:
		return
	if selected.freeze_cooldown > 0.0:
		hint.text = "Freeze is recharging."
		return
	if board.enemies.is_empty():
		hint.text = "Wait for a zombie."
		return
	$HUD/SelectionCard.hide()
	board.freeze_aiming = true
	hint.text = "Click a zombie to freeze it."

func _deselect() -> void:
	if is_instance_valid(selected):
		selected.selected = false
		selected.queue_redraw()
	selected = null
	board.freeze_aiming = false
	$HUD/SelectionCard.hide()

func _toggle_pause() -> void:
	if finished or reward_open:
		return
	paused = not paused
	shop.hide()
	get_node("/root/Sfx").set_combat_paused(paused)
	$SettingsOverlay.visible = paused
	_deselect()

func _unhandled_key_input(event: InputEvent) -> void:
	if finished or reward_open:
		return
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	match event.physical_keycode:
		KEY_B: _toggle_shop()
		KEY_Q: _skill(0)
		KEY_ESCAPE:
			if board.freeze_aiming:
				_deselect()
			elif shop.visible:
				_toggle_shop()
			elif is_instance_valid(selected):
				_deselect()
			else:
				_toggle_pause()
		_: return
	get_viewport().set_input_as_handled()

func _show_sack() -> void:
	reward_open = true
	_deselect()
	sack_button = Button.new()
	sack_button.text = "BOSS REWARD SACK\nTap 5 times to open (0/5)"
	sack_button.position = Vector2(376, 250)
	sack_button.size = Vector2(400, 140)
	sack_button.pressed.connect(_tap_sack)
	add_child(sack_button)

func _tap_sack() -> void:
	sack_taps += 1
	if sack_taps < 5:
		sack_button.text = "BOSS REWARD SACK\nTap 5 times to open (%d/5)" % sack_taps
		return
	var already_unlocked: bool = brick_unlocked
	brick_unlocked = true
	var saved := ConfigFile.new()
	var result: Error = saved.load(progress_path)
	if result != OK and result != ERR_FILE_NOT_FOUND:
		hint.text = "Could not read saved progress."
	saved.set_value("unlocks", "brick", true)
	saved.set_value("levels", "stage_one_complete", true)
	var save_ok: bool = saved.save(progress_path) == OK
	sack_button.queue_free()
	reward_open = false
	finished = true
	$VictoryCelebration.celebrate()
	if not save_ok:
		$VictoryCelebration/Content/Message.text = "PROGRESS COULD NOT BE SAVED" if already_unlocked else "BRICK UNLOCKED - SAVE FAILED"
	elif already_unlocked:
		$VictoryCelebration/Content/Message.text = "THE KINGDOM IS SAFE"
	else:
		$VictoryCelebration/Content/Message.text = "BRICK TOWER UNLOCKED!"
	$VictoryCelebration/Content/Quit.text = "Return to menu"

func _back() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _refresh() -> void:
	if not is_node_ready():
		return
	status.text = "DEFEAT" if finished and kingdom_health == 0 else ("PREPARE · %d s" % ceili(waiting) if waiting > 0 else "WAVE %d / 5" % wave)
	$HUD/TopBar/Gold.text = str(gold)
	$HUD/TopBar/Kingdom.max_value = balance.kingdom_health
	$HUD/TopBar/Kingdom.value = kingdom_health
	$HUD/TopBar/Kingdom/Value.text = "%d / %d" % [kingdom_health, balance.kingdom_health]
	hint.visible = not hint.text.is_empty()
	if not is_instance_valid(selected) or selected.settled or paused or shop.visible or board.freeze_aiming:
		$HUD/SelectionCard.hide()
		return
	var tower: Variant = selected
	tower.selected = true
	tower.queue_redraw()
	var card: PanelContainer = $HUD/SelectionCard
	card.show()
	card.position = Vector2(clampf(tower.position.x + 56, 16, 1136 - card.size.x), clampf(tower.position.y - card.size.y * 0.5, 76, 632 - card.size.y))
	side.get_node("Selection").text = ("BRICK TOWER + MINIONS" if tower.tier > 0 else "BRICK TOWER") if tower.brick else ["STANDARD TOWER", "REINFORCED TOWER", "FIRE BOW TOWER"][tower.tier]
	side.get_node("PowerLabel").text = ("%d total damage · 5 bricks" if tower.brick else "%d damage") % tower.power
	side.get_node("Extra").text = ("Range %d px | Minion every %.0fs" % [balance.tower_range, tower.minion_interval]) if tower.brick and tower.tier > 0 else "Range %d px" % balance.tower_range
	side.get_node("Health").max_value = tower.max_health
	side.get_node("Health").value = tower.health
	side.get_node("Health/Value").text = "%d / %d" % [tower.health, tower.max_health]
	var upgrade: Button = side.get_node("Upgrade")
	var maxed: bool = tower.tier >= (1 if tower.brick else 2)
	var upgrade_cost: int = 100 if tower.brick else (50 if tower.tier == 0 else 100)
	upgrade.text = "Fully upgraded" if maxed else ("Add minions · %d gold" if tower.brick else "Upgrade · %d gold") % upgrade_cost
	upgrade.disabled = maxed or gold < upgrade_cost
	side.get_node("Sell").text = "Sell · %d gold" % floori(tower.invested * 0.5)
	for slot: int in DefenseTower.MAX_SKILLS:
		var button: Button = side.get_node("Skills/" + "QWER"[slot])
		button.get_node("Name").text = ("Freeze" if tower.freeze_cooldown <= 0 else "%ds" % ceili(tower.freeze_cooldown)) if slot == 0 else "Empty"
		button.get_node("Icon").visible = slot == 0
		button.disabled = slot != 0 or tower.freeze_cooldown > 0

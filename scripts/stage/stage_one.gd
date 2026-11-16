extends Control

@export var balance: TutorialBalance
@export var waves: StageOneWaves = StageOneWaves.new()
@export var spawn_interval: float = 4.0
@export var between_waves: float = 8.0
@export var progress_path: String = "user://stage_progress.cfg"
const MINION_COST: int = 150
const TREADMILL_COST: int = 100
const TOWER_ART = preload("res://scripts/stage/stage_tower.gd")
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
var stage_two_complete: bool = false
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
	var saved := ConfigFile.new()
	if saved.load(progress_path) == OK:
		brick_unlocked = saved.get_value("unlocks", "brick", false)
		stage_two_complete = saved.get_value("levels", "stage_two_complete", false)
	_setup_shop_cards()
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

func _setup_shop_cards() -> void:
	var panel: PanelContainer = shop.get_node("Card")
	var cards: HBoxContainer = panel.get_node("Contents/TowerCards")
	_add_shop_card(cards, "standard", "Standard Tower", balance.tower_cost, DefenseTower.BASE_ART)
	brick_button = _add_shop_card(cards, "brick", "Brick Tower", 150, TOWER_ART.BRICK_ART, brick_unlocked)
	_add_shop_card(cards, "minion", "Minion Tower", MINION_COST, TOWER_ART.MINION_ART, stage_two_complete)
	_add_shop_card(cards, "treadmill", "Treadmill Tower", TREADMILL_COST, TOWER_ART.TREADMILL_ART, stage_two_complete)
	var available: int = 1 + int(brick_unlocked) + 2 * int(stage_two_complete)
	var width: float = maxf(330.0, 160.0 * available + 12.0 * (available - 1) + 32.0)
	panel.position = Vector2((1152.0 - width) * 0.5, 158.0)
	panel.size = Vector2(width, 332.0)

func _add_shop_card(cards: HBoxContainer, kind: String, tower_name: String, cost: int, art: Texture2D, unlocked: bool = true) -> Button:
	var card := VBoxContainer.new()
	card.name = kind.capitalize()
	card.custom_minimum_size.x = 160.0
	card.add_theme_constant_override("separation", 8)
	card.visible = unlocked
	cards.add_child(card)
	var picture := TextureRect.new()
	picture.name = "Picture"
	picture.texture = art
	picture.custom_minimum_size.y = 122.0
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(picture)
	var title := Label.new()
	title.name = "Name"
	title.text = tower_name
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(title)
	var button := Button.new()
	button.name = "Buy"
	button.text = "Buy · %d gold" % cost
	button.custom_minimum_size.y = 42.0
	button.pressed.connect(_buy.bind(kind))
	card.add_child(button)
	return button

func _process(delta: float) -> void:
	if not paused and not finished and not reward_open:
		var ability_ticking: bool = not shop.visible
		if waiting > 0.0:
			if not shop.visible:
				board.tick_preparation(delta)
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
					spawn_left = _next_spawn_delay()
			if not finished and queue.is_empty() and board.enemies.is_empty():
				board.clear_bricks()
				if wave == _wave_count():
					_complete_stage()
				else:
					_prepare_next_wave()
		if ability_ticking and not finished and not reward_open:
			_tick_ability(delta)
	_refresh()

func _tick_ability(_delta: float) -> void:
	pass

func _wave_count() -> int:
	return 5

func _complete_stage() -> void:
	_show_sack()

func _prepare_next_wave() -> void:
	waiting = between_waves
	hint.text = "Wave cleared! Prepare for the next wave."

func _start_wave() -> void:
	wave += 1
	if wave > _wave_count():
		return
	if wave > 1:
		board.warning_rows.clear()
		board.queue_redraw()
	queue = _wave_roster()
	spawn_left = 0.0
	hint.text = "Wave %d incoming!" % wave

func _wave_roster() -> Array[String]:
	var roster: Array[int] = waves.roster(wave)
	var enemies: Array[String] = []
	for index: int in 3:
		for count: int in roster[index]:
			enemies.append(["standard", "dog", "toilet"][index])
	# Shuffle ordinary enemies while keeping each finale last.
	enemies.shuffle()
	if roster[3] > 0:
		enemies.append("boss" if wave == _wave_count() else "semiboss")
	return enemies

func _spawn_enemy(kind: String) -> void:
	var enemy: TutorialZombie = board.spawn_stage_enemy(balance, kind, _spawn_row())
	enemy.died.connect(_enemy_died.bind(enemy))
	enemy.gate_hit.connect(_gate_hit)

func _spawn_row() -> int:
	if wave == 1:
		return first_wave_rows[rng.randi_range(0, first_wave_rows.size() - 1)]
	return rng.randi_range(board.FIRST_BUILD_ROW, board.ROWS - 1)

func _next_spawn_delay() -> float:
	return spawn_interval

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
	if not shop.visible or not pending.is_empty():
		return
	var cost: int
	match kind:
		"standard": cost = balance.tower_cost
		"brick":
			if not brick_unlocked:
				return
			cost = 150
		"minion", "treadmill":
			if not stage_two_complete:
				return
			cost = MINION_COST if kind == "minion" else TREADMILL_COST
		_: return
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
		var cost: int = MINION_COST if pending == "minion" else TREADMILL_COST
		var tower: DefenseTower = board.add_stage_tower(cell, balance, pending == "brick", pending, cost)
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
	if tower.tier >= tower.max_tier() or tower.temp_max_upgrade:
		return
	var cost: int = tower.upgrade_cost()
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
	if slot != 0 or paused or finished or shop.visible or not is_instance_valid(selected) or selected.settled:
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
	status.text = "DEFEAT" if finished and kingdom_health == 0 else ("PREPARE · %d s" % ceili(waiting) if waiting > 0 else "WAVE %d / %d" % [wave, _wave_count()])
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
	side.get_node("Selection").text = tower.display_name()
	side.get_node("PowerLabel").text = tower.attack_description()
	side.get_node("Extra").text = tower.effect_description()
	side.get_node("Health").max_value = tower.max_health
	side.get_node("Health").value = tower.health
	side.get_node("Health/Value").text = "%d / %d" % [tower.health, tower.max_health]
	var upgrade: Button = side.get_node("Upgrade")
	var maxed: bool = tower.tier >= tower.max_tier()
	var upgrade_cost: int = tower.upgrade_cost()
	upgrade.text = "Fully upgraded" if maxed else tower.upgrade_description()
	if tower.temp_max_upgrade:
		upgrade.text = "Max Upgrade active"
	upgrade.disabled = maxed or tower.temp_max_upgrade or gold < upgrade_cost
	side.get_node("Sell").text = "Sell · %d gold" % floori(tower.invested * 0.5)
	for slot: int in DefenseTower.MAX_SKILLS:
		var button: Button = side.get_node("Skills/" + "QWER"[slot])
		_refresh_skill(slot, button, tower.freeze_cooldown)

func _refresh_skill(slot: int, button: Button, freeze_cooldown: float) -> void:
	button.get_node("Name").text = ("Freeze" if freeze_cooldown <= 0 else "%ds" % ceili(freeze_cooldown)) if slot == 0 else "Empty"
	button.get_node("Icon").visible = slot == 0
	button.disabled = slot != 0 or freeze_cooldown > 0

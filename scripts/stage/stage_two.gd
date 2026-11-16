extends "res://scripts/stage/stage_one.gd"

const WAVE_COUNT: int = 7
const ZOMBIES_PER_WAVE: int = 20
const OPENINGS: Dictionary = {
	3: {"kind": "dog", "count": 8, "lanes": 2, "interval": 1.5, "name": "Dog rush",
		"warning": "Dogs will rush down the two marked lanes."},
	4: {"kind": "armored", "count": 2, "lanes": 1, "interval": 2.0, "name": "Armored push",
		"warning": "Two armored zombies will lead the attack in the marked lane."}
}

@export_range(1.0, 30.0) var max_upgrade_duration: float = 10.0
@export_range(1.0, 120.0) var max_upgrade_recharge: float = 30.0
@onready var max_upgrade_button: Button = $HUD/SelectionCard/Side/Skills/W

var max_upgrade_left: float = 0.0
var max_upgrade_cooldown: float = 0.0
var opening_rows: Array[int] = []

func _ready() -> void:
	super._ready()
	max_upgrade_button.tooltip_text = "Max Upgrade [W] · Temporarily maxes out all your towers"
	max_upgrade_button.get_node("Name").text = "Max Upgrade"
	max_upgrade_button.get_node("Icon").hide()
	hint.text = "Build at the gold arrows. Press W or select a tower to use Max Upgrade."

func _wave_count() -> int:
	return WAVE_COUNT

func _process(delta: float) -> void:
	if max_upgrade_left > 0.0 and delta > max_upgrade_left and not paused and not shop.visible:
		var active_delta: float = max_upgrade_left
		super._process(active_delta)
		delta -= active_delta
	super._process(delta)

func _prepare_next_wave() -> void:
	super._prepare_next_wave()
	opening_rows.clear()
	var upcoming_wave: int = wave + 1
	if not OPENINGS.has(upcoming_wave):
		return
	_plan_opening(upcoming_wave)
	board.warning_rows = opening_rows.duplicate()
	board.queue_redraw()
	hint.text = "Wave %d next · %s" % [upcoming_wave, OPENINGS[upcoming_wave].warning]

func _plan_opening(upcoming_wave: int) -> void:
	var rows: Array[int] = []
	for row: int in range(board.FIRST_BUILD_ROW, board.ROWS):
		rows.append(row)
	for lane: int in OPENINGS[upcoming_wave].lanes:
		opening_rows.append(rows.pop_at(rng.randi_range(0, rows.size() - 1)))

func _start_wave() -> void:
	super._start_wave()
	if OPENINGS.has(wave):
		if opening_rows.size() != OPENINGS[wave].lanes:
			opening_rows.clear()
			_plan_opening(wave)
		hint.text = "Wave %d · %s!" % [wave, OPENINGS[wave].name]
	else:
		opening_rows.clear()

func _spawn_row() -> int:
	var index: int = ZOMBIES_PER_WAVE - queue.size() - 1
	if OPENINGS.has(wave) and index < OPENINGS[wave].count:
		return opening_rows[index % opening_rows.size()]
	return super._spawn_row()

func _next_spawn_delay() -> float:
	var spawned: int = ZOMBIES_PER_WAVE - queue.size()
	if OPENINGS.has(wave) and spawned < OPENINGS[wave].count:
		return OPENINGS[wave].interval
	return super._next_spawn_delay()

func _wave_roster() -> Array[String]:
	var enemies: Array[String] = []
	var opening: Dictionary = OPENINGS.get(wave, {})
	var opening_count: int = opening.get("count", 0)
	for index: int in opening_count:
		enemies.append(opening.kind)
	var regular_slots: int = ZOMBIES_PER_WAVE if wave == 1 else ZOMBIES_PER_WAVE - 1
	regular_slots -= opening_count
	var armored_slot: int = rng.randi_range(0, regular_slots - 1)
	var armor_chance: int = 5 + (wave - 1) * 2
	for slot: int in regular_slots:
		var roll: int = rng.randi_range(0, 99)
		if slot == armored_slot or roll < armor_chance:
			enemies.append("armored")
		elif roll < armor_chance + 18:
			enemies.append("dog")
		elif roll < armor_chance + 30:
			enemies.append("toilet")
		else:
			enemies.append("standard")
	if wave > 1:
		enemies.append("boss" if wave == WAVE_COUNT else "semiboss")
	return enemies

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.physical_keycode == KEY_W and event.pressed and not event.echo:
		_activate_max_upgrade()
		get_viewport().set_input_as_handled()

func _skill(slot: int) -> void:
	if slot == 1:
		_activate_max_upgrade()
	else:
		super._skill(slot)

func _activate_max_upgrade() -> void:
	if paused or shop.visible or finished or max_upgrade_cooldown > 0.0 or max_upgrade_left > 0.0:
		return
	max_upgrade_left = max_upgrade_duration
	max_upgrade_cooldown = max_upgrade_recharge
	board.set_temp_max_upgrade(true)
	get_node("/root/Sfx").play(&"upgrade")
	_refresh()

func _tick_ability(delta: float) -> void:
	max_upgrade_cooldown = maxf(0.0, max_upgrade_cooldown - delta)
	if max_upgrade_left > 0.0:
		max_upgrade_left = maxf(0.0, max_upgrade_left - delta)
		if max_upgrade_left == 0.0:
			board.set_temp_max_upgrade(false)

func _refresh_skill(slot: int, button: Button, freeze_cooldown: float) -> void:
	if slot != 1:
		super._refresh_skill(slot, button, freeze_cooldown)
		return
	var timer: Label = button.get_node("Timer")
	button.disabled = finished or max_upgrade_left > 0.0 or max_upgrade_cooldown > 0.0
	if max_upgrade_left > 0.0:
		timer.text = "%ds active" % ceili(max_upgrade_left)
	elif max_upgrade_cooldown > 0.0:
		timer.text = "%ds" % ceili(max_upgrade_cooldown)
	else:
		timer.text = "Ready"

func _complete_stage() -> void:
	finished = true
	_deselect()
	board.set_temp_max_upgrade(false)
	max_upgrade_left = 0.0
	var progress := ConfigFile.new()
	var loaded: Error = progress.load(progress_path)
	var saved: bool = false
	if loaded == OK or loaded == ERR_FILE_NOT_FOUND:
		progress.set_value("levels", "stage_two_complete", true)
		saved = progress.save(progress_path) == OK
	$VictoryCelebration.celebrate()
	if not saved:
		$VictoryCelebration/Content/Message.text = "PROGRESS COULD NOT BE SAVED"
	elif not stage_two_complete:
		$VictoryCelebration/Content/Message.text = "MINION & TREADMILL TOWERS UNLOCKED!"
	stage_two_complete = saved or stage_two_complete
	$VictoryCelebration/Content/Quit.text = "Return to menu"

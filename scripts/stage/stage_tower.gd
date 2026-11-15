extends "res://scripts/actors/tower.gd"

const FIRE_BOW_ART: Texture2D = preload("res://assets/generated/realistic_tower_fire_bow.png")
const BRICK_ART: Texture2D = preload("res://assets/generated/realistic_brick_catapult.png")
const BRICK_UPGRADED_ART: Texture2D = preload("res://assets/generated/realistic_brick_recruiter.png")
const BRICKS_PER_VOLLEY: int = 5
signal minion_requested
@export_range(1.0, 60.0) var minion_interval: float = 12.0

var tier: int = 0
var brick: bool = false
var invested: int = 100
var brick_launch_index: int = 0
var minion_time_left: float = 0.0

func setup_stage(config: TutorialBalance, is_brick: bool) -> void:
	setup(config)
	brick = is_brick
	if brick:
		power = 60
		invested = 150
	else:
		power = 30

func _ready() -> void:
	super._ready()
	if brick:
		_set_art(BRICK_ART, 76.0)

func tick(delta: float, target: TutorialZombie) -> void:
	cooldown = maxf(0.0, cooldown - delta)
	if settled or not is_instance_valid(target) or target.settled:
		return
	if position.distance_to(target.position) > balance.tower_range or cooldown > 0.0:
		return
	var interval: float = 0.5 if brick else balance.shot_interval
	if target.freeze_left > 0.0:
		interval *= 0.5
	cooldown = interval
	fired.emit(target, power)

func tick_bricks(delta: float, targets: Array[TutorialZombie]) -> void:
	cooldown = maxf(0.0, cooldown - delta)
	if settled or targets.is_empty() or cooldown > 0.0:
		return
	var first: TutorialZombie = targets[0]
	cooldown = 0.25 if first.freeze_left > 0.0 else 0.5
	# Aim at distinct targets first; when fewer than five are present, spread
	# the remaining bricks among them in the same order. Split the total power
	# evenly, sharing any remainder without increasing the volley's total.
	var damage_per_brick: int = floori(float(power) / BRICKS_PER_VOLLEY)
	var remainder: int = power % BRICKS_PER_VOLLEY
	for index: int in BRICKS_PER_VOLLEY:
		brick_launch_index = index
		fired.emit(targets[index % targets.size()], damage_per_brick + (1 if index < remainder else 0))

func stage_upgrade() -> void:
	if settled or (brick and tier >= 1) or (not brick and tier >= 2):
		return
	if brick:
		tier = 1
		invested += 100
		minion_time_left = minion_interval
		_set_art(BRICK_UPGRADED_ART, 76.0)
		upgrade_elapsed = 0.0
		$UpgradeLabel.text = "MINIONS READY!"
		$UpgradeLabel.show()
		get_node("/root/Sfx").play(&"upgrade")
		queue_redraw()
		return
	tier += 1
	invested += 50 if tier == 1 else 100
	if tier == 1:
		upgrade()
	else:
		power = 60
		health += 40
		max_health += 40
		_update_health_display()
		_set_art(FIRE_BOW_ART, 84.0)
		upgrade_elapsed = 0.0
		$UpgradeLabel.text = "FIRE BOW!"
		$UpgradeLabel.show()
		get_node("/root/Sfx").play(&"upgrade")
	queue_redraw()

func tick_recruitment(delta: float) -> void:
	if not brick or tier < 1 or settled or minion_interval <= 0.0:
		return
	minion_time_left -= delta
	while minion_time_left <= 0.0:
		minion_time_left += minion_interval
		minion_requested.emit()

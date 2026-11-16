extends "res://scripts/actors/tower.gd"

const FIRE_BOW_ART: Texture2D = preload("res://assets/generated/realistic_tower_fire_bow.png")
const BRICK_ART: Texture2D = preload("res://assets/generated/realistic_brick_catapult.png")
const BRICK_UPGRADED_ART: Texture2D = preload("res://assets/generated/realistic_brick_recruiter.png")
const MINION_ART: Texture2D = preload("res://assets/generated/realistic_minion_tower.png")
const TREADMILL_ART: Texture2D = preload("res://assets/generated/realistic_treadmill_tower.png")
const MINION_BATCHES: Array[int] = [3, 10, 20]
const MINION_UPGRADE_INTERVALS: Array[float] = [3.0, 1.0]
const MINION_UPGRADE_COSTS: Array[int] = [150, 300]
const MAX_UPGRADE_MINION_BATCH: int = 50
const MAX_UPGRADE_MINION_INTERVAL: float = 2.0
const BRICKS_PER_VOLLEY: int = 5
signal minion_requested(slot: int)
@export_range(1.0, 60.0) var minion_interval: float = 12.0
@export_range(1.0, 60.0) var minion_tower_interval: float = 5.0
@export_range(0.1, 1.0) var treadmill_speed_factor: float = 0.25

var tier: int = 0
var brick: bool = false
var invested: int = 100
var brick_launch_index: int = 0
var minion_time_left: float = 0.0
var kind: String = "standard"
var temp_max_upgrade: bool = false
var bonus_health: int = 0
var bonus_health_remaining: int = 0

func setup_stage(config: TutorialBalance, is_brick: bool, tower_kind: String = "standard", cost: int = 0) -> void:
	setup(config)
	brick = is_brick
	kind = "brick" if brick else tower_kind
	if brick:
		power = 60
		invested = 150
	elif kind == "standard":
		power = 30
		invested = config.tower_cost
	else:
		power = 0
		invested = cost
		minion_time_left = minion_tower_interval

func _ready() -> void:
	super._ready()
	if brick:
		_set_art(BRICK_ART, 76.0)
	elif kind == "minion":
		_set_art(MINION_ART, 76.0)
		$Art.position.y = -23.0
		$Health.position.y = -86.0
	elif kind == "treadmill":
		_set_art(TREADMILL_ART, 106.0)
		$Art.position.y = 8.0
		$Health.hide()

func tick(delta: float, target: TutorialZombie) -> void:
	if kind == "minion" or kind == "treadmill":
		return
	cooldown = maxf(0.0, cooldown - delta)
	if settled or not is_instance_valid(target) or target.settled:
		return
	if position.distance_to(target.position) > balance.tower_range or cooldown > 0.0:
		return
	var interval: float = 0.5 if brick else balance.shot_interval
	if target.freeze_left > 0.0:
		interval *= 0.5
	cooldown = interval
	fired.emit(target, effective_power())

func effective_power() -> int:
	return 60 if temp_max_upgrade and kind == "standard" else power

func effective_tier() -> int:
	return max_tier() if temp_max_upgrade else tier

func max_tier() -> int:
	match kind:
		"standard", "minion": return 2
		"brick": return 1
		_: return 0

func set_temp_max_upgrade(active: bool) -> void:
	if temp_max_upgrade == active or (active and tier >= max_tier() and kind != "minion"):
		return
	temp_max_upgrade = active
	if kind == "minion":
		minion_time_left = recruitment_interval()
		queue_redraw()
		return
	if active:
		if brick:
			minion_time_left = 0.0
			_set_art(BRICK_UPGRADED_ART, 76.0)
		else:
			bonus_health = balance.upgraded_health + 40 - max_health
			bonus_health_remaining = bonus_health
			max_health += bonus_health
			health += bonus_health
			_set_art(FIRE_BOW_ART, 84.0)
	else:
		max_health -= bonus_health
		health -= bonus_health_remaining
		bonus_health = 0
		bonus_health_remaining = 0
		if brick:
			_set_art(BRICK_ART, 76.0)
		else:
			_set_art(UPGRADED_ART if tier == 1 else BASE_ART, 84.0 if tier == 1 else 76.0)
	_update_health_display()
	queue_redraw()

func take_damage(amount: int) -> void:
	bonus_health_remaining = maxi(0, bonus_health_remaining - maxi(amount, 0))
	super.take_damage(amount)

func display_name() -> String:
	match kind:
		"minion": return "MINION TOWER · LV %d" % (effective_tier() + 1)
		"treadmill": return "TREADMILL TOWER"
		"brick": return "BRICK TOWER + MINIONS" if effective_tier() > 0 else "BRICK TOWER"
		_: return ["STANDARD TOWER", "REINFORCED TOWER", "FIRE BOW TOWER"][effective_tier()]

func attack_description() -> String:
	match kind:
		"minion":
			var interval: float = recruitment_interval()
			var decimals: int = 0 if is_equal_approx(interval, roundf(interval)) else 2
			return "%d minions every %s s" % [recruitment_batch(), String.num(interval, decimals)]
		"treadmill": return "Slows zombies on the belt"
		"brick": return "%d total damage · 5 bricks" % power
		_: return "%d damage" % effective_power()

func effect_description() -> String:
	match kind:
		"minion": return "40 health · 6 melee damage each"
		"treadmill": return "Zombies move at %.0f%% speed" % (treadmill_speed_factor * 100.0)
		"brick":
			if effective_tier() > 0:
				return "Range %d px | Minion every %.0fs" % [balance.tower_range, minion_interval]
	return "Range %d px" % balance.tower_range

func recruitment_interval() -> float:
	if kind != "minion":
		return minion_interval
	if temp_max_upgrade:
		return MAX_UPGRADE_MINION_INTERVAL
	var current_tier: int = effective_tier()
	return minion_tower_interval if current_tier == 0 else MINION_UPGRADE_INTERVALS[current_tier - 1]

func recruitment_batch() -> int:
	if kind != "minion":
		return 1
	return MAX_UPGRADE_MINION_BATCH if temp_max_upgrade else MINION_BATCHES[tier]

func upgrade_cost() -> int:
	if tier >= max_tier():
		return 0
	match kind:
		"minion": return MINION_UPGRADE_COSTS[tier]
		"brick": return 100
		_: return 50 if tier == 0 else 100

func upgrade_description() -> String:
	match kind:
		"minion":
			return "%d minions / %.0fs · %d gold" % [
				MINION_BATCHES[tier + 1], MINION_UPGRADE_INTERVALS[tier], upgrade_cost()]
		"brick": return "Add minions · %d gold" % upgrade_cost()
		_: return "Upgrade · %d gold" % upgrade_cost()

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
	if settled or temp_max_upgrade or tier >= max_tier():
		return
	invested += upgrade_cost()
	tier += 1
	if kind == "minion":
		minion_time_left = recruitment_interval()
		upgrade_elapsed = 0.0
		get_node("/root/Sfx").play(&"upgrade")
		queue_redraw()
		return
	if brick:
		minion_time_left = minion_interval
		_set_art(BRICK_UPGRADED_ART, 76.0)
		upgrade_elapsed = 0.0
		$UpgradeLabel.text = "MINIONS READY!"
		$UpgradeLabel.show()
		get_node("/root/Sfx").play(&"upgrade")
		queue_redraw()
		return
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
	var interval: float = recruitment_interval()
	if settled or interval <= 0.0 or (kind != "minion" and not (brick and effective_tier() == 1)):
		return
	minion_time_left -= delta
	var batch: int = recruitment_batch()
	while minion_time_left <= 0.000001:
		minion_time_left += interval
		for slot: int in batch:
			minion_requested.emit(slot)

func _draw() -> void:
	super._draw()
	if temp_max_upgrade:
		draw_arc(Vector2.ZERO, 37, 0, TAU, 40, Color("ffcf65"), 3.0, true)

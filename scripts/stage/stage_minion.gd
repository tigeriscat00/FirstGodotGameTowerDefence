extends "res://scripts/actors/tower.gd"
## Friendly unit: 10 damage per second in melee, 100 health.

const MINION_ART: Texture2D = preload("res://assets/generated/kingdom_minion_walk_v2.png")
# Centers and foot baselines measured in each cell at alpha >= 128.
const FRAME_CENTER_X: Array[float] = [201.0, 201.5, 200.5, 197.5, 205.0, 218.5, 211.5, 218.5]
const FRAME_FEET_Y: Array[float] = [404.0, 404.0, 406.0, 403.0, 382.0, 383.0, 389.0, 382.0]
@export var movement_speed: float = 90.0
@export var attack_reach: float = 35.0
@export var attack_interval: float = 1.0
@export_range(40.0, 200.0) var walk_cycle_distance: float = 90.0
var home: Vector2 = Vector2.ZERO
var patrol_time: float = 0.0
var walking_distance: float = 0.0
var attack_flash: float = 0.0

func setup_minion(home_position: Vector2) -> void:
	home = home_position
	health = 100
	max_health = 100
	power = 10

func _ready() -> void:
	$Art.texture = MINION_ART
	$Art.hframes = 4
	$Art.vframes = 2
	_set_walk_frame(0)
	$Health.custom_minimum_size = Vector2(48, 14)
	$Health.position = Vector2(-24, -72)
	$Health.size = Vector2(48, 14)
	$Health/Value.add_theme_font_size_override("font_size", 10)
	_update_health_display()
	queue_redraw()

func tick_minion(delta: float, enemies: Array[TutorialZombie]) -> void:
	if settled:
		return
	cooldown = maxf(0.0, cooldown - delta)
	attack_flash = maxf(0.0, attack_flash - delta)
	var target: TutorialZombie = null
	var nearest: float = INF
	for enemy: TutorialZombie in enemies:
		if not is_instance_valid(enemy) or enemy.settled:
			continue
		var distance: float = position.distance_squared_to(enemy.position)
		if distance < nearest:
			nearest = distance
			target = enemy
	if is_instance_valid(target):
		if position.distance_to(target.position) <= attack_reach:
			if cooldown <= 0.0:
				cooldown = attack_interval
				attack_flash = 0.18
				target.take_damage(power)
		else:
			_move_towards(target.position, delta)
	else:
		patrol_time += delta
		var patrol_point: Vector2 = home + Vector2(cos(patrol_time * 0.7) * 44.0, sin(patrol_time * 0.7) * 28.0)
		patrol_point = patrol_point.clamp(Vector2(64, 110), Vector2(850, 610))
		_move_towards(patrol_point, delta)
	queue_redraw()

func _move_towards(destination: Vector2, delta: float) -> void:
	var old: Vector2 = position
	if absf(destination.x - position.x) > 1.0:
		$Art.flip_h = destination.x > position.x
	position = position.move_toward(destination, movement_speed * delta)
	var traveled: float = old.distance_to(position)
	walking_distance += traveled
	if traveled > 0.0:
		_set_walk_frame(floori(walking_distance / walk_cycle_distance * 8.0) % 8)

func _set_walk_frame(frame: int) -> void:
	$Art.frame = frame
	var art_scale: float = 56.0 / 310.0
	$Art.scale = Vector2.ONE * art_scale
	var center_offset: float = (FRAME_CENTER_X[frame] - MINION_ART.get_width() / 8.0) * art_scale
	var foot_offset: float = (FRAME_FEET_Y[frame] - MINION_ART.get_height() / 4.0) * art_scale
	$Art.position = Vector2(center_offset if $Art.flip_h else -center_offset, -foot_offset)

func _draw() -> void:
	draw_set_transform(Vector2(0, 2), 0.0, Vector2(1, 0.3))
	draw_circle(Vector2.ZERO, 15, Color(0.03, 0.045, 0.025, 0.3))
	draw_set_transform(Vector2.ZERO)
	if attack_flash > 0.0:
		draw_arc(Vector2(-12, -25), 20.0, 2.1, 4.4, 12, Color("fff1b2"), 3.0, true)

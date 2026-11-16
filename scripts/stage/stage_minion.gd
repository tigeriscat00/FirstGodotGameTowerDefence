extends "res://scripts/actors/tower.gd"
## Friendly melee unit recruited by Brick and Minion Towers.

const MINION_ART: Texture2D = preload("res://assets/generated/kingdom_minion_walk_v2.png")
const FRAME_SCALE: float = 56.0 / 310.0
static var frame_size: Vector2 = Vector2(MINION_ART.get_width() / 4.0, MINION_ART.get_height() / 2.0)
# Centers and foot baselines measured in each cell at alpha >= 128.
const FRAME_CENTER_X: Array[float] = [201.0, 201.5, 200.5, 197.5, 205.0, 218.5, 211.5, 218.5]
const FRAME_FEET_Y: Array[float] = [404.0, 404.0, 406.0, 403.0, 382.0, 383.0, 389.0, 382.0]
@export var movement_speed: float = 90.0
@export var attack_reach: float = 35.0
@export var attack_interval: float = 1.0
@export_range(40.0, 200.0) var walk_cycle_distance: float = 90.0
@onready var art: Sprite2D = get_node_or_null("Art")
var home: Vector2 = Vector2.ZERO
var patrol_time: float = 0.0
var walking_distance: float = 0.0
var attack_flash: float = 0.0
var from_minion_tower: bool = false
var formation_offset: Vector2 = Vector2.ZERO
var facing_right: bool = false
var walk_frame: int = 0

func setup_minion(home_position: Vector2, dedicated: bool = false, slot: int = 0) -> void:
	home = home_position
	from_minion_tower = dedicated
	health = 40 if dedicated else 100
	max_health = health
	power = 6 if dedicated else 10
	if dedicated:
		formation_offset = Vector2.from_angle(slot * 2.4) * minf(32.0, 8.0 * sqrt(slot))

func _ready() -> void:
	if from_minion_tower:
		set_process(false)
		return
	art.texture = MINION_ART
	art.hframes = 4
	art.vframes = 2
	art.scale = Vector2.ONE * FRAME_SCALE
	_set_walk_frame(0)
	$Health.custom_minimum_size = Vector2(48, 14)
	$Health.position = Vector2(-24, -72)
	$Health.size = Vector2(48, 14)
	$Health/Value.add_theme_font_size_override("font_size", 10)
	_update_health_display()
	queue_redraw()

func _update_health_display() -> void:
	if not from_minion_tower:
		super._update_health_display()

func tick_minion(delta: float, enemies: Array[TutorialZombie]) -> void:
	if settled:
		return
	cooldown = maxf(0.0, cooldown - delta)
	var was_attacking: bool = attack_flash > 0.0
	attack_flash = maxf(0.0, attack_flash - delta)
	var current_position: Vector2 = position
	var target: TutorialZombie = null
	var nearest: float = INF
	for enemy: TutorialZombie in enemies:
		if not is_instance_valid(enemy) or enemy.settled:
			continue
		var distance: float = current_position.distance_squared_to(enemy.position)
		if distance < nearest:
			nearest = distance
			target = enemy
	if target != null:
		if nearest <= attack_reach * attack_reach:
			if cooldown <= 0.0:
				cooldown = attack_interval
				attack_flash = 0.18
				target.take_damage(power)
			elif from_minion_tower and attack_flash <= 0.0:
				_move_towards(target.position + formation_offset, delta)
		else:
			_move_towards(target.position + formation_offset, delta)
	else:
		patrol_time += delta
		var patrol_point: Vector2 = home + formation_offset + Vector2(cos(patrol_time * 0.7) * 44.0, sin(patrol_time * 0.7) * 28.0)
		patrol_point = patrol_point.clamp(Vector2(64, 110), Vector2(850, 610))
		_move_towards(patrol_point, delta)
	if not from_minion_tower and was_attacking != (attack_flash > 0.0):
		queue_redraw()

func _move_towards(destination: Vector2, delta: float) -> void:
	var start: Vector2 = position
	var next: Vector2 = start.move_toward(destination, movement_speed * delta)
	if next == start:
		return
	var was_flipped: bool = facing_right
	if absf(destination.x - start.x) > 1.0:
		facing_right = destination.x > start.x
	position = next
	walking_distance += start.distance_to(next)
	var previous_frame: int = walk_frame
	walk_frame = floori(walking_distance / walk_cycle_distance * 8.0) % 8
	if not from_minion_tower and (walk_frame != previous_frame or was_flipped != facing_right):
		_set_walk_frame(walk_frame)

func _set_walk_frame(frame: int) -> void:
	art.frame = frame
	art.flip_h = facing_right
	art.position = frame_offset(frame, facing_right)

static func frame_offset(frame: int, flipped: bool) -> Vector2:
	var offset := Vector2(FRAME_CENTER_X[frame], FRAME_FEET_Y[frame]) - frame_size * 0.5
	offset.x *= 1.0 if flipped else -1.0
	return Vector2(offset.x, -offset.y) * FRAME_SCALE

func _draw() -> void:
	if from_minion_tower:
		return
	draw_set_transform(Vector2(0, 2), 0.0, Vector2(1, 0.3))
	draw_circle(Vector2.ZERO, 15, Color(0.03, 0.045, 0.025, 0.3))
	draw_set_transform(Vector2.ZERO)
	if attack_flash > 0.0:
		draw_arc(Vector2(-12, -25), 20.0, 2.1, 4.4, 12, Color("fff1b2"), 3.0, true)

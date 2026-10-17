class_name TutorialZombie
extends Node2D

signal died
signal gate_hit(damage: int)

@export_range(40.0, 160.0) var walk_cycle_distance: float = 72.0

var balance: TutorialBalance
var health: int = 80
var max_health: int = 80
var power: int = 90
var freeze_left: float = 0.0
var cooldown: float = 0.0
var settled: bool = false
var selected: bool = false
var walk_distance: float = 0.0
var is_semiboss: bool = false
var gold_reward: int = 25
var move_speed: float = 45.0
var groan_left: float = 2.0
var groan_variant: bool = false
# Foot baselines measured from the generated 4x2 sheet; align in Godot without
# altering the original pixels so the walk cycle does not jump vertically.
const FRAME_FEET: Array[float] = [420.0, 420.0, 420.0, 420.0, 414.5, 416.5, 417.5, 413.5]


func setup(config: TutorialBalance, semiboss: bool = false) -> void:
	balance = config
	is_semiboss = semiboss
	health = config.semiboss_health if semiboss else config.zombie_health
	max_health = health
	power = config.semiboss_power if semiboss else config.zombie_power
	move_speed = config.semiboss_speed if semiboss else config.zombie_speed
	gold_reward = config.semiboss_reward if semiboss else config.kill_reward


func _ready() -> void:
	groan_left = randf_range(1.8, 3.2)
	$SemibossLabel.visible = is_semiboss
	if is_semiboss:
		$Health.position.y = -108.0
	_update_health_display()


func tick(delta: float, towers: Array[DefenseTower], gate: Vector2) -> void:
	if settled:
		return
	if freeze_left > 0.0:
		freeze_left = maxf(0.0, freeze_left - delta)
		$Art.modulate = Color(0.4, 0.8, 1.4) if freeze_left > 0.0 else Color.WHITE
		queue_redraw()
		return
	groan_left -= delta
	if groan_left <= 0.0:
		get_node("/root/Sfx").play(&"groan_b" if is_semiboss or groan_variant else &"groan_a")
		groan_variant = not groan_variant
		groan_left = randf_range(4.0, 6.5)
	cooldown = maxf(0.0, cooldown - delta)
	var victim: DefenseTower = null
	var nearest: float = balance.zombie_reach
	for tower: DefenseTower in towers:
		if not is_instance_valid(tower) or tower.settled:
			continue
		var distance: float = position.distance_to(tower.position)
		if distance <= nearest:
			nearest = distance
			victim = tower
	if victim != null:
		_apply_walk_frame(0)
		if cooldown <= 0.0:
			cooldown = balance.zombie_attack_interval
			victim.take_damage(power)
		return
	if position.distance_to(gate) <= 24.0:
		_apply_walk_frame(0)
		if cooldown <= 0.0:
			cooldown = balance.zombie_attack_interval
			gate_hit.emit(power)
		return
	var previous_position: Vector2 = position
	position = position.move_toward(gate, move_speed * delta)
	walk_distance += previous_position.distance_to(position)
	# Advance poses by ground covered, rather than flailing at a fixed frame rate.
	# Larger enemies take longer strides, giving the semiboss a heavier shuffle.
	var size_ratio: float = ($Art.texture.get_height() / float($Art.vframes)) * $Art.scale.y / 104.0
	var stride_length: float = walk_cycle_distance * size_ratio
	_apply_walk_frame(floori(walk_distance / stride_length * 8.0) % 8)


func _apply_walk_frame(frame: int) -> void:
	$Art.frame = frame
	var frame_height: float = float($Art.texture.get_height()) / $Art.vframes
	var display_height: float = 132.0 if is_semiboss else 104.0
	# The highest lane needs a smaller silhouette to stay below the toolbar.
	display_height = minf(display_height, maxf(72.0, (position.y - 68.0) / 0.89))
	$Art.scale = Vector2.ONE * (display_height / frame_height)
	$Art.position.y = -(FRAME_FEET[frame] - frame_height * 0.5) * $Art.scale.y


func freeze(seconds: float) -> void:
	if settled:
		return
	freeze_left = seconds
	$Art.modulate = Color(0.4, 0.8, 1.4)
	queue_redraw()


func take_damage(amount: int) -> void:
	if settled:
		return
	if amount > 0:
		get_node("/root/Sfx").play(&"impact")
	health = maxi(0, health - amount)
	_update_health_display()
	queue_redraw()
	if health == 0:
		settled = true
		died.emit()
		queue_free()


func _update_health_display() -> void:
	# Keep the bar below the HUD even when this wave uses the highest build row.
	_apply_walk_frame($Art.frame)
	var normal_y: float = -140.0 if is_semiboss else -116.0
	$Health.position.y = maxf(normal_y, (96.0 if is_semiboss else 72.0) - position.y)
	# If top-lane headroom is tight, place the bar beside the face instead of over it.
	$Health.position.x = 56.0 if $Health.position.y > normal_y else -36.0
	$SemibossLabel.position.x = $Health.position.x - 19.0
	$SemibossLabel.position.y = $Health.position.y - 24.0
	$Health.max_value = max_health
	$Health.value = health
	$Health/Value.text = "%d / %d" % [health, max_health]


func _draw() -> void:
	draw_set_transform(Vector2(0, 2), 0.0, Vector2(1, 0.28))
	draw_circle(Vector2.ZERO, 25 if is_semiboss else 18, Color(0.03, 0.045, 0.025, 0.3))
	draw_set_transform(Vector2.ZERO)
	if is_semiboss:
		draw_arc(Vector2.ZERO, 40, 0, TAU, 32, Color("ffc768"), 3)
	if selected:
		draw_arc(Vector2.ZERO, 32, 0, TAU, 32, Color("ffe6a1"), 3)
	if freeze_left > 0.0:
		draw_circle(Vector2(0, -24), 42, Color(0.4, 0.85, 1, 0.25))
		draw_arc(Vector2(0, -24), 42, 0, TAU, 6, Color("96edff"), 3)

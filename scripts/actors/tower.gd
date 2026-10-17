class_name DefenseTower
extends Node2D

signal destroyed
signal fired(target: TutorialZombie, damage: int)

const MAX_SKILLS: int = 4
const BASE_ART: Texture2D = preload("res://assets/generated/realistic_tower.png")
const UPGRADED_ART: Texture2D = preload("res://assets/generated/realistic_tower_upgraded.png")
@export var skills: Array[StringName] = [&"freeze"]:
	set(value):
		skills = value.slice(0, MAX_SKILLS)
var freeze_cooldown: float = 0.0

var balance: TutorialBalance
var health: int = 180
var max_health: int = 180
var power: int = 20
var upgraded: bool = false
var selected: bool = false
var cooldown: float = 0.0
var settled: bool = false
var upgrade_elapsed: float = -1.0
const UPGRADE_SECONDS: float = 1.2


func _set_art(texture: Texture2D, width: float) -> void:
	$Art.texture = texture
	$Art.scale = Vector2.ONE * (width / texture.get_width())
	$Art.position.y = -8.0


func setup(config: TutorialBalance) -> void:
	balance = config
	health = config.tower_health
	max_health = health
	power = config.tower_power


func _ready() -> void:
	_set_art(BASE_ART, 76.0)
	_update_health_display()
	queue_redraw()


func _process(delta: float) -> void:
	if upgrade_elapsed < 0.0:
		return
	upgrade_elapsed = minf(upgrade_elapsed + delta, UPGRADE_SECONDS)
	var progress: float = upgrade_elapsed / UPGRADE_SECONDS
	var width: float = 84.0 if upgraded else 76.0
	var pulse: float = 1.0 + sin(progress * PI) * 0.18
	$Art.scale = Vector2.ONE * (width / $Art.texture.get_width()) * pulse
	$Art.modulate = Color.WHITE.lerp(Color(1.6, 1.45, 1.1), sin(progress * PI) * 0.6)
	$UpgradeLabel.position.y = -82.0 - progress * 20.0
	$UpgradeLabel.modulate.a = 1.0 - progress * progress
	if progress >= 1.0:
		upgrade_elapsed = -1.0
		$Art.modulate = Color.WHITE
		$UpgradeLabel.hide()
	queue_redraw()


func tick(delta: float, target: TutorialZombie) -> void:
	cooldown = maxf(0.0, cooldown - delta)
	if settled or not is_instance_valid(target) or target.settled:
		return
	if position.distance_to(target.position) > balance.tower_range or cooldown > 0.0:
		return
	cooldown = balance.boosted_interval if target.freeze_left > 0.0 else balance.shot_interval
	fired.emit(target, power)


func upgrade() -> void:
	if upgraded or settled:
		return
	upgraded = true
	get_node("/root/Sfx").play(&"upgrade")
	health += balance.upgraded_health - max_health
	max_health = balance.upgraded_health
	power = balance.upgraded_power
	_set_art(UPGRADED_ART, 84.0)
	upgrade_elapsed = 0.0
	$UpgradeLabel.show()
	_update_health_display()
	queue_redraw()


func take_damage(amount: int) -> void:
	if settled:
		return
	health = maxi(0, health - amount)
	_update_health_display()
	queue_redraw()
	if health == 0:
		settled = true
		destroyed.emit()
		queue_free()


func _update_health_display() -> void:
	$Health.max_value = max_health
	$Health.value = health
	$Health/Value.text = "%d / %d" % [health, max_health]


func _draw() -> void:
	draw_set_transform(Vector2(0, 24), 0.0, Vector2(1, 0.3))
	draw_circle(Vector2.ZERO, 29, Color(0.03, 0.045, 0.025, 0.28))
	draw_set_transform(Vector2.ZERO)
	# A rising ring and gold particles make the one-time transformation obvious.
	if upgrade_elapsed >= 0.0:
		var progress: float = upgrade_elapsed / UPGRADE_SECONDS
		var color := Color(1, 0.83, 0.36, 1.0 - progress)
		draw_arc(Vector2(0, -10), 22.0 + progress * 58.0, 0, TAU, 64, color, 3.0, true)
		for index: int in 18:
			var angle: float = index * TAU / 18.0
			var point := Vector2(cos(angle) * (24.0 + progress * 28.0), -10.0 + sin(angle) * 18.0 - progress * 80.0)
			draw_circle(point, 2.0 + (1.0 - progress) * 2.0, color)
	if selected and balance != null:
		draw_circle(Vector2.ZERO, balance.tower_range, Color(0.2, 0.8, 0.95, 0.10))
		draw_arc(Vector2.ZERO, balance.tower_range, 0, TAU, 64, Color(0.35, 0.85, 1, 0.6), 2)

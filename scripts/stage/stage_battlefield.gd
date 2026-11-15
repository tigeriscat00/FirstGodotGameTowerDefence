extends "res://scripts/tutorial/battlefield.gd"

const STAGE_TOWER: PackedScene = preload("res://scenes/actors/stage_tower.tscn")
const STAGE_ZOMBIE: PackedScene = preload("res://scenes/actors/stage_zombie.tscn")
const MINION_SCENE: PackedScene = preload("res://scenes/actors/stage_minion.tscn")
var enemies: Array[TutorialZombie] = []
var minions: Array[DefenseTower] = []
var warning_rows: Array[int] = []
var projectile_kind: String = "standard"
const BRICK_FLIGHT_SECONDS: float = 0.65
const BRICK_LAUNCH_SPACING: float = 0.08
var flying_bricks: Array[Dictionary] = []

func _draw() -> void:
	super._draw()
	for row: int in warning_rows:
		var y: float = cell_center(row * COLUMNS + FIRST_BUILD_COLUMN).y
		draw_line(Vector2(18, y), Vector2(120, y), Color(1, 0.78, 0.25, 0.8), 4)
		draw_colored_polygon(PackedVector2Array([Vector2(120, y - 9), Vector2(136, y), Vector2(120, y + 9)]), Color(1, 0.78, 0.25, 0.9))
	if beam_left > 0.0 and projectile_kind == "fire":
		draw_line(beam_from, beam_to, Color("ff9a2e"), 5.0, true)
		var midpoint: Vector2 = beam_from.lerp(beam_to, 0.65)
		draw_circle(midpoint, 7.0, Color("ffce4a"))
	for projectile: Dictionary in flying_bricks:
		if projectile.elapsed < 0.0:
			continue
		draw_set_transform(projectile.position, projectile.angle, Vector2.ONE)
		draw_rect(Rect2(-9, -5, 18, 10), Color("a8442e"))
		draw_rect(Rect2(-8, -4, 16, 3), Color("d47b55"))
		draw_rect(Rect2(-9, -5, 18, 10), Color("f1b18b"), false, 1.0)
		draw_set_transform(Vector2.ZERO)

func _on_fired(target: TutorialZombie, damage: int, tower: DefenseTower) -> void:
	var stage_tower: Variant = tower
	if stage_tower.brick:
		if not is_instance_valid(target) or target.settled:
			return
		var origin: Vector2 = tower.position + Vector2(-10, -42)
		flying_bricks.append({"target": weakref(target), "damage": damage, "start": origin,
			"position": origin, "elapsed": -float(stage_tower.brick_launch_index) * BRICK_LAUNCH_SPACING, "angle": 0.0,
			"spread": float(stage_tower.brick_launch_index - 2) * 14.0})
		get_node("/root/Sfx").play(&"ballista")
		queue_redraw()
		return
	projectile_kind = "fire" if stage_tower.tier >= 2 else "standard"
	super._on_fired(target, damage, tower)

func _tick_bricks(delta: float) -> void:
	if flying_bricks.is_empty():
		return
	for index: int in range(flying_bricks.size() - 1, -1, -1):
		var projectile: Dictionary = flying_bricks[index]
		var target: TutorialZombie = projectile.target.get_ref()
		if not is_instance_valid(target) or target.settled:
			flying_bricks.remove_at(index)
			continue
		projectile.elapsed += delta
		if projectile.elapsed < 0.0:
			continue
		var progress: float = minf(projectile.elapsed / BRICK_FLIGHT_SECONDS, 1.0)
		var destination: Vector2 = target.position + Vector2(0, -22)
		var start: Vector2 = projectile.start
		var flight_offset: Vector2 = Vector2(projectile.spread, -36.0) * sin(progress * PI)
		projectile.position = start.lerp(destination, progress) + flight_offset
		projectile.angle = projectile.elapsed * 2.0
		if progress >= 1.0:
			target.take_damage(projectile.damage)
			flying_bricks.remove_at(index)
	queue_redraw()

func add_stage_tower(index: int, config: TutorialBalance, brick: bool) -> DefenseTower:
	if not is_build_cell(index) or occupied(index):
		return null
	var tower: DefenseTower = STAGE_TOWER.instantiate()
	tower.setup_stage(config, brick)
	tower.position = cell_center(index)
	towers.append(tower)
	$Actors.add_child(tower)
	tower.fired.connect(_on_fired.bind(tower))
	var stage_tower: Variant = tower
	stage_tower.minion_requested.connect(_spawn_minion.bind(tower))
	queue_redraw()
	return tower

func _spawn_minion(tower: DefenseTower) -> void:
	if not is_instance_valid(tower) or tower.settled:
		return
	var minion: DefenseTower = MINION_SCENE.instantiate()
	minion.setup_minion(tower.position)
	minion.position = tower.position + Vector2(-35, 24)
	minions.append(minion)
	$Actors.add_child(minion)

func tick_recruitment(delta: float) -> void:
	for tower: DefenseTower in towers:
		if is_instance_valid(tower) and not tower.settled:
			var stage_tower: Variant = tower
			stage_tower.tick_recruitment(delta)

func spawn_stage_enemy(config: TutorialBalance, kind: String, row: int) -> TutorialZombie:
	var enemy: TutorialZombie = STAGE_ZOMBIE.instantiate()
	enemy.setup_stage(config, kind)
	enemy.position = Vector2(60, cell_center(row * COLUMNS + FIRST_BUILD_COLUMN).y)
	enemies.append(enemy)
	$Actors.add_child(enemy)
	return enemy

func tick_stage(delta: float) -> void:
	_tick_bricks(delta)
	tick_recruitment(delta)
	for index: int in range(towers.size() - 1, -1, -1):
		if not is_instance_valid(towers[index]) or towers[index].settled:
			towers.remove_at(index)
	for index: int in range(enemies.size() - 1, -1, -1):
		if not is_instance_valid(enemies[index]) or enemies[index].settled:
			enemies.remove_at(index)
	for index: int in range(minions.size() - 1, -1, -1):
		if not is_instance_valid(minions[index]) or minions[index].settled:
			minions.remove_at(index)
	for tower: DefenseTower in towers:
		tower.freeze_cooldown = maxf(0.0, tower.freeze_cooldown - delta)
		var target: TutorialZombie = null
		var nearest: float = INF
		var candidates: Array[TutorialZombie] = []
		for enemy: TutorialZombie in enemies:
			if not is_instance_valid(enemy) or enemy.settled:
				continue
			var distance: float = tower.position.distance_to(enemy.position)
			if distance <= tower.balance.tower_range:
				candidates.append(enemy)
			if distance < nearest:
				nearest = distance
				target = enemy
		var stage_tower: Variant = tower
		if stage_tower.brick:
			candidates.sort_custom(func(a: TutorialZombie, b: TutorialZombie) -> bool: return tower.position.distance_squared_to(a.position) < tower.position.distance_squared_to(b.position))
			stage_tower.tick_bricks(delta, candidates)
		else:
			tower.tick(delta, target)
	for minion: DefenseTower in minions:
		if is_instance_valid(minion) and not minion.settled:
			var unit: Variant = minion
			unit.tick_minion(delta, enemies)
	var defenders: Array[DefenseTower] = []
	defenders.append_array(towers)
	defenders.append_array(minions)
	for enemy: TutorialZombie in enemies:
		if is_instance_valid(enemy) and not enemy.settled:
			enemy.tick(delta, defenders, Vector2(GATE.x, enemy.position.y))

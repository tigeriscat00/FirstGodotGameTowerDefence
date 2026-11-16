extends "res://scripts/tutorial/battlefield.gd"

const STAGE_TOWER: PackedScene = preload("res://scenes/actors/stage_tower.tscn")
const STAGE_ZOMBIE: PackedScene = preload("res://scenes/actors/stage_zombie.tscn")
const MINION_SCENE: PackedScene = preload("res://scenes/actors/stage_minion.tscn")
const BARRACKS_MINION_SCENE: PackedScene = preload("res://scenes/actors/stage_barracks_minion.tscn")
const Minion = preload("res://scripts/stage/stage_minion.gd")
const CROWD_DRAW_CELL: float = 12.0
const CROWD_ROW_STRIDE: int = 128
const TARGET_CELL_SIZE: float = 32.0
var barracks_units := Node.new()
var crowd_canvas := Node2D.new()
var crowd_cells: Dictionary[int, Array] = {}
var brick_minions: Array[DefenseTower] = []
var enemies: Array[TutorialZombie] = []
var minions: Array[DefenseTower] = []
var warning_rows: Array[int] = []
var projectile_kind: String = "standard"
const BRICK_FLIGHT_SECONDS: float = 0.65
const BRICK_LAUNCH_SPACING: float = 0.08
var flying_bricks: Array[Dictionary] = []
var temp_max_upgrade: bool = false

func _ready() -> void:
	super._ready()
	add_child(barracks_units)
	add_child(crowd_canvas)
	crowd_canvas.draw.connect(_draw_barracks_crowd)

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
	projectile_kind = "fire" if stage_tower.effective_tier() >= 2 else "standard"
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

func clear_bricks() -> void:
	flying_bricks.clear()
	queue_redraw()

func add_stage_tower(index: int, config: TutorialBalance, brick: bool, kind: String = "standard", cost: int = 0) -> DefenseTower:
	if not is_build_cell(index) or occupied(index):
		return null
	var tower: DefenseTower = STAGE_TOWER.instantiate()
	tower.setup_stage(config, brick, kind, cost)
	tower.position = cell_center(index)
	towers.append(tower)
	$Actors.add_child(tower)
	tower.set_temp_max_upgrade(temp_max_upgrade)
	tower.fired.connect(_on_fired.bind(tower))
	var stage_tower: Variant = tower
	stage_tower.minion_requested.connect(_spawn_minion.bind(tower))
	queue_redraw()
	return tower

func set_temp_max_upgrade(active: bool) -> void:
	temp_max_upgrade = active
	for tower: DefenseTower in towers:
		if is_instance_valid(tower) and not tower.settled:
			tower.set_temp_max_upgrade(active)

func _spawn_minion(slot: int, tower: DefenseTower) -> void:
	if not is_instance_valid(tower) or tower.settled:
		return
	var dedicated: bool = tower.get("kind") == "minion"
	var minion: Minion = (BARRACKS_MINION_SCENE if dedicated else MINION_SCENE).instantiate()
	var door: Vector2 = tower.position + Vector2(-15, 24) if dedicated else tower.position + Vector2(-35, 24)
	minion.setup_minion(tower.position, dedicated, slot)
	minion.position = door + Vector2((slot % 10 - 5) * 2.0, floori(slot / 10.0) * 2.0) if dedicated else door
	minions.append(minion)
	var units: Node = barracks_units if dedicated else $Actors
	units.add_child(minion)

func tick_recruitment(delta: float) -> void:
	for tower: DefenseTower in towers:
		if is_instance_valid(tower) and not tower.settled:
			var stage_tower: Variant = tower
			stage_tower.tick_recruitment(delta)

func tick_preparation(delta: float) -> void:
	_tick_minions(delta, true)
	tick_recruitment(delta)

func _tick_minions(delta: float, preparation: bool = false) -> void:
	var had_crowd: bool = not crowd_cells.is_empty()
	crowd_cells.clear()
	brick_minions.clear()
	var target_cache: Dictionary[Vector2i, Array] = {}
	for index: int in range(minions.size() - 1, -1, -1):
		if not is_instance_valid(minions[index]) or minions[index].settled:
			minions.remove_at(index)
			continue
		var unit: Minion = minions[index]
		if not preparation or unit.from_minion_tower:
			var targets: Array[TutorialZombie] = enemies
			if unit.from_minion_tower and enemies.size() > 1:
				var target_cell := Vector2i((unit.position / TARGET_CELL_SIZE).floor())
				var cached: Variant = target_cache.get(target_cell)
				if cached == null or (not cached.is_empty() and cached[0].settled):
					targets = _target_candidates(target_cell)
					target_cache[target_cell] = targets
				else:
					targets = cached
			unit.tick_minion(delta, targets)
		if unit.from_minion_tower:
			var unit_position: Vector2 = unit.position
			var cell_x: int = floori(unit_position.x / CROWD_DRAW_CELL)
			var cell_y: int = floori(unit_position.y / CROWD_DRAW_CELL)
			var key: int = cell_y * CROWD_ROW_STRIDE + cell_x
			var bucket: Variant = crowd_cells.get(key)
			if bucket == null:
				crowd_cells[key] = [unit]
			else:
				bucket.append(unit)
		else:
			brick_minions.append(unit)
	if had_crowd or not crowd_cells.is_empty():
		crowd_canvas.queue_redraw()

func _target_candidates(cell: Vector2i) -> Array[TutorialZombie]:
	var center: Vector2 = (Vector2(cell) + Vector2(0.5, 0.5)) * TARGET_CELL_SIZE
	var closest: TutorialZombie
	var nearest: float = INF
	for enemy: TutorialZombie in enemies:
		if not is_instance_valid(enemy) or enemy.settled:
			continue
		var distance: float = center.distance_squared_to(enemy.position)
		if distance < nearest:
			nearest = distance
			closest = enemy
	var candidates: Array[TutorialZombie] = []
	if closest == null:
		return candidates
	# A target farther from the cell center than the closest target plus the
	# cell's diagonal cannot be the closest target from any point in the cell.
	var limit: float = sqrt(nearest) + TARGET_CELL_SIZE * sqrt(2.0)
	var limit_squared: float = limit * limit
	candidates.append(closest)
	for enemy: TutorialZombie in enemies:
		if is_instance_valid(enemy) and not enemy.settled and enemy != closest:
			if center.distance_squared_to(enemy.position) <= limit_squared:
				candidates.append(enemy)
	return candidates

func _draw_barracks_crowd() -> void:
	# Every recruit fights. Share a drawing for units overlapping in the same
	# small area so repeated casts do not stack thousands of identical sprites.
	var cells: Array = crowd_cells.keys()
	cells.sort()
	var frame_size: Vector2 = Minion.frame_size
	var display_size: Vector2 = frame_size * Minion.FRAME_SCALE
	for cell: int in cells:
		var unit: Minion
		for candidate: Variant in crowd_cells[cell]:
			if is_instance_valid(candidate) and not candidate.settled:
				unit = candidate
				break
		if unit == null:
			continue
		var frame: int = unit.walk_frame
		var source := Rect2(Vector2(frame % 4, floori(frame / 4.0)) * frame_size, frame_size)
		var center: Vector2 = unit.position + Minion.frame_offset(frame, unit.facing_right)
		if unit.facing_right:
			crowd_canvas.draw_set_transform(center, 0.0, Vector2(-1.0, 1.0))
			crowd_canvas.draw_texture_rect_region(Minion.MINION_ART, Rect2(-display_size * 0.5, display_size), source)
			crowd_canvas.draw_set_transform(Vector2.ZERO)
		else:
			crowd_canvas.draw_texture_rect_region(Minion.MINION_ART, Rect2(center - display_size * 0.5, display_size), source)
		if unit.health < unit.max_health:
			var bar := Rect2(unit.position + Vector2(-14, -65), Vector2(28, 5))
			crowd_canvas.draw_rect(bar, Color("14302a"))
			bar.size.x *= float(unit.health) / unit.max_health
			crowd_canvas.draw_rect(bar, Color("31aa69"))
		if unit.attack_flash > 0.0:
			crowd_canvas.draw_arc(unit.position + Vector2(-12, -25), 20.0, 2.1, 4.4, 6, Color("fff1b2"), 3.0, true)

func _closest_barracks_minion(point: Vector2, reach: float) -> DefenseTower:
	var nearest_squared: float = reach * reach
	var closest: DefenseTower
	var low := Vector2i(((point - Vector2.ONE * reach) / CROWD_DRAW_CELL).floor())
	var high := Vector2i(((point + Vector2.ONE * reach) / CROWD_DRAW_CELL).floor())
	for y: int in range(low.y, high.y + 1):
		for x: int in range(low.x, high.x + 1):
			var bucket: Variant = crowd_cells.get(y * CROWD_ROW_STRIDE + x)
			if bucket == null:
				continue
			var corner := Vector2(x, y) * CROWD_DRAW_CELL
			var closest_in_cell: Vector2 = point.clamp(corner, corner + Vector2.ONE * CROWD_DRAW_CELL)
			if point.distance_squared_to(closest_in_cell) > nearest_squared:
				continue
			for candidate: Variant in bucket:
				if not is_instance_valid(candidate) or candidate.settled:
					continue
				var unit: Minion = candidate
				var distance_squared: float = point.distance_squared_to(unit.position)
				if distance_squared <= nearest_squared:
					nearest_squared = distance_squared
					closest = unit
	return closest

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
	var defenders: Array[DefenseTower] = []
	var treadmills: Array[DefenseTower] = []
	for tower: DefenseTower in towers:
		tower.freeze_cooldown = maxf(0.0, tower.freeze_cooldown - delta)
		var stage_tower: Variant = tower
		if stage_tower.kind == "treadmill":
			treadmills.append(tower)
			continue
		defenders.append(tower)
		if stage_tower.kind == "minion":
			continue
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
		if stage_tower.brick:
			candidates.sort_custom(func(a: TutorialZombie, b: TutorialZombie) -> bool: return tower.position.distance_squared_to(a.position) < tower.position.distance_squared_to(b.position))
			stage_tower.tick_bricks(delta, candidates)
		else:
			tower.tick(delta, target)
	_tick_minions(delta)
	defenders.append_array(brick_minions)
	for enemy: TutorialZombie in enemies:
		if is_instance_valid(enemy) and not enemy.settled:
			var speed_factor: float = 1.0
			for belt: DefenseTower in treadmills:
				var offset: Vector2 = enemy.position - belt.position
				if absf(offset.x) < 50.0 and absf(offset.y) <= 23.0:
					speed_factor = minf(speed_factor, belt.get("treadmill_speed_factor"))
			var barracks_target: DefenseTower
			if not crowd_cells.is_empty() and enemy.freeze_left <= 0.0:
				barracks_target = _closest_barracks_minion(enemy.position, enemy.balance.zombie_reach)
			enemy.tick(delta, defenders, Vector2(GATE.x, enemy.position.y), speed_factor, barracks_target)

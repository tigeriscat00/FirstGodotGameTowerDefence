class_name TutorialBattlefield
extends Control
## Full-height lawn; actors and placement use logical board-local pixels.

signal board_clicked(point: Vector2)

const TOWER_SCENE: PackedScene = preload("res://scenes/actors/tower.tscn")
const ZOMBIE_SCENE: PackedScene = preload("res://scenes/actors/zombie.tscn")
const GRID_ORIGIN: Vector2 = Vector2(16, 16)
const CELL_SIZE: Vector2 = Vector2(112, 88)
const COLUMNS: int = 7
const ROWS: int = 7
# First three columns are the entry area; top row leaves room for enemy labels.
const FIRST_BUILD_COLUMN: int = 3
const FIRST_BUILD_ROW: int = 1
const RECOMMENDED_CELLS: Array[int] = [24, 25, 26]
const GATE: Vector2 = Vector2(904, 324)

@export_range(0.01, 0.3) var grid_opacity: float = 0.08
@export_range(400.0, 648.0) var castle_height: float = 552.0

var towers: Array[DefenseTower] = []
var zombie: TutorialZombie
var placing: bool = false
var freeze_aiming: bool = false
var pointer: Vector2 = Vector2(-100, -100)
var beam_from: Vector2
var beam_to: Vector2
var beam_left: float = 0.0
var lane_y: float = 324.0
var build_range: float = 250.0


func _ready() -> void:
    var scale_factor: float = castle_height / $Gate.texture.get_height()
    $Gate.scale = Vector2.ONE * scale_factor
    $Gate.position = Vector2(size.x - $Gate.texture.get_width() * scale_factor * 0.5, 352)


func _gui_input(event: InputEvent) -> void:
    if event is InputEventMouseMotion:
        pointer = event.position
        queue_redraw()
    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        board_clicked.emit(event.position)
        accept_event()


func _process(delta: float) -> void:
    if beam_left > 0.0:
        beam_left = maxf(0.0, beam_left - delta)
        queue_redraw()


func cell_center(index: int) -> Vector2:
    return GRID_ORIGIN + Vector2(index % COLUMNS + 0.5, floori(float(index) / COLUMNS) + 0.5) * CELL_SIZE


func cell_rect(index: int) -> Rect2:
    return Rect2(cell_center(index) - CELL_SIZE * 0.5, CELL_SIZE)


func is_build_cell(index: int) -> bool:
    return index >= 0 and index < COLUMNS * ROWS and index % COLUMNS >= FIRST_BUILD_COLUMN and index / COLUMNS >= FIRST_BUILD_ROW


func build_cells() -> Array[int]:
    var cells: Array[int] = []
    for index: int in COLUMNS * ROWS:
        if is_build_cell(index):
            cells.append(index)
    return cells


func cell_at(point: Vector2) -> int:
    if not Rect2(GRID_ORIGIN, CELL_SIZE * Vector2(COLUMNS, ROWS)).has_point(point):
        return -1
    var local: Vector2 = (point - GRID_ORIGIN) / CELL_SIZE
    var index: int = floori(local.y) * COLUMNS + floori(local.x)
    return index if is_build_cell(index) else -1


func tower_at(point: Vector2) -> DefenseTower:
    var index: int = cell_at(point)
    if index < 0:
        return null
    for tower: DefenseTower in towers:
        if is_instance_valid(tower) and not tower.settled and tower.position == cell_center(index):
            return tower
    return null


func occupied(index: int) -> bool:
    for tower: DefenseTower in towers:
        if is_instance_valid(tower) and not tower.settled and tower.position == cell_center(index):
            return true
    return false


func placement_cue_cell() -> int:
    var hovered: int = cell_at(pointer)
    if _clear_placement_cue(hovered):
        return hovered
    for index: int in RECOMMENDED_CELLS:
        if _clear_placement_cue(index):
            return index
    for index: int in build_cells():
        if _clear_placement_cue(index):
            return index
    return -1


func _clear_placement_cue(index: int) -> bool:
    if not is_build_cell(index) or occupied(index):
        return false
    # This is visual guidance, not a new placement rule: never frame the enemy
    # when Sphinx is asking the player to choose an empty building cell.
    if is_instance_valid(zombie) and not zombie.settled:
        var enemy_art := Rect2(zombie.position + Vector2(-45, -90), Vector2(90, 100))
        if cell_rect(index).intersects(enemy_art):
            return false
    return true


func add_tower(index: int, config: TutorialBalance) -> DefenseTower:
    if not is_build_cell(index) or occupied(index):
        return null
    var tower: DefenseTower = TOWER_SCENE.instantiate()
    tower.setup(config)
    tower.position = cell_center(index)
    towers.append(tower)
    $Actors.add_child(tower)
    tower.fired.connect(_on_fired.bind(tower))
    # Tutorial wave stays in the first built tower's row, like a lawn lane.
    if towers.size() == 1:
        lane_y = tower.position.y
    queue_redraw()
    return tower


func spawn_zombie(config: TutorialBalance, start_x: float = 60.0, semiboss: bool = false) -> TutorialZombie:
    zombie = ZOMBIE_SCENE.instantiate()
    zombie.setup(config, semiboss)
    zombie.position = Vector2(start_x, lane_y)
    $Actors.add_child(zombie)
    return zombie


func align_lesson_enemy(tower: DefenseTower) -> void:
    lane_y = tower.position.y
    if is_instance_valid(zombie):
        zombie.position = Vector2(maxf(60.0, tower.position.x - 160.0), lane_y)
        zombie._update_health_display()
    queue_redraw()


func tick(delta: float) -> void:
    if not is_instance_valid(zombie):
        zombie = null
    for index: int in range(towers.size() - 1, -1, -1):
        if not is_instance_valid(towers[index]):
            towers.remove_at(index)
    for tower: DefenseTower in towers:
        if is_instance_valid(tower):
            tower.tick(delta, zombie)
    if is_instance_valid(zombie):
        zombie.tick(delta, towers, Vector2(GATE.x, zombie.position.y))


func _on_fired(target: TutorialZombie, damage: int, tower: DefenseTower) -> void:
    if not is_instance_valid(target) or target.settled:
        return
    beam_from = tower.position + Vector2(0, -22)
    beam_to = target.position + Vector2(0, -22)
    beam_left = 0.16
    get_node("/root/Sfx").play(&"ballista")
    target.take_damage(damage)
    queue_redraw()


func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO, size), Color("365e49"))
    var lawn := Rect2(GRID_ORIGIN, CELL_SIZE * Vector2(COLUMNS, ROWS))
    # A broad lawn replaces the thin road. Alternate row color is deliberately subtle.
    for row: int in ROWS:
        var row_rect := Rect2(GRID_ORIGIN + Vector2(0, row * CELL_SIZE.y), Vector2(lawn.size.x, CELL_SIZE.y))
        if row % 2 == 0:
            draw_rect(row_rect, Color(0.5, 0.7, 0.43, 0.06))
    draw_rect(Rect2(GRID_ORIGIN, Vector2(FIRST_BUILD_COLUMN * CELL_SIZE.x, lawn.size.y)), Color(0.1, 0.2, 0.15, 0.10))
    for x: int in range(28, 1140, 31):
        for y: int in range(28, 636, 31):
            draw_line(Vector2(x, y), Vector2(x + 2, y - 4), Color(0.5, 0.7, 0.5, 0.10), 1)
    var grid_color := Color(0.9, 1.0, 0.85, grid_opacity)
    for column: int in COLUMNS + 1:
        var x: float = GRID_ORIGIN.x + column * CELL_SIZE.x
        draw_line(Vector2(x, lawn.position.y), Vector2(x, lawn.end.y), grid_color, 1)
    for row: int in ROWS + 1:
        var y: float = GRID_ORIGIN.y + row * CELL_SIZE.y
        draw_line(Vector2(lawn.position.x, y), Vector2(lawn.end.x, y), grid_color, 1)
    if placing:
        for index: int in build_cells():
            if not occupied(index):
                draw_rect(cell_rect(index).grow(-2), Color(0.5, 1.0, 0.7, 0.035))
        var index: int = cell_at(pointer)
        var valid: bool = index >= 0 and not occupied(index)
        if index >= 0:
            var color := Color("91e8b0") if valid else Color("d76660")
            draw_rect(cell_rect(index).grow(-2), Color(color, 0.20))
            draw_rect(cell_rect(index).grow(-2), color, false, 2)
            if valid:
                draw_arc(cell_center(index), build_range, 0, TAU, 64, Color(0.35, 0.85, 1, 0.3), 1)
        elif Rect2(Vector2.ZERO, size).has_point(pointer):
            draw_circle(pointer, 8, Color("d76660"))
    if freeze_aiming:
        draw_arc(pointer, 24, 0, TAU, 6, Color("91eaff"), 3)
    if beam_left > 0.0:
        draw_line(beam_from, beam_to, Color("ffe29a"), 4, true)
        draw_circle(beam_to, 7, Color("fff2cc"))
